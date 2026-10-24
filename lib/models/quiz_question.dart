import 'dart:math' as math;

enum Operation {
  addition,
  subtraction,
  multiplication,
  division,
  modulo,
  exponent,
  squareRoot,
  percentage,
  preAlgebra,
}

enum Difficulty { easy, medium, hard }

class QuizQuestion {
  final int num1;
  final int num2;
  final Operation operation;
  final int correctAnswer;
  final List<int> options;
  final String? customQuestionText;

  const QuizQuestion({
    required this.num1,
    required this.num2,
    required this.operation,
    required this.correctAnswer,
    required this.options,
    this.customQuestionText,
  });

  String get questionText {
    if (customQuestionText != null) return customQuestionText!;
    return switch (operation) {
      Operation.addition => '$num1 + $num2 = ?',
      Operation.subtraction => '$num1 − $num2 = ?',
      Operation.multiplication => '$num1 × $num2 = ?',
      Operation.division => '$num1 ÷ $num2 = ?',
      Operation.modulo => '$num1 % $num2 = ?',
      Operation.exponent => num2 == 2
          ? '$num1² = ?'
          : (num2 == 3 ? '$num1³ = ?' : '$num1 ^ $num2 = ?'),
      Operation.squareRoot => '√$num1 = ?',
      Operation.percentage => '$num1% of $num2 = ?',
      Operation.preAlgebra => '$num1 + ? = $num2',
    };
  }

  static List<QuizQuestion> generate({
    required Difficulty difficulty,
    required Operation operation,
    required int rangeStart,
    required int rangeEnd,
    int count = 10,
  }) {
    final rand = _SimpleRandom();
    return List.generate(
      count,
      (_) => _generateSingle(
        operation: operation,
        difficulty: difficulty,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        rand: rand,
      ),
    );
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
    final ops = operations.isEmpty ? [Operation.addition] : operations;
    return List.generate(
      count,
      (_) => _generateSingle(
        operation: ops[rand.nextInt(ops.length)],
        difficulty: difficulty,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        rand: rand,
      ),
    );
  }

  static QuizQuestion _generateSingle({
    required Operation operation,
    required Difficulty difficulty,
    required int rangeStart,
    required int rangeEnd,
    required _SimpleRandom rand,
  }) {
    int n1 = 0;
    int n2 = 0;
    int answer = 0;
    String? customText;

    final span = math.max(1, rangeEnd - rangeStart + 1);

    switch (operation) {
      case Operation.addition:
        n1 = rangeStart + rand.nextInt(span);
        n2 = rangeStart + rand.nextInt(span);
        answer = n1 + n2;
        break;

      case Operation.subtraction:
        n1 = rangeStart + rand.nextInt(span);
        n2 = rangeStart + rand.nextInt(span);
        if (n2 > n1) {
          final tmp = n1;
          n1 = n2;
          n2 = tmp;
        }
        answer = n1 - n2;
        break;

      case Operation.multiplication:
        final maxMultiplier = switch (difficulty) {
          Difficulty.easy => 10,
          Difficulty.medium => 15,
          Difficulty.hard => 25,
        };
        n1 = rangeStart + rand.nextInt(math.min(span, maxMultiplier));
        n2 = rangeStart + rand.nextInt(math.min(span, maxMultiplier));
        if (n1 == 0) n1 = 1;
        if (n2 == 0) n2 = 1;
        answer = n1 * n2;
        break;

      case Operation.division:
        final maxDivisor = switch (difficulty) {
          Difficulty.easy => 10,
          Difficulty.medium => 12,
          Difficulty.hard => 20,
        };
        n2 = rand.nextInt(maxDivisor - 1) + 2; // 2..maxDivisor
        final quotient = rand.nextInt(maxDivisor) + 1;
        n1 = n2 * quotient;
        answer = quotient;
        break;

      case Operation.modulo:
        n2 = rand.nextInt(8) + 2; // 2..9
        final quotient = rand.nextInt(8) + 1;
        final remainder = rand.nextInt(n2 - 1) + 1; // 1..n2-1
        n1 = n2 * quotient + remainder;
        answer = remainder;
        break;

      case Operation.exponent:
        if (difficulty == Difficulty.easy) {
          n1 = rand.nextInt(11) + 2; // 2..12
          n2 = 2; // squares
          answer = n1 * n1;
        } else if (difficulty == Difficulty.medium) {
          final isCube = rand.nextInt(3) == 0;
          if (isCube) {
            n1 = rand.nextInt(4) + 2; // 2..5
            n2 = 3;
            answer = n1 * n1 * n1;
          } else {
            n1 = rand.nextInt(9) + 11; // 11..19
            n2 = 2;
            answer = n1 * n1;
          }
        } else {
          if (rand.nextInt(2) == 0) {
            n1 = 2;
            n2 = rand.nextInt(6) + 3; // 2^3 to 2^8
            answer = math.pow(2, n2).toInt();
          } else {
            n1 = rand.nextInt(11) + 15; // 15..25
            n2 = 2;
            answer = n1 * n1;
          }
        }
        break;

      case Operation.squareRoot:
        final rootMax = switch (difficulty) {
          Difficulty.easy => 10,
          Difficulty.medium => 15,
          Difficulty.hard => 25,
        };
        final root = rand.nextInt(rootMax - 1) + 2; // 2..rootMax
        n1 = root * root;
        n2 = 2;
        answer = root;
        break;

      case Operation.percentage:
        final pcts = switch (difficulty) {
          Difficulty.easy => [10, 20, 50],
          Difficulty.medium => [10, 20, 25, 50, 75],
          Difficulty.hard => [5, 10, 15, 20, 25, 30, 40, 50, 75],
        };
        n1 = pcts[rand.nextInt(pcts.length)];
        final baseFactor = (n1 % 25 == 0) ? 4 : (n1 % 10 == 0 ? 10 : 20);
        final multiplier = rand.nextInt(10) + 1;
        n2 = baseFactor * multiplier * (difficulty == Difficulty.hard ? 5 : 2);
        answer = (n2 * n1) ~/ 100;
        break;

      case Operation.preAlgebra:
        final isMul = (difficulty != Difficulty.easy) && rand.nextInt(2) == 0;
        if (isMul) {
          final a = rand.nextInt(10) + 2;
          final b = rand.nextInt(10) + 2;
          final c = a * b;
          if (rand.nextInt(2) == 0) {
            n1 = b;
            n2 = c;
            answer = a;
            customText = '? × $b = $c';
          } else {
            n1 = a;
            n2 = c;
            answer = b;
            customText = '$a × ? = $c';
          }
        } else {
          final a = rand.nextInt(30) + 5;
          final b = rand.nextInt(30) + 5;
          final c = a + b;
          if (rand.nextInt(2) == 0) {
            n1 = b;
            n2 = c;
            answer = a;
            customText = '? + $b = $c';
          } else {
            n1 = a;
            n2 = c;
            answer = b;
            customText = '$a + ? = $c';
          }
        }
        break;
    }

    final opts = _generateOptions(answer, rand);
    return QuizQuestion(
      num1: n1,
      num2: n2,
      operation: operation,
      correctAnswer: answer,
      options: opts,
      customQuestionText: customText,
    );
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
