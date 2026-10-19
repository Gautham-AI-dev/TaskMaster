# TaskMaster implementation status

## Connected demonstration workflow

1. Authenticated POST /v1/tasks with {"goal":"echo: hello"}.
2. Authenticated POST /v1/tasks/{id}/prepare creates an expiring, **unapproved** exact-action grant and transitions to WAITING_APPROVAL.
3. User explicitly reviews and approves using POST /v1/tasks/{id}/approve with {"approval_id":"..."}.
4. POST /v1/tasks/{id}/run with the same approval_id consumes the grant once, invokes the safe echo worker, verifies output and records COMPLETED.
5. POST /v1/tasks/{id}/cancel cancels eligible unexecuted tasks.

The Android Flutter UI exposes prepare, review/approve, run and cancel controls for this demonstration. The approval ID is held in memory; if the app restarts, the grant is not recoverable through the current API. Create a new task if needed. This is not yet a secure paired-device identity model.

## Tests

Python unittest suites cover routing, SQLite state, API auth, approval lifecycle and end-to-end echo execution. Flutter widget test covers basic UI. CI workflows are configured, but a passing CI run and APK artifact have **not yet been verified**.

## Boundaries

- Only literal `echo: ` goals are executable; never arbitrary shell commands.
- No autonomous LLM agent, browser control or Android accessibility automation yet.
- No secure Android-to-PC pairing yet. Do not expose the FastAPI server publicly.
- A shared bearer token is an MVP authentication mechanism, not per-user/per-device authorization.
- This is a demonstration of a user-approved execution lifecycle, not production-grade distributed execution.
