import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalTask {
  final String id;
  final String goal;
  final String state;
  final String createdAt;
  final String? result;

  const LocalTask({
    required this.id,
    required this.goal,
    required this.state,
    required this.createdAt,
    this.result,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goal': goal,
        'state': state,
        'createdAt': createdAt,
        'result': result,
      };

  factory LocalTask.fromJson(Map<String, dynamic> json) => LocalTask(
        id: json['id'] as String,
        goal: json['goal'] as String,
        state: json['state'] as String,
        createdAt: json['createdAt'] as String,
        result: json['result'] as String?,
      );

  LocalTask copyWith({String? state, String? result}) => LocalTask(
        id: id,
        goal: goal,
        state: state ?? this.state,
        createdAt: createdAt,
        result: result ?? this.result,
      );
}

class TaskRepository {
  TaskRepository(this._preferences);
  final SharedPreferences _preferences;
  static const _key = 'taskmaster.tasks.v1';

  List<LocalTask> load() {
    final stored = _preferences.getString(_key);
    if (stored == null) return [];
    final decoded = jsonDecode(stored) as List<dynamic>;
    return decoded
        .map((item) => LocalTask.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<LocalTask> tasks) async {
    final ok = await _preferences.setString(
      _key,
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
    if (!ok) throw StateError('Local task storage failed');
  }
}
