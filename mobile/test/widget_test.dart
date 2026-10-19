import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster/main.dart';

void main() {
  testWidgets('TaskMaster shows backend connection and task creation', (tester) async {
    await tester.pumpWidget(const TaskMasterApp());
    expect(find.text('TaskMaster'), findsOneWidget);
    expect(find.text('Connect / Refresh tasks'), findsOneWidget);
    expect(find.text('Create task'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
  });
}
