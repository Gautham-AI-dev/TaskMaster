import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster/main.dart';

void main() {
  testWidgets('Standalone TaskMaster creates and prepares offline tasks', (tester) async {
    await tester.pumpWidget(const TaskMasterApp());
    expect(find.text('Standalone Android MVP'), findsOneWidget);
    expect(find.text('Create task'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'echo: Hello');
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();
    expect(find.text('echo: Hello'), findsOneWidget);
    expect(find.text('Prepare'), findsOneWidget);
    await tester.tap(find.text('Prepare'));
    await tester.pumpAndSettle();
    expect(find.text('Review and approve'), findsOneWidget);
  });
}
