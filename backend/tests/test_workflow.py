import os
import tempfile
import unittest
from fastapi.testclient import TestClient
from taskmaster.api import create_app

class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.client = TestClient(create_app(os.path.join(self.tmp.name, "db.sqlite"), "a" * 32))
        self.auth = {"Authorization": "Bearer " + "a" * 32}

    def tearDown(self):
        self.client.close()
        self.tmp.cleanup()

    def post(self, path, body=None, auth=True):
        return self.client.post(path, json=body or {}, headers=self.auth if auth else {})

    def test_complete_approved_workflow(self):
        created = self.post("/v1/tasks", {"goal": "echo: hello", "classification": "private"}).json()
        base = "/v1/tasks/" + created["id"]
        grant = self.post(base + "/prepare").json()
        self.assertFalse(grant["approved"])
        self.assertEqual(self.post(base + "/run", {"approval_id": grant["id"]}).status_code, 409)
        self.assertEqual(self.post(base + "/approve", {"approval_id": grant["id"]}, auth=False).status_code, 401)
        self.assertEqual(self.post(base + "/approve", {"approval_id": grant["id"]}).status_code, 200)
        result = self.post(base + "/run", {"approval_id": grant["id"]})
        self.assertEqual(result.status_code, 200)
        self.assertEqual(result.json()["output"], "hello")
        self.assertEqual(self.post(base + "/run", {"approval_id": grant["id"]}).status_code, 409)
        self.assertEqual(self.client.get(base, headers=self.auth).json()["state"], "COMPLETED")
        self.assertEqual(len(self.client.get(base + "/events", headers=self.auth).json()), 6)

    def test_cancel_prevents_execution(self):
        created = self.post("/v1/tasks", {"goal": "echo: hello"}).json()
        base = "/v1/tasks/" + created["id"]
        grant = self.post(base + "/prepare").json()
        self.assertEqual(self.post(base + "/cancel").status_code, 200)
        self.assertEqual(self.post(base + "/approve", {"approval_id": grant["id"]}).status_code, 409)

    def test_unsupported_goal_rejected(self):
        created = self.post("/v1/tasks", {"goal": "delete everything"}).json()
        self.assertEqual(self.post("/v1/tasks/" + created["id"] + "/prepare").status_code, 422)

if __name__ == "__main__":
    unittest.main()
