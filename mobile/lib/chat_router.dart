enum ChatIntent { bookMyShow, echo, unsupported }

class ChatRoute {
  const ChatRoute(this.intent, this.reply);
  final ChatIntent intent;
  final String reply;
}

/// Transparent offline rule routing, not an LLM.
class ChatRouter {
  const ChatRouter();

  ChatRoute route(String message) {
    final text = message.trim();
    if (text.isEmpty) return const ChatRoute(ChatIntent.unsupported, 'Type a request to begin.');
    final lower = text.toLowerCase();
    if (lower.startsWith('echo: ')) {
      return ChatRoute(ChatIntent.echo, text.substring(6));
    }
    if (lower.contains('bookmyshow') ||
        ((lower.contains('movie') || lower.contains('film')) &&
            (lower.contains('ticket') || lower.contains('showtime')))) {
      return const ChatRoute(
        ChatIntent.bookMyShow,
        'I can open BookMyShow. I cannot yet search its listings or verify ticket availability automatically.',
      );
    }
    return const ChatRoute(
      ChatIntent.unsupported,
      'I saved your request, but this offline prototype cannot perform it yet. Try asking to open BookMyShow or use "echo: hello".',
    );
  }
}
