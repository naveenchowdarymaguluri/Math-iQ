import 'dart:convert';

class TriviaQuestion {
  final String category;
  final String type;
  final String difficulty;
  final String question;
  final String correctAnswer;
  final List<String> options;

  const TriviaQuestion({
    required this.category,
    required this.type,
    required this.difficulty,
    required this.question,
    required this.correctAnswer,
    required this.options,
  });

  factory TriviaQuestion.fromBase64Json(Map<String, dynamic> json) {
    String decode(String s) {
      try {
        return utf8.decode(base64.decode(s));
      } catch (_) {
        return s;
      }
    }

    final question = decode(json['question'] as String? ?? '');
    final correct = decode(json['correct_answer'] as String? ?? '');
    final incorrect = ((json['incorrect_answers'] as List<dynamic>?) ?? [])
        .map((e) => decode(e.toString()))
        .toList();

    final allOptions = [correct, ...incorrect]..shuffle();

    return TriviaQuestion(
      category: decode(json['category'] as String? ?? ''),
      type: decode(json['type'] as String? ?? ''),
      difficulty: decode(json['difficulty'] as String? ?? ''),
      question: question,
      correctAnswer: correct,
      options: allOptions,
    );
  }

  factory TriviaQuestion.raw({
    required String category,
    required String difficulty,
    required String question,
    required String correctAnswer,
    required List<String> incorrectAnswers,
  }) {
    final opts = [correctAnswer, ...incorrectAnswers]..shuffle();
    return TriviaQuestion(
      category: category,
      type: 'multiple',
      difficulty: difficulty,
      question: question,
      correctAnswer: correctAnswer,
      options: opts,
    );
  }
}
