import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster/chat_router.dart';

void main() {
  const router = ChatRouter();
  test('routes natural language movie ticket request', () {
    expect(router.route('Check movie tickets on BookMyShow').intent, ChatIntent.bookMyShow);
  });
  test('does not claim unsupported actions succeeded', () {
    expect(router.route('Send an email').intent, ChatIntent.unsupported);
  });
  test('echo intent is deterministic', () {
    expect(router.route('echo: hi').reply, 'hi');
  });
}
