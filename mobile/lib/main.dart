import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'task_engine.dart';
import 'bookmyshow_launcher.dart';
import 'movie_availability.dart';
import 'task_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(TaskMasterApp(repository: TaskRepository(preferences)));
}

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key, this.repository});

  final TaskRepository? repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TaskMaster',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: TaskHome(repository: repository),
      );
}

class TaskHome extends StatefulWidget {
  const TaskHome({super.key, this.repository});
  final TaskRepository? repository;

  @override
  State<TaskHome> createState() => _TaskHomeState();
}

class _TaskHomeState extends State<TaskHome> {
  final _goal = TextEditingController();
  final _movie = TextEditingController();
  final _city = TextEditingController();
  final _bookMyShow = const BookMyShowLauncher();
  final _engine = const TaskEngine();
  List<LocalTask> _tasks = [];
  String _message = 'Offline mode: no PC, account, or internet required.';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    try {
      _tasks = widget.repository?.load() ?? [];
    } catch (_) {
      _tasks = [];
      _message = 'Stored tasks could not be read. Existing data was not deleted.';
    }
  }

  @override
  void dispose() {
    _goal.dispose();
    _movie.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _persist(List<LocalTask> next) async {
    final repository = widget.repository;
    if (repository != null) await repository.save(next);
    if (mounted) setState(() => _tasks = next);
  }

  Future<void> _openBookMyShow() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final request = MovieAvailabilityRequest(movie: _movie.text, city: _city.text);
      final opened = await _bookMyShow.open();
      if (!mounted) return;
      setState(() => _message = opened
          ? 'Opened BookMyShow. Search for ${request.movie} in ${request.city} and inspect showtimes. Ticket availability is not yet automatically verified.'
          : 'Could not open BookMyShow.');
    } catch (error) {
      if (mounted) setState(() => _message = 'Movie search failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final task = _engine.create(_goal.text);
      await _persist([task, ..._tasks]);
      _goal.clear();
      if (mounted) setState(() => _message = 'Task saved on this device.');
    } catch (error) {
      if (mounted) setState(() => _message = 'Could not create task: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _update(LocalTask task, LocalTask Function(LocalTask) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final next = action(task);
      await _persist([
        for (final existing in _tasks)
          if (existing.id == task.id) next else existing,
      ]);
      if (mounted) setState(() => _message = 'Task status: ${next.state}');
    } catch (error) {
      if (mounted) setState(() => _message = 'Action failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(LocalTask task) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve local action?'),
        content: Text(
          'Task: ${task.goal}\n\n'
          'Action: display the text after "echo:". '
          'No network requests or other app actions will occur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Deny'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve and run'),
          ),
        ],
      ),
    );
    if (approved == true && mounted) {
      await _update(task, _engine.executeApproved);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('TaskMaster')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Standalone Android MVP',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Tasks are stored locally. No backend connection is required.'),
            const SizedBox(height: 16),
            const Text('First automation: BookMyShow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _movie, decoration: const InputDecoration(labelText: 'Movie name')),
            TextField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
            FilledButton.tonal(onPressed: _busy ? null : _openBookMyShow, child: const Text('Open BookMyShow to check tickets')),
            const Divider(height: 32),
            TextField(
              controller: _goal,
              minLines: 2,
              maxLines: 4,
              maxLength: 5000,
              decoration: const InputDecoration(
                labelText: 'New task goal',
                hintText: 'echo: Hello TaskMaster',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton(
              onPressed: _busy ? null : _create,
              child: const Text('Create task'),
            ),
            const SizedBox(height: 12),
            Text(_message, key: const Key('status')),
            const Divider(height: 32),
            const Text(
              'My tasks',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            for (final task in _tasks)
              Card(
                key: ValueKey(task.id),
                child: ListTile(
                  title: Text(task.goal),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.state),
                      if (task.result != null) Text('Result: ${task.result}'),
                      if (task.state == 'CREATED' && task.goal.startsWith('echo: '))
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _update(task, _engine.prepare),
                          child: const Text('Prepare'),
                        ),
                      if (task.state == 'WAITING_APPROVAL')
                        TextButton(
                          onPressed: _busy ? null : () => _review(task),
                          child: const Text('Review and approve'),
                        ),
                      if (task.state == 'CREATED' || task.state == 'WAITING_APPROVAL')
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _update(task, _engine.cancel),
                          child: const Text('Cancel'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}
