import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster/main.dart';

void main() {
  testWidgets('Chat-first Prods shows a single composer and settings', (tester) async {
    await tester.pumpWidget(const TaskMasterApp());
    expect(find.text('Prods'), findsOneWidget);
    expect(find.byKey(const Key('chat-input')), findsOneWidget);
    expect(find.byTooltip('Settings & integrations'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('chat-input')), 'echo: hello');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('echo: hello'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });
}
