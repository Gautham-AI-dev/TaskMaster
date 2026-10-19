# TaskMaster backend MVP

Requires Python 3.11+.

```bash
cd backend
python -m venv .venv
# Activate the virtual environment for your OS
pip install -r requirements.txt
export TASKMASTER_API_TOKEN="$(python -c 'import secrets; print(secrets.token_urlsafe(32))')"
PYTHONPATH=. python -m unittest discover -s tests -v
PYTHONPATH=. uvicorn taskmaster.api:app --host 127.0.0.1 --port 8000
```

On Windows PowerShell, set the environment variable using `$env:TASKMASTER_API_TOKEN = ...`.

Example (replace YOUR_TOKEN with the secret from the same shell):

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" -H "Content-Type: application/json" -d '{"goal":"Prepare a report","classification":"private"}' http://127.0.0.1:8000/v1/tasks
```

**Security:** This is a local development API, not an internet-exposed service. Use localhost binding. A production mobile connection needs authenticated device pairing, TLS/private network, per-device authorization, and a separate authenticated worker execution API. The current API records tasks but **does not autonomously execute them**.
