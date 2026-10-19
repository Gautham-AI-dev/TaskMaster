import os
import tempfile
import unittest
from taskmaster.store import TaskStore
from taskmaster.worker import execute_echo_task

class WorkerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.store = TaskStore(os.path.join(self.tmp.name, "tasks.db"))

    def tearDown(self):
        self.tmp.cleanup()

    def test_verified_echo(self):
        task = self.store.create("echo: hello TaskMaster", "private")
        self.store.transition(task["id"], "PLANNED")
        result = execute_echo_task(self.store, task["id"])
        self.assertEqual(result.output, "hello TaskMaster")
        self.assertEqual(self.store.get(task["id"])["state"], "COMPLETED")

    def test_arbitrary_goal_not_executed(self):
        task = self.store.create("rm -rf /", "private")
        self.store.transition(task["id"], "PLANNED")
        with self.assertRaises(ValueError):
            execute_echo_task(self.store, task["id"])
        self.assertEqual(self.store.get(task["id"])["state"], "PLANNED")

if __name__ == "__main__":
    unittest.main()
