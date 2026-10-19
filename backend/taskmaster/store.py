"""Durable SQLite task state with transactional transitions and audit events."""
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

STATES = {"CREATED", "PLANNED", "RUNNING", "WAITING_APPROVAL", "PAUSED", "RETRYING", "COMPLETED", "FAILED", "CANCELLED"}
TRANSITIONS = {
    "CREATED": {"PLANNED", "CANCELLED"},
    "PLANNED": {"RUNNING", "WAITING_APPROVAL", "CANCELLED"},
    "RUNNING": {"WAITING_APPROVAL", "PAUSED", "RETRYING", "COMPLETED", "FAILED", "CANCELLED"},
    "WAITING_APPROVAL": {"PLANNED", "CANCELLED"},
    "PAUSED": {"RUNNING", "CANCELLED"},
    "RETRYING": {"RUNNING", "FAILED", "CANCELLED"},
    "COMPLETED": set(), "FAILED": set(), "CANCELLED": set(),
}


def now():
    return datetime.now(timezone.utc).isoformat()


class TaskStore:
    def __init__(self, path: str):
        self.path = str(Path(path))
        with self._connect() as db:
            db.execute("""CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY, goal TEXT NOT NULL, classification TEXT NOT NULL,
                state TEXT NOT NULL, verified INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL, updated_at TEXT NOT NULL
            )""")
            db.execute("""CREATE TABLE IF NOT EXISTS events (
                id INTEGER PRIMARY KEY AUTOINCREMENT, task_id TEXT NOT NULL,
                state TEXT NOT NULL, detail TEXT NOT NULL, created_at TEXT NOT NULL,
                FOREIGN KEY(task_id) REFERENCES tasks(id)
            )""")

    def _connect(self):
        db = sqlite3.connect(self.path, timeout=10)
        db.row_factory = sqlite3.Row
        db.execute("PRAGMA foreign_keys=ON")
        return db

    def create(self, goal: str, classification: str):
        if not goal.strip() or len(goal) > 5000:
            raise ValueError("Goal must be 1–5000 characters")
        if classification not in {"public", "private", "restricted"}:
            raise ValueError("Invalid classification")
        task_id, timestamp = str(uuid4()), now()
        with self._connect() as db:
            db.execute("INSERT INTO tasks VALUES (?, ?, ?, ?, ?, ?, ?)",
                       (task_id, goal, classification, "CREATED", 0, timestamp, timestamp))
            db.execute("INSERT INTO events(task_id,state,detail,created_at) VALUES (?,?,?,?)",
                       (task_id, "CREATED", "Task created", timestamp))
        return self.get(task_id)

    def get(self, task_id: str):
        with self._connect() as db:
            row = db.execute("SELECT * FROM tasks WHERE id=?", (task_id,)).fetchone()
            return dict(row) if row else None

    def list(self):
        with self._connect() as db:
            return [dict(row) for row in db.execute("SELECT * FROM tasks ORDER BY created_at DESC")]

    def events(self, task_id: str):
        with self._connect() as db:
            return [dict(row) for row in db.execute(
                "SELECT id,task_id,state,detail,created_at FROM events WHERE task_id=? ORDER BY id", (task_id,))]

    def transition(self, task_id: str, new_state: str, *, detail: str = "", verified: bool = False):
        if new_state not in STATES:
            raise ValueError("Unknown state")
        if len(detail) > 2000:
            raise ValueError("Detail too long")
        with self._connect() as db:
            db.execute("BEGIN IMMEDIATE")
            row = db.execute("SELECT state,verified FROM tasks WHERE id=?", (task_id,)).fetchone()
            if row is None:
                raise KeyError(task_id)
            if new_state not in TRANSITIONS[row["state"]]:
                raise ValueError(f"Illegal transition {row['state']} -> {new_state}")
            if new_state == "COMPLETED" and not verified:
                raise ValueError("Completion requires independently verified result")
            timestamp = now()
            db.execute("UPDATE tasks SET state=?,verified=?,updated_at=? WHERE id=?",
                       (new_state, int(verified) if new_state == "COMPLETED" else row["verified"], timestamp, task_id))
            db.execute("INSERT INTO events(task_id,state,detail,created_at) VALUES (?,?,?,?)",
                       (task_id, new_state, detail, timestamp))
        return self.get(task_id)
