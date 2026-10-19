import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster/task_engine.dart';

void main() {
  const engine = TaskEngine();

  test('offline echo requires explicit approval stage', () {
    final task = engine.create('echo: hello');
    final prepared = engine.prepare(task);
    expect(prepared.state, 'WAITING_APPROVAL');
    final finished = engine.executeApproved(prepared);
    expect(finished.state, 'COMPLETED');
    expect(finished.result, 'hello');
  });

  test('arbitrary instructions cannot run', () {
    final task = engine.create('delete files');
    expect(() => engine.prepare(task), throwsUnsupportedError);
  });

  test('cancelled tasks cannot run', () {
    final task = engine.prepare(engine.create('echo: hi'));
    expect(() => engine.executeApproved(engine.cancel(task)), throwsStateError);
  });
}
