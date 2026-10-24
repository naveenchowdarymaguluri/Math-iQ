import 'package:flutter_test/flutter_test.dart';
import 'package:mathiq/main.dart';
import 'package:mathiq/models/quiz_question.dart';
import 'package:mathiq/models/challenge_level.dart';
import 'package:mathiq/services/level_service.dart';
import 'package:mathiq/models/trivia_question.dart';
import 'package:mathiq/services/trivia_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  test('LevelService batch saves, loads, and resets progress correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = LevelService.instance;
    await svc.resetAll();
    expect(svc.grandTotalStars, 0);

    await svc.recordResult(
      mode: ChallengeMode.beginner,
      level: 1,
      correct: 10,
      total: 10,
    );

    expect(svc.starsFor(ChallengeMode.beginner, 1), greaterThan(0));
    expect(svc.grandTotalStars, greaterThan(0));

    // Reload from storage
    await svc.load();
    expect(svc.starsFor(ChallengeMode.beginner, 1), greaterThan(0));

    // Reset
    await svc.resetAll();
    expect(svc.grandTotalStars, 0);
  });

  test('TriviaQuestion decodes OpenTDB base64 JSON properly', () {
    // base64 for "What is 2 + 2?", "4", and ["3", "5", "6"]
    final json = {
      'category': 'U2NpZW5jZTogTWF0aGVtYXRpY3M=',
      'type': 'bXVsdGlwbGU=',
      'difficulty': 'ZWFzeQ==',
      'question': 'V2hhdCBpcyAyICsgMj8=',
      'correct_answer': 'NA==',
      'incorrect_answers': ['Mw==', 'NQ==', 'Ng=='],
    };

    final q = TriviaQuestion.fromBase64Json(json);
    expect(q.category, 'Science: Mathematics');
    expect(q.type, 'multiple');
    expect(q.difficulty, 'easy');
    expect(q.question, 'What is 2 + 2?');
    expect(q.correctAnswer, '4');
    expect(q.options.length, 4);
    expect(q.options.contains('4'), isTrue);
  });

  test('TriviaService returns fallback questions if offline or API unavailable', () async {
    final questions = await TriviaService.instance.fetchQuestions(
      amount: 5,
      categoryId: 19,
    );
    expect(questions.isNotEmpty, isTrue);
    expect(questions.first.options.length, 4);
  });
}
