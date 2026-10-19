# Prods — Autonomous AI Platform Architecture Blueprint
Status: proposed architecture; implementation not yet complete.
Decision: fully automatic model selection with hybrid local/cloud execution. Preserve the existing Flutter chat UX and working Android APK pipeline.

## Product contract
One chat interface accepts natural-language tasks and displays progress, approvals, evidence and final status. No dedicated UI per external app, tool or MCP. Platform-required permission dialogs and optional settings are exceptions.
Never report completion based solely on launching an app or tapping a control. Distinguish COMPLETED, PARTIAL, BLOCKED, FAILED, CANCELLED, and AWAITING_APPROVAL.

## Layered architecture
1. Flutter presentation: chat composer, task timeline, approval prompts, results.
2. Agent runtime: task state machine, planner, bounded observe-act-verify loop, retries, cancellation, checkpointing, tool execution log.
3. Automatic hybrid model router: hardware profiler; model capability registry; local inference adapter(s); authorized cloud provider adapters; per-subtask routing; cost, latency, privacy and confidence budgets.
4. Capability registry: typed native Android actions, browser/API integrations, MCP clients, skills and reusable workflows. Treat tool outputs as untrusted.
5. Digital organs: Eyes = accessible UI semantics and consented screenshots/vision; Ears = permissioned speech input; Hands = platform-permitted intents and actions; Voice = speech output. Keep organ interfaces independent of models.
6. Memory: task state, user-approved preferences, verified reusable procedures, provenance, expiration and secure persistence.
7. Policy and verification: scoped permissions, approval gates for payments/messages/account changes, prompt-injection defenses, independent evidence verification and audit logs.
8. Evaluation: deterministic unit tests, emulator integration, real-device benchmark and regression reporting.

## Automatic routing
Prefer capable local models when privacy, hardware and performance permit; use cloud models when locally unavailable, unreliable or too slow, subject to explicit authorization and data-sharing preferences. Do not equate a consumer AI subscription with API access. Route subtasks independently when useful. Never suppress necessary escalation solely to satisfy a quota. Track model selection and reasons.

## Android distribution constraints
General-purpose autonomous cross-app AccessibilityService use is not automatically Play-compliant. Separate Play-compatible API/intents flows from research/developer experimental UI automation. Obtain explicit Android permissions and respect secure surfaces, third-party terms and OS restrictions. No bypass of platform protections.

## Build milestones
M0 Baseline audit, benchmark contract and CI scaffolding.
M1 Agent runtime, typed task state, deterministic mock tools, verification tests.
M2 Hardware profiling, local inference prototype and cloud provider adapters.
M3 Perception and action interfaces; approved native Android capabilities; experimental UI research in isolated builds.
M4 Tool/skill/MCP registry and permission enforcement.
M5 Verified memory, recovery and subtask scheduling.
M6 Real-device benchmarking, security testing, release gating and APK promotion.

## Acceptance
100% completion on the fixed, versioned supported-task acceptance suite; 0 false-success and 0 unauthorized actions in their dedicated suites. P95 routine end-to-end completion latency <=20s for tasks that are designated routine and bounded; for longer tasks separately measure first meaningful progress response. Cloud escalation <=30% of eligible task executions, counting any cloud-model invocation as escalated. Report denominator, device class, network conditions and exclusions. Never silently narrow the supported suite.

## Initial source audit (2026-10-19)
mobile/lib/main.dart uses ChatRouter, BookMyShowLauncher and SharedPreferences chat history. mobile/lib/chat_router.dart is rule-based, not an LLM. mobile/lib/bookmyshow_launcher.dart uses url_launcher to open https://in.bookmyshow.com/ externally; it cannot inspect availability. mobile/lib/settings_screen.dart describes integrations as unavailable. mobile/pubspec.yaml version 0.2.0+2; dependencies shared_preferences and url_launcher. .github/workflows/android-apk.yml analyzes, tests and builds a debug APK, with Android scaffold generated during CI. Preserve this pipeline while extending tests.

## Research directions to validate, not assume production-ready
OpenPhone (ACL Findings 2026): https://aclanthology.org/2026.findings-acl.1518/
Mobile-Agent-v3.5: https://arxiv.org/abs/2602.16855
HybridFlow (ICML 2026): https://proceedings.mlr.press/v306/dong26g.html
SE-GA (ICML 2026): https://proceedings.mlr.press/v306/jin26m.html
VenusBench-Mobile (ICML 2026): https://proceedings.mlr.press/v306/gong26a.html
Benchmarks and model claims must be reproduced on supported Prods hardware before product claims.

## Product identity decision (2026-10-19)
Prods is the name of the entire autonomous AI platform, not just its brain. TaskMaster is the legacy project/repository identifier during migration. Preserve existing Android applicationId and signing identity until an explicit compatibility plan is validated; do not rename package IDs as a documentation-only change. Existing file paths and CI identifiers remain unchanged until implementation migration.
