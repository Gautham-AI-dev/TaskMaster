enum TaskStatus { pending, running, awaitingApproval, completed, partial, blocked, failed, cancelled }

class AgentTask {
  const AgentTask({required this.id, required this.request, this.status = TaskStatus.pending, this.evidence = const []});
  final String id;
  final String request;
  final TaskStatus status;
  final List<String> evidence;

  AgentTask copyWith({TaskStatus? status, List<String>? evidence}) => AgentTask(
    id: id, request: request, status: status ?? this.status, evidence: evidence ?? this.evidence,
  );
}

class ToolResult {
  const ToolResult({required this.succeeded, required this.message, this.evidence = const []});
  final bool succeeded;
  final String message;
  final List<String> evidence;
}

abstract class AgentTool {
  String get name;
  Future<ToolResult> execute(String request);
}

abstract class OutcomeVerifier {
  Future<bool> verify(AgentTask task, ToolResult result);
}
