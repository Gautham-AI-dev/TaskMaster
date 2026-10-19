# TaskMaster roadmap — Android first

## Milestone 1: Standalone Android MVP (must ship first)
- Build a working Android APK that runs without a PC, backend server, account, or cloud service.
- Local task creation, task list, status transitions, persistence, and audit trail.
- Explicit user review and approval for consequential actions.
- Deterministic, narrowly scoped Android-native actions via supported platform APIs (e.g. compose a share intent, open a URL, draft a reminder). Never claim an action happened without verifying its result.
- Offline operation for core functionality; safe permissions and clear errors.
- Unit/widget tests, on-device smoke tests, successful CI APK build.

## Milestone 2: On-device agent intelligence
- Evaluate on-device open-weight model feasibility and memory/latency by target device.
- Plan/act/verify loop constrained by an allowlisted action registry.
- Android permissions and platform policy compliance; no unrestricted accessibility assumptions.

## Milestone 3: Optional private PC worker
- Only after milestone 1 ships: authenticated pairing, transport security, delegated heavy workloads, local model inference.

## Milestone 4: Optional cloud
- Strictly opt-in, privacy- and budget-constrained tasks.

## Current migration requirement
The existing Flutter UI is a remote FastAPI client, **not** the standalone MVP. Replace that dependency with on-device persistence and action execution before calling milestone 1 complete. Keep the Python backend as an optional future PC component; it is not a prerequisite for the Android MVP.
