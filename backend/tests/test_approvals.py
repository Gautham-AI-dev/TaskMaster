import os
import tempfile
import unittest
from taskmaster.approvals import ApprovalStore

class ApprovalTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.store = ApprovalStore(os.path.join(self.tmp.name, "db.sqlite"))

    def tearDown(self):
        self.tmp.cleanup()

    def test_approval_is_explicit_single_use_and_exact(self):
        grant = self.store.request("t", "echo", {"goal": "echo: yes"})
        self.assertFalse(self.store.consume(grant["id"], "t", "echo", {"goal": "echo: yes"}))
        self.assertFalse(self.store.approve(grant["id"], "t", "echo", {"goal": "echo: no"}))
        self.assertTrue(self.store.approve(grant["id"], "t", "echo", {"goal": "echo: yes"}))
        self.assertFalse(self.store.consume(grant["id"], "t", "echo", {"goal": "echo: no"}))
        self.assertTrue(self.store.consume(grant["id"], "t", "echo", {"goal": "echo: yes"}))
        self.assertFalse(self.store.consume(grant["id"], "t", "echo", {"goal": "echo: yes"}))

    def test_revoke(self):
        grant = self.store.request("t", "echo", {})
        self.assertTrue(self.store.revoke(grant["id"]))
        self.assertFalse(self.store.approve(grant["id"], "t", "echo", {}))

    def test_restart(self):
        grant = self.store.request("t", "echo", {})
        reopened = ApprovalStore(self.store.path)
        self.assertTrue(reopened.approve(grant["id"], "t", "echo", {}))
        self.assertTrue(reopened.consume(grant["id"], "t", "echo", {}))

    def test_invalid_ttl(self):
        with self.assertRaises(ValueError):
            self.store.request("t", "echo", {}, 0)
