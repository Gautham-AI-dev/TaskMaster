import os
import tempfile
import unittest

from taskmaster.api import create_app


class ApiTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.app = create_app(os.path.join(self.tmp.name, "test.db"), "a" * 32)
        from fastapi.testclient import TestClient
        self.client = TestClient(self.app)
        self.auth = {"Authorization": "Bearer " + "a" * 32}

    def tearDown(self):
        self.client.close()
        self.tmp.cleanup()

    def test_requires_token(self):
        self.assertEqual(self.client.get("/v1/tasks").status_code, 401)

    def test_create_and_list(self):
        response = self.client.post("/v1/tasks", json={"goal": "Research", "classification": "private"}, headers=self.auth)
        self.assertEqual(response.status_code, 201)
        task_id = response.json()["id"]
        self.assertEqual(self.client.get("/v1/tasks/" + task_id, headers=self.auth).status_code, 200)
        self.assertEqual(len(self.client.get("/v1/tasks", headers=self.auth).json()), 1)
        self.assertEqual(len(self.client.get("/v1/tasks/" + task_id + "/events", headers=self.auth).json()), 1)

    def test_invalid_classification(self):
        response = self.client.post("/v1/tasks", json={"goal": "Research", "classification": "unknown"}, headers=self.auth)
        self.assertEqual(response.status_code, 422)


if __name__ == "__main__":
    unittest.main()
