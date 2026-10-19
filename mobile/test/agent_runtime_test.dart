import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster/agent/runtime.dart';
import 'package:taskmaster/agent/task.dart';

class FakeTool implements AgentTool {
  FakeTool(this.result);
  final ToolResult result;
  @override String get name => 'fake';
  @override Future<ToolResult> execute(String request) async => result;
}

class FakeVerifier implements OutcomeVerifier {
  FakeVerifier(this.approved);
  final bool approved;
  @override Future<bool> verify(AgentTask task, ToolResult result) async => approved;
}

void main() {
  const task = AgentTask(id: 't1', request: 'Check movie listings');

  test('verified evidence permits completed status', () async {
    final runtime = AgentRuntime(
      tool: FakeTool(const ToolResult(succeeded: true, message: 'Found', evidence: ['fixture:showtime'])),
      verifier: FakeVerifier(true),
    );
    expect((await runtime.run(task)).status, TaskStatus.completed);
  });

  test('successful tool without evidence is not completed', () async {
    final runtime = AgentRuntime(
      tool: FakeTool(const ToolResult(succeeded: true, message: 'Opened app')),
      verifier: FakeVerifier(true),
    );
    expect((await runtime.run(task)).status, TaskStatus.partial);
  });

  test('failed verification is partial, not completed', () async {
    final runtime = AgentRuntime(
      tool: FakeTool(const ToolResult(succeeded: true, message: 'Found', evidence: ['unverified'])),
      verifier: FakeVerifier(false),
    );
    expect((await runtime.run(task)).status, TaskStatus.partial);
  });

  test('failed tool reports failed', () async {
    final runtime = AgentRuntime(
      tool: FakeTool(const ToolResult(succeeded: false, message: 'Unavailable')),
      verifier: FakeVerifier(true),
    );
    expect((await runtime.run(task)).status, TaskStatus.failed);
  });

  test('nonpending tasks cannot restart silently', () async {
    final runtime = AgentRuntime(
      tool: FakeTool(const ToolResult(succeeded: true, message: 'ok')),
      verifier: FakeVerifier(true),
    );
    expect(() => runtime.run(task.copyWith(status: TaskStatus.completed)), throwsStateError);
  });
}
