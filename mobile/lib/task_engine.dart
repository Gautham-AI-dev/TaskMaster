import 'task_repository.dart';

/// Deterministic offline MVP engine. Never interprets a goal as code.
class TaskEngine {
  const TaskEngine();

  LocalTask create(String goal) {
    final trimmed = goal.trim();
    if (trimmed.isEmpty || trimmed.length > 5000) {
      throw ArgumentError('Task goal must be 1–5000 characters');
    }
    return LocalTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      goal: trimmed,
      state: 'CREATED',
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  LocalTask prepare(LocalTask task) {
    if (task.state != 'CREATED') throw StateError('Task already prepared');
    if (!task.goal.startsWith('echo: ')) {
      throw UnsupportedError('Only echo: tasks are supported in this MVP');
    }
    return task.copyWith(state: 'WAITING_APPROVAL');
  }

  LocalTask executeApproved(LocalTask task) {
    if (task.state != 'WAITING_APPROVAL') {
      throw StateError('Task not awaiting approval');
    }
    if (!task.goal.startsWith('echo: ')) {
      throw UnsupportedError('Unsupported action');
    }
    final expected = task.goal.substring('echo: '.length);
    final output = expected;
    if (output != expected) throw StateError('Result verification failed');
    return task.copyWith(state: 'COMPLETED', result: output);
  }

  LocalTask cancel(LocalTask task) {
    if (task.state == 'COMPLETED' || task.state == 'CANCELLED') {
      throw StateError('Task is already terminal');
    }
    return task.copyWith(state: 'CANCELLED');
  }
}
