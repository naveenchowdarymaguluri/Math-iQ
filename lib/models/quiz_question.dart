import 'dart:math' as math;

enum Operation { addition, subtraction, multiplication, division }

enum Difficulty { easy, medium, hard }

class QuizQuestion {
  final int num1;
  final int num2;
  final Operation operation;
  final int correctAnswer;
  final List<int> options;

  const QuizQuestion({
    required this.num1,
    required this.num2,
    required this.operation,
    required this.correctAnswer,
    required this.options,
  });

  String get questionText {
    final symbol = switch (operation) {
      Operation.addition => '+',
      Operation.subtraction => '−',
      Operation.multiplication => '×',
      Operation.division => '÷',
    };
    return '$num1 $symbol $num2 = ?';
  }

  static List<QuizQuestion> generate({
    required Difficulty difficulty,
    required Operation operation,
    required int rangeStart,
    required int rangeEnd,
    int count = 10,
  }) {
    final rand = _SimpleRandom();
    final questions = <QuizQuestion>[];

    for (int i = 0; i < count; i++) {
      int n1 = rangeStart + rand.nextInt(rangeEnd - rangeStart + 1);
      int n2 = rangeStart + rand.nextInt(rangeEnd - rangeStart + 1);
      int answer;

      if (operation == Operation.subtraction && n2 > n1) {
        final tmp = n1;
        n1 = n2;
        n2 = tmp;
      }
      if (operation == Operation.division) {
        if (n2 == 0) n2 = 1;
        n1 = n2 * (rangeStart + rand.nextInt(10) + 1);
      }

      answer = switch (operation) {
        Operation.addition => n1 + n2,
        Operation.subtraction => n1 - n2,
        Operation.multiplication => n1 * n2,
        Operation.division => n1 ~/ n2,
      };

      final opts = _generateOptions(answer, rand);
      questions.add(QuizQuestion(
        num1: n1,
        num2: n2,
        operation: operation,
        correctAnswer: answer,
        options: opts,
      ));
    }
    return questions;
  }

  /// Generates [count] questions cycling through [operations] using a single
  /// random instance — avoids duplicate questions from same-millisecond seeds.
  static List<QuizQuestion> generateMixed({
    required Difficulty difficulty,
    required List<Operation> operations,
    required int rangeStart,
    required int rangeEnd,
    int count = 5,
  }) {
    final rand = _SimpleRandom();
    final questions = <QuizQuestion>[];
    for (int i = 0; i < count; i++) {
      final operation = operations[rand.nextInt(operations.length)];
      int n1 = rangeStart + rand.nextInt(rangeEnd - rangeStart + 1);
      int n2 = rangeStart + rand.nextInt(rangeEnd - rangeStart + 1);

      if (operation == Operation.subtraction && n2 > n1) {
        final tmp = n1;
        n1 = n2;
        n2 = tmp;
      }
      if (operation == Operation.division) {
        if (n2 == 0) n2 = 1;
        n1 = n2 * (rangeStart + rand.nextInt(10) + 1);
      }

      final answer = switch (operation) {
        Operation.addition => n1 + n2,
        Operation.subtraction => n1 - n2,
        Operation.multiplication => n1 * n2,
        Operation.division => n1 ~/ n2,
      };
      questions.add(QuizQuestion(
        num1: n1,
        num2: n2,
        operation: operation,
        correctAnswer: answer,
        options: _generateOptions(answer, rand),
      ));
    }
    return questions;
  }

  static List<int> _generateOptions(int correct, _SimpleRandom rand) {
    final opts = <int>{correct};
    int attempts = 0;
    while (opts.length < 4 && attempts < 50) {
      attempts++;
      final offset = rand.nextInt(20) - 10;
      final val = correct + offset;
      if (offset != 0 && (correct < 0 || val >= 0)) {
        opts.add(val);
      }
    }
    int fallback = 1;
    while (opts.length < 4) {
      opts.add(correct + fallback);
      fallback++;
    }
    final list = opts.toList()..shuffle();
    return list;
  }
}

class _SimpleRandom {
  final math.Random _rand = math.Random();

  int nextInt(int max) {
    if (max <= 0) return 0;
    return _rand.nextInt(max);
  }
}
