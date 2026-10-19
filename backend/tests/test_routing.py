import unittest
from taskmaster.routing import Task, Worker, choose_worker


def worker(name, environment, caps=frozenset({"browser"}), cost=0, healthy=True, reliability=0.9):
    return Worker(name, environment, caps, healthy, cost, reliability, 100)


class RoutingPolicyTests(unittest.TestCase):
    def test_restricted_never_cloud(self):
        task = Task("1", "restricted", frozenset({"browser"}), frozenset({"cloud", "private_pc"}))
        selected = choose_worker(task, [worker("cloud", "cloud", reliability=1), worker("pc", "private_pc")])
        self.assertEqual(selected.worker_id, "pc")

    def test_private_cloud_denied(self):
        task = Task("2", "private", frozenset({"browser"}), frozenset({"cloud"}))
        self.assertIsNone(choose_worker(task, [worker("cloud", "cloud")]))

    def test_missing_capability_denied(self):
        task = Task("3", "public", frozenset({"android.action"}), frozenset({"android"}))
        self.assertIsNone(choose_worker(task, [worker("phone", "android")]))

    def test_paid_worker_denied_at_zero_budget(self):
        task = Task("4", "public", frozenset({"browser"}), frozenset({"cloud"}))
        self.assertIsNone(choose_worker(task, [worker("paid", "cloud", cost=0.01)]))

    def test_unhealthy_worker_denied(self):
        task = Task("5", "public", frozenset({"browser"}), frozenset({"private_pc"}))
        self.assertIsNone(choose_worker(task, [worker("pc", "private_pc", healthy=False)]))

    def test_best_reliability_then_latency(self):
        task = Task("6", "public", frozenset({"browser"}), frozenset({"private_pc"}))
        a = worker("a", "private_pc", reliability=0.8)
        b = worker("b", "private_pc", reliability=0.95)
        self.assertEqual(choose_worker(task, [a, b]), b)

    def test_unknown_classification_rejected(self):
        with self.assertRaises(ValueError):
            choose_worker(Task("7", "secretish", frozenset(), frozenset({"cloud"})), [])


if __name__ == "__main__":
    unittest.main()
