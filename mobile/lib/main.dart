import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const TaskMasterApp());

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TaskMaster',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const TaskHome(),
      );
}

class TaskHome extends StatefulWidget {
  const TaskHome({super.key});

  @override
  State<TaskHome> createState() => _TaskHomeState();
}

class _TaskHomeState extends State<TaskHome> {
  final _url = TextEditingController();
  final _token = TextEditingController();
  final _goal = TextEditingController();
  final _client = http.Client();
  bool _busy = false;
  String _message = 'Connect to your private TaskMaster backend.';
  List<dynamic> _tasks = [];

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    _goal.dispose();
    _client.close();
    super.dispose();
  }

  Uri _endpoint(String path) {
    final base = Uri.tryParse(_url.text.trim());
    if (base == null ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.query.isNotEmpty ||
        base.fragment.isNotEmpty ||
        base.path != '' && base.path != '/' ||
        (base.scheme != 'https' &&
            !(base.scheme == 'http' &&
                (base.host == '127.0.0.1' ||
                    base.host == 'localhost' ||
                    base.host == '10.0.2.2')))) {
      throw const FormatException(
        'Use an HTTPS backend URL. HTTP is allowed only for local development.',
      );
    }
    return base.replace(path: path);
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${_token.text.trim()}',
        'Content-Type': 'application/json',
      };

  Future<void> _run(Future<String> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await action().timeout(const Duration(seconds: 15));
      if (mounted) setState(() => _message = result);
    } catch (e) {
      if (mounted) setState(() => _message = 'Request failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() => _run(() async {
        final response = await _client.get(
          _endpoint('/v1/tasks'),
          headers: _headers,
        );
        if (response.statusCode != 200) {
          return 'Backend error: HTTP ${response.statusCode}';
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! List) return 'Unexpected backend response';
        if (mounted) setState(() => _tasks = decoded);
        return 'Loaded ${decoded.length} task(s).';
      });

  Future<void> _create() => _run(() async {
        final goal = _goal.text.trim();
        if (goal.isEmpty) return 'Enter a task goal first.';
        final response = await _client.post(
          _endpoint('/v1/tasks'),
          headers: _headers,
          body: jsonEncode({'goal': goal, 'classification': 'private'}),
        );
        if (response.statusCode != 201) {
          return 'Create failed: HTTP ${response.statusCode}';
        }
        final decoded = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _tasks = [decoded, ..._tasks];
            _goal.clear();
          });
        }
        return 'Task created. Execution worker is not yet connected.';
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('TaskMaster')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Private backend connection',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Use a trusted HTTPS endpoint. Tokens remain in memory and are not saved on the device.'),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'https://your-private-host',
              ),
            ),
            TextField(
              controller: _token,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'API token'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _busy ? null : _refresh,
              child: const Text('Connect / Refresh tasks'),
            ),
            const Divider(height: 32),
            TextField(
              controller: _goal,
              minLines: 2,
              maxLines: 4,
              maxLength: 5000,
              decoration: const InputDecoration(
                labelText: 'New task goal',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton(
              onPressed: _busy ? null : _create,
              child: const Text('Create task'),
            ),
            const SizedBox(height: 12),
            Text(_message, key: const Key('status')),
            const SizedBox(height: 12),
            const Text('Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            for (final task in _tasks)
              Card(
                child: ListTile(
                  title: Text(task['goal']?.toString() ?? 'Untitled'),
                  subtitle: Text(task['state']?.toString() ?? 'Unknown'),
                ),
              ),
          ],
        ),
      );
}
