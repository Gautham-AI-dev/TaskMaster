# TaskMaster architecture

- Flutter Android client: task creation, task status and approvals.
- FastAPI backend: task API and SQLite persistence.
- Optional Ollama: local model inference without paid API calls.
- Optional Playwright worker: browser automation with explicit approval for consequential actions.
- GitHub Actions: debug APK builds using hosted runners within applicable free limits.

This project will not promise unlimited free cloud hosting. Do not expose the local backend directly to the public Internet.
