"""Single-use action approvals. Requesting is NOT approving."""
import hashlib
import json
import secrets
import sqlite3
from datetime import datetime, timedelta, timezone

def _canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

class ApprovalStore:
    def __init__(self, db_path: str):
        self.path = db_path
        with self._connect() as db:
            db.execute("""CREATE TABLE IF NOT EXISTS approvals (
                id TEXT PRIMARY KEY, task_id TEXT NOT NULL, action TEXT NOT NULL,
                args_hash TEXT NOT NULL, expires_at TEXT NOT NULL,
                approved_at TEXT, consumed_at TEXT, revoked_at TEXT
            )""")
            columns = {r[1] for r in db.execute("PRAGMA table_info(approvals)")}
            if "approved_at" not in columns:
                db.execute("ALTER TABLE approvals ADD COLUMN approved_at TEXT")

    def _connect(self):
        db = sqlite3.connect(self.path, timeout=10)
        db.execute("PRAGMA busy_timeout=10000")
        return db

    def request(self, task_id: str, action: str, args: dict, ttl_seconds: int = 300) -> dict:
        if not task_id or not action or not isinstance(args, dict):
            raise ValueError("Invalid approval request")
        if not 1 <= ttl_seconds <= 3600:
            raise ValueError("TTL out of range")
        approval_id = secrets.token_urlsafe(24)
        expiry = (datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)).isoformat()
        digest = hashlib.sha256(_canonical(args).encode()).hexdigest()
        with self._connect() as db:
            db.execute("INSERT INTO approvals(id,task_id,action,args_hash,expires_at) VALUES (?,?,?,?,?)",
                       (approval_id, task_id, action, digest, expiry))
        return {"id": approval_id, "task_id": task_id, "action": action,
                "args": args, "expires_at": expiry, "approved": False}

    def get(self, approval_id: str):
        with self._connect() as db:
            db.row_factory = sqlite3.Row
            row = db.execute("SELECT * FROM approvals WHERE id=?", (approval_id,)).fetchone()
            return dict(row) if row else None

    def approve(self, approval_id: str, task_id: str, action: str, args: dict) -> bool:
        digest = hashlib.sha256(_canonical(args).encode()).hexdigest()
        timestamp = datetime.now(timezone.utc).isoformat()
        with self._connect() as db:
            db.execute("BEGIN IMMEDIATE")
            cursor = db.execute("""UPDATE approvals SET approved_at=?
                WHERE id=? AND task_id=? AND action=? AND args_hash=?
                AND approved_at IS NULL AND consumed_at IS NULL AND revoked_at IS NULL
                AND expires_at>?""",
                (timestamp, approval_id, task_id, action, digest, timestamp))
            return cursor.rowcount == 1

    def consume(self, approval_id: str, task_id: str, action: str, args: dict) -> bool:
        digest = hashlib.sha256(_canonical(args).encode()).hexdigest()
        timestamp = datetime.now(timezone.utc).isoformat()
        with self._connect() as db:
            db.execute("BEGIN IMMEDIATE")
            cursor = db.execute("""UPDATE approvals SET consumed_at=?
                WHERE id=? AND task_id=? AND action=? AND args_hash=?
                AND approved_at IS NOT NULL AND consumed_at IS NULL AND revoked_at IS NULL
                AND expires_at>?""",
                (timestamp, approval_id, task_id, action, digest, timestamp))
            return cursor.rowcount == 1

    def revoke(self, approval_id: str) -> bool:
        with self._connect() as db:
            cursor = db.execute(
                "UPDATE approvals SET revoked_at=? WHERE id=? AND consumed_at IS NULL AND revoked_at IS NULL",
                (datetime.now(timezone.utc).isoformat(), approval_id))
            return cursor.rowcount == 1
