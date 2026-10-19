"""TaskMaster local API. Requires an explicitly configured bearer token."""
import os
import secrets
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

from .store import TaskStore


class TaskInput(BaseModel):
    goal: str = Field(min_length=1, max_length=5000)
    classification: str = "private"


class TransitionInput(BaseModel):
    state: str
    detail: str = Field(default="", max_length=2000)
    verified: bool = False


def create_app(db_path: str | None = None, api_token: str | None = None) -> FastAPI:
    path = db_path or os.environ.get("TASKMASTER_DB", "taskmaster.sqlite3")
    token = api_token if api_token is not None else os.environ.get("TASKMASTER_API_TOKEN")
    if not token or len(token) < 24:
        raise RuntimeError("Set TASKMASTER_API_TOKEN to a random secret of at least 24 characters")
    store = TaskStore(path)

    def authorize(authorization: str | None = Header(default=None)):
        expected = "Bearer " + token
        if authorization is None or not secrets.compare_digest(authorization, expected):
            raise HTTPException(status_code=401, detail="Unauthorized")

    app = FastAPI(title="TaskMaster Local API", version="0.1.0")

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

    # Transition endpoint is intentionally not public. A future authenticated
    # worker channel will perform server-side verification and transitions.
    return app


# ASGI entry point: requires a configured secret, and fails closed otherwise.
# Run with: uvicorn taskmaster.api:app --host 127.0.0.1 --port 8000
app = create_app() if os.environ.get("TASKMASTER_API_TOKEN") else None
