import 'package:flutter_test/flutter_test.dart';
import 'package:mathiq/main.dart';
import 'package:mathiq/models/quiz_question.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MathIQApp());
    expect(find.byType(MathIQApp), findsOneWidget);
  });

  test('QuizQuestion options are distinct and non-negative for small numbers', () {
    final questions = QuizQuestion.generate(
      difficulty: Difficulty.easy,
      operation: Operation.addition,
      rangeStart: 1,
      rangeEnd: 3,
      count: 20,
    );

    for (final q in questions) {
      expect(q.options.length, 4);
      expect(q.options.toSet().length, 4, reason: 'All 4 options must be unique');
      expect(q.options.contains(q.correctAnswer), isTrue, reason: 'Must contain correct answer');
      for (final opt in q.options) {
        expect(opt >= 0, isTrue, reason: 'Options must be non-negative for small kids questions');
      }
    }
  });
}
