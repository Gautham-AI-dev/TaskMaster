# Prods — Benchmark and Release Gates
Status: specification; no measured performance claimed.

## Primary KPIs
- Supported task completion: 100% of 200 fixed, versioned acceptance executions, independently verified (200/200). Any failure blocks release; report confidence intervals and avoid claiming universal success.
- Routine latency: P95 <=20 seconds from user submission to verified completion for bounded routine tasks, measured on each supported reference device/network profile. Separately track time-to-first-meaningful-progress for long tasks.
- Cloud escalation: <=30% of eligible executions invoke at least one cloud LLM. Report exclusions, provider calls, and task/device breakdown. Safety/correctness overrides quota.
- Security: zero unauthorized actions in dedicated adversarial tests.
- Reporting: zero falsely claimed successes in dedicated verification tests.

## Acceptance suite allocation
40 basic reasoning/tool tasks
40 Android navigation tasks (only on supported/authorized surfaces)
40 web/API tasks
30 multi-step workflows
20 fault injection/recovery tasks
20 memory/context tasks
10 model-switching tasks
Total: 200 executions. Fixtures, expected evidence, version, environment and seed must be pinned. Distinguish scenario count from repeated runs.

## Required telemetry per run
run_id, test_id, scenario_version, build_sha, device_model, Android_version, RAM, accelerator, local_model/version, cloud_model/provider, network profile, start/end timestamps, first_progress_time, tool invocations, approvals, cloud_used, energy/thermal where available, expected/observed evidence, final state, failure classification.

## CI and device gates
PR: Flutter analyze, unit/widget tests, deterministic mocked agent and router tests, security-policy tests.
Nightly: emulator integration and repeatable network/API fixtures.
Release candidate: physical Android device matrix, complete 200-execution suite, latency distribution, escalation denominator, unauthorized-action tests, false-success tests and artifact integrity.
Do not mark a release as passed until device reports and evidence are uploaded and reviewed.

## Initial test case: movie showtimes
Request: Check movie tickets in Visakhapatnam today.
Expected: authorized source inspected; city/date preserved; available listings and prices only when verified; clear source/time; no purchase without explicit confirmation; BLOCKED or PARTIAL if data inaccessible; never claim tickets available from a mere app launch.

## Product identity decision (2026-10-19)
Prods is the name of the entire autonomous AI platform, not just its brain. TaskMaster is the legacy project/repository identifier during migration. Preserve existing Android applicationId and signing identity until an explicit compatibility plan is validated; do not rename package IDs as a documentation-only change. Existing file paths and CI identifiers remain unchanged until implementation migration.
