import os
import tempfile
import unittest

from taskmaster.approvals import ApprovalStore


class ApprovalTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = os.path.join(self.temp.name, "approvals.sqlite3")
        self.store = ApprovalStore(self.path)

    def tearDown(self):
        self.temp.cleanup()

    def test_single_use_and_argument_binding(self):
        grant = self.store.request("task1", "message.send", {"to": "alice", "body": "hello"})
        self.assertFalse(self.store.consume(grant["id"], "task1", "message.send", {"to": "bob", "body": "hello"}))
        self.assertFalse(self.store.consume(grant["id"], "task2", "message.send", {"to": "alice", "body": "hello"}))
        self.assertTrue(self.store.consume(grant["id"], "task1", "message.send", {"body": "hello", "to": "alice"}))
        self.assertFalse(self.store.consume(grant["id"], "task1", "message.send", {"to": "alice", "body": "hello"}))

    def test_revocation(self):
        grant = self.store.request("task1", "file.delete", {"path": "a"})
        self.assertTrue(self.store.revoke(grant["id"]))
        self.assertFalse(self.store.consume(grant["id"], "task1", "file.delete", {"path": "a"}))

    def test_survives_restart(self):
        grant = self.store.request("task1", "file.write", {"path": "a"})
        reopened = ApprovalStore(self.path)
        self.assertTrue(reopened.consume(grant["id"], "task1", "file.write", {"path": "a"}))

    def test_invalid_ttl(self):
        with self.assertRaises(ValueError):
            self.store.request("task1", "file.write", {}, 0)


if __name__ == "__main__":
    unittest.main()
