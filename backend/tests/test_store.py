import os
import tempfile
import unittest

from taskmaster.store import TaskStore


class StoreTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.path = os.path.join(self.tmp.name, "tasks.db")
        self.store = TaskStore(self.path)

    def tearDown(self):
        self.tmp.cleanup()

    def test_persists_after_restart(self):
        task = self.store.create("Prepare report", "restricted")
        self.store.transition(task["id"], "PLANNED")
        reopened = TaskStore(self.path)
        self.assertEqual(reopened.get(task["id"])["state"], "PLANNED")
        self.assertEqual(len(reopened.events(task["id"])), 2)

    def test_cannot_complete_without_verification(self):
        task = self.store.create("Test", "public")
        self.store.transition(task["id"], "PLANNED")
        self.store.transition(task["id"], "RUNNING")
        with self.assertRaises(ValueError):
            self.store.transition(task["id"], "COMPLETED")
        self.assertEqual(self.store.get(task["id"])["state"], "RUNNING")
        self.assertEqual(self.store.transition(task["id"], "COMPLETED", verified=True)["verified"], 1)

    def test_cannot_resume_cancelled(self):
        task = self.store.create("Test", "private")
        self.store.transition(task["id"], "CANCELLED")
        with self.assertRaises(ValueError):
            self.store.transition(task["id"], "RUNNING")

    def test_invalid_classification(self):
        with self.assertRaises(ValueError):
            self.store.create("Test", "secret")

    def test_unknown_task(self):
        with self.assertRaises(KeyError):
            self.store.transition("missing", "PLANNED")


if __name__ == "__main__":
    unittest.main()
