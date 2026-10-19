"""Authenticated local task API and explicit user approval workflow."""
import os
import secrets
from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field
from .store import TaskStore
from .approvals import ApprovalStore
from .worker import execute_echo_task

class TaskInput(BaseModel):
    goal: str = Field(min_length=1, max_length=5000)
    classification: str = "private"

class ApprovalDecision(BaseModel):
    approval_id: str

def create_app(db_path: str | None = None, api_token: str | None = None) -> FastAPI:
    path = db_path or os.environ.get("TASKMASTER_DB", "taskmaster.sqlite3")
    token = api_token if api_token is not None else os.environ.get("TASKMASTER_API_TOKEN")
    if not token or len(token) < 24:
        raise RuntimeError("Set TASKMASTER_API_TOKEN to a random secret of at least 24 characters")
    store, approvals = TaskStore(path), ApprovalStore(path)

    def authorize(authorization: str | None = Header(default=None)):
        if authorization is None or not secrets.compare_digest(authorization, "Bearer " + token):
            raise HTTPException(status_code=401, detail="Unauthorized")

    app = FastAPI(title="TaskMaster Local API", version="0.2.0")

    @app.get("/healthz")
    def healthz():
        return {"status": "ok"}

    @app.post("/v1/tasks", status_code=201, dependencies=[Depends(authorize)])
    def create_task(body: TaskInput):
        try:
            return store.create(body.goal, body.classification)
        except ValueError as exc:
            raise HTTPException(status_code=422, detail=str(exc)) from exc

    @app.get("/v1/tasks", dependencies=[Depends(authorize)])
    def list_tasks():
        return store.list()

    @app.get("/v1/tasks/{task_id}", dependencies=[Depends(authorize)])
    def get_task(task_id: str):
        task = store.get(task_id)
        if task is None:
            raise HTTPException(status_code=404, detail="Task not found")
        return task

    @app.get("/v1/tasks/{task_id}/events", dependencies=[Depends(authorize)])
    def get_events(task_id: str):
        if store.get(task_id) is None:
            raise HTTPException(status_code=404, detail="Task not found")
        return store.events(task_id)

    @app.post("/v1/tasks/{task_id}/prepare", dependencies=[Depends(authorize)])
    def prepare(task_id: str):
        task = store.get(task_id)
        if task is None:
            raise HTTPException(status_code=404, detail="Task not found")
        if task["state"] != "CREATED":
            raise HTTPException(status_code=409, detail="Task already prepared")
        if not task["goal"].startswith("echo: "):
            raise HTTPException(status_code=422, detail="Only echo: demo tasks are supported")
        store.transition(task_id, "PLANNED", detail="Safe local echo action planned")
        grant = approvals.request(task_id, "echo", {"goal": task["goal"]}, ttl_seconds=600)
        store.transition(task_id, "WAITING_APPROVAL", detail="Awaiting explicit user approval")
        return grant

    @app.post("/v1/tasks/{task_id}/approve", dependencies=[Depends(authorize)])
    def approve(task_id: str, body: ApprovalDecision):
        task = store.get(task_id)
        if task is None:
            raise HTTPException(status_code=404, detail="Task not found")
        if task["state"] != "WAITING_APPROVAL":
            raise HTTPException(status_code=409, detail="Task is not awaiting approval")
        if not approvals.approve(body.approval_id, task_id, "echo", {"goal": task["goal"]}):
            raise HTTPException(status_code=409, detail="Approval invalid, expired or already decided")
        store.transition(task_id, "PLANNED", detail="User explicitly approved exact echo action")
        return {"approved": True, "task": store.get(task_id)}

    @app.post("/v1/tasks/{task_id}/run", dependencies=[Depends(authorize)])
    def run(task_id: str, body: ApprovalDecision):
        task = store.get(task_id)
        if task is None:
            raise HTTPException(status_code=404, detail="Task not found")
        if task["state"] != "PLANNED":
            raise HTTPException(status_code=409, detail="Task is not ready")
        if not approvals.consume(body.approval_id, task_id, "echo", {"goal": task["goal"]}):
            raise HTTPException(status_code=403, detail="Approved single-use grant required")
        result = execute_echo_task(store, task_id)
        return {"task_id": result.task_id, "state": result.state, "output": result.output}

    @app.post("/v1/tasks/{task_id}/cancel", dependencies=[Depends(authorize)])
    def cancel(task_id: str):
        task = store.get(task_id)
        if task is None:
            raise HTTPException(status_code=404, detail="Task not found")
        if task["state"] not in {"CREATED", "PLANNED", "WAITING_APPROVAL"}:
            raise HTTPException(status_code=409, detail="Task cannot be cancelled from this state")
        store.transition(task_id, "CANCELLED", detail="User cancelled")
        return store.get(task_id)

    return app

# Startup must fail closed if the token is missing.
app = create_app()
