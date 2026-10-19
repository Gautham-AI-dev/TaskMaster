import 'task.dart';

/// Deterministic execution core. This is not yet an LLM planner or Android automation.
/// A successful tool invocation alone NEVER implies task completion.
class AgentRuntime {
  const AgentRuntime({required this.tool, required this.verifier});
  final AgentTool tool;
  final OutcomeVerifier verifier;

  Future<AgentTask> run(AgentTask task) async {
    if (task.status != TaskStatus.pending) {
      throw StateError('Only pending tasks can be executed');
    }
    try {
      final result = await tool.execute(task.request);
      final evidence = [...task.evidence, ...result.evidence];
      if (!result.succeeded) {
        return task.copyWith(status: TaskStatus.failed, evidence: evidence);
      }
      if (evidence.isEmpty) {
        return task.copyWith(status: TaskStatus.partial, evidence: evidence);
      }
      final verified = await verifier.verify(task.copyWith(evidence: evidence), result);
      return task.copyWith(
        status: verified ? TaskStatus.completed : TaskStatus.partial,
        evidence: evidence,
      );
    } catch (_) {
      return task.copyWith(status: TaskStatus.failed);
    }
  }
}
