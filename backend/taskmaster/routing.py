"""Fail-closed, deterministic executor selection. No LLM authorization decisions."""
from dataclasses import dataclass
from typing import FrozenSet, Optional

CLASSIFICATIONS = frozenset({"public", "private", "restricted"})
ENVIRONMENTS = frozenset({"android", "private_pc", "cloud"})


@dataclass(frozen=True)
class Task:
    task_id: str
    classification: str
    capabilities: FrozenSet[str]
    allowed_environments: FrozenSet[str]
    max_cost: float = 0.0


@dataclass(frozen=True)
class Worker:
    worker_id: str
    environment: str
    capabilities: FrozenSet[str]
    healthy: bool
    estimated_cost: float
    reliability: float
    latency_ms: int


def choose_worker(task: Task, workers: list[Worker]) -> Optional[Worker]:
    """Return best eligible worker, or None. Classification restrictions are hard gates."""
    if not task.task_id or task.classification not in CLASSIFICATIONS:
        raise ValueError("Invalid task")
    if not task.allowed_environments <= ENVIRONMENTS or task.max_cost < 0:
        raise ValueError("Invalid task policy")
    eligible = []
    for worker in workers:
        if not worker.healthy or worker.environment not in ENVIRONMENTS:
            continue
        if worker.environment not in task.allowed_environments:
            continue
        # Restricted and private data are local-only until explicit, separately
        # modeled cloud authorization exists. Never infer permission from an LLM.
        if task.classification != "public" and worker.environment == "cloud":
            continue
        if not task.capabilities <= worker.capabilities:
            continue
        if worker.estimated_cost < 0 or worker.estimated_cost > task.max_cost:
            continue
        if not 0 <= worker.reliability <= 1 or worker.latency_ms < 0:
            continue
        eligible.append(worker)
    return max(eligible, key=lambda w: (w.reliability, -w.latency_ms, w.worker_id), default=None)
