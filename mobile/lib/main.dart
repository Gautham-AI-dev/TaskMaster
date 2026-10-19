import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bookmyshow_launcher.dart';
import 'chat_router.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(TaskMasterApp(preferences: prefs));
}

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key, this.preferences});
  final SharedPreferences? preferences;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TaskMaster',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: ChatHome(preferences: preferences),
      );
}

class ChatMessage {
  const ChatMessage(this.role, this.text);
  final String role;
  final String text;
  Map<String, String> toJson() => {'role': role, 'text': text};
  factory ChatMessage.fromJson(Map<String, dynamic> data) =>
      ChatMessage(data['role'] as String, data['text'] as String);
}

class ChatHome extends StatefulWidget {
  const ChatHome({super.key, this.preferences});
  final SharedPreferences? preferences;

  @override
  State<ChatHome> createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  final _input = TextEditingController();
  final _router = const ChatRouter();
  final _launcher = const BookMyShowLauncher();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _busy = false;
  static const _historyKey = 'taskmaster.chat.v1';

  @override
  void initState() {
    super.initState();
    final stored = widget.preferences?.getStringList(_historyKey) ?? [];
    for (final line in stored) {
      final index = line.indexOf(':');
      if (index < 0) continue;
      final role = line.substring(0, index);
      if (role == 'user' || role == 'assistant') {
        _messages.add(ChatMessage(role, line.substring(index + 1)));
      }
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _append(String role, String message) async {
    setState(() => _messages.add(ChatMessage(role, message)));
    final prefs = widget.preferences;
    if (prefs != null) {
      try {
        await prefs.setStringList(
          _historyKey,
          _messages.map((item) => '${item.role}:${item.text}').toList(),
        );
      } catch (_) {
        if (mounted) {
          setState(() => _messages.add(const ChatMessage(
                'assistant', 'Warning: conversation could not be saved locally.',
              )));
        }
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    setState(() => _busy = true);
    try {
      await _append('user', text);
      final route = _router.route(text);
      if (route.intent != ChatIntent.bookMyShow) {
        await _append('assistant', route.reply);
        return;
      }
      if (!mounted) return;
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Open BookMyShow?'),
          content: const Text(
            'TaskMaster will open BookMyShow externally. '
            'It cannot yet inspect showtimes or verify availability.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open app'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (approved != true) {
        await _append('assistant', 'Cancelled. I did not open BookMyShow.');
        return;
      }
      final launched = await _launcher.open();
      await _append(
        'assistant',
        launched
            ? 'Opened BookMyShow (or its website). Search for your movie and city there. '
              'I cannot yet confirm ticket availability.'
            : 'I could not open BookMyShow on this device.',
      );
    } catch (error) {
      await _append('assistant', 'The request failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('TaskMaster'),
          actions: [
            IconButton(
              tooltip: 'Settings & integrations',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const TaskMasterSettings(),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'What can I help you with?\n\n'
                            'Try: Check movie tickets on BookMyShow',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final item = _messages[index];
                          return Align(
                            alignment: item.role == 'user'
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Card(
                              color: item.role == 'user'
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(item.text),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        key: const Key('chat-input'),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask TaskMaster anything...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Send',
                      onPressed: _busy ? null : _send,
                      icon: const Icon(Icons.arrow_upward),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
