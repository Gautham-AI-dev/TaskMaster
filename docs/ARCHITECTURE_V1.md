# TaskMaster architecture specification v1.0
Status: proposed implementation baseline (2026-10-19).

## Objective
Free-first hybrid Android + private-PC agent, with optional permitted cloud workers. No claim of always-on free hosting or guaranteed autonomous success.

## Trust boundaries
1. Android UI is a user control surface; Kotlin adapters perform permitted device actions.
2. FastAPI accepts authenticated task requests and persists immutable audit events.
3. Policy engine is deterministic and denies by default. Model suggestions cannot grant permissions.
4. Scheduler selects only healthy workers with required capabilities, allowed data residency and zero monetary cost.
5. PC worker executes approved actions in constrained workspaces. Browser data and model output are untrusted.
6. External cloud is opt-in per task; restricted data never leaves local devices.
7. Each consequential action requires a scoped, expiring approval tied to task, tool and arguments.

## Task contract
Required fields: task_id, goal, data_classification (public/private/restricted), required_capabilities, allowed_environments, risk_level, max_monetary_cost, and verification.
States: CREATED, PLANNED, RUNNING, WAITING_APPROVAL, PAUSED, RETRYING, COMPLETED, FAILED, CANCELLED.
A task can be COMPLETED only after its verification predicate passes. External side effects require idempotency keys and reconciliation; exactly-once execution is not assumed.

## Execution priorities
Typed app functions / APIs > intents > authorized deterministic Android actions > permitted visual automation > manual handoff.
Android lifecycle restrictions apply. The phone must not be treated as an unlimited background server.

## Security invariants
- No executor selection before policy eligibility.
- No unapproved financial transfers, external messages, destructive actions, or credential modifications.
- Approval tokens are single-action, time-bounded and non-transferable.
- Tool output never changes user permissions or high-trust memory.
- Sensitive task data is not transferred to unapproved cloud workers.
- Logs redact secrets and preserve provenance.
- Cancel and revoke must prevent new actions; in-flight side effects require reconciliation.
- Self-improvement changes are proposed, benchmarked, versioned and reversible.

## Initial delivery slices
1. Pure-Python routing policy and unit tests.
2. SQLite task state and audit events with recovery tests.
3. FastAPI authenticated pairing and task endpoints.
4. Flutter UI plus Kotlin capability bridge.
5. Private PC worker and optional Ollama.
6. Playwright browser adapter with explicit approvals.
7. CI tests and Android APK build after Flutter scaffolding exists.

## Acceptance gates
- Deny restricted data on cloud even when cloud is fastest.
- Deny workers missing required capabilities.
- Deny paid workers when task budget is zero.
- Pause sensitive actions pending exact approval.
- Recover task state after restart without duplicating external side effects.
- Verify actual artifacts or device state before completion.
- Never silently escalate permissions after model or tool suggestions.

## Research validation backlog
Check current Android AccessibilityService distribution policy and AppFunctions device support before implementing UI automation. Reproduce mobile benchmarks on supported devices rather than extrapolating published percentages. Evaluate local model tool-call accuracy, latency, and memory use on actual hardware.
