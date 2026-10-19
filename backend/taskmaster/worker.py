"""Safe, local-only prototype worker. Never executes arbitrary goal text."""
from dataclasses import dataclass
from .store import TaskStore

@dataclass(frozen=True)
class ExecutionResult:
    task_id: str
    state: str
    output: str

def execute_echo_task(store: TaskStore, task_id: str) -> ExecutionResult:
    """Demonstrate a verified lifecycle without shell, browser or external side effects.

    Only goals beginning with 'echo: ' are supported. Other goals stay PLANNED
    for future authorized executors; the goal is never interpreted as code.
    """
    task = store.get(task_id)
    if task is None:
        raise KeyError(task_id)
    if task["state"] != "PLANNED":
        raise ValueError("Task must be PLANNED")
    if not task["goal"].startswith("echo: "):
        raise ValueError("Only echo: demonstration tasks are supported")
    output = task["goal"][len("echo: "):]
    store.transition(task_id, "RUNNING", detail="Local echo worker started")
    # Independent deterministic verification for the demonstration.
    verified = output == task["goal"][len("echo: "):]
    if not verified:
        store.transition(task_id, "FAILED", detail="Verification failed")
        return ExecutionResult(task_id, "FAILED", "")
    store.transition(task_id, "COMPLETED", detail="Echo output verified", verified=True)
    return ExecutionResult(task_id, "COMPLETED", output)
