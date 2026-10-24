import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trivia_question.dart';

class TriviaCategory {
  final int? id;
  final String title;
  final String emoji;

  const TriviaCategory({required this.id, required this.title, required this.emoji});
}

class TriviaService {
  static final TriviaService instance = TriviaService._();
  TriviaService._();

  static const List<TriviaCategory> categories = [
    TriviaCategory(id: 19, title: 'Mathematics', emoji: '📐'),
    TriviaCategory(id: 17, title: 'Science & Nature', emoji: '🔬'),
    TriviaCategory(id: 18, title: 'Computers & Tech', emoji: '💻'),
    TriviaCategory(id: 9, title: 'General Knowledge', emoji: '🧠'),
    TriviaCategory(id: null, title: 'Mixed Trivia', emoji: '🎲'),
  ];

  /// Fetch questions from Open Trivia Database API (https://opentdb.com/api.php)
  /// Uses base64 encoding to prevent encoding issues with special characters.
  Future<List<TriviaQuestion>> fetchQuestions({
    int amount = 10,
    int? categoryId,
    String? difficulty, // 'easy', 'medium', 'hard', or null for any
  }) async {
    final params = <String, String>{
      'amount': '$amount',
      'type': 'multiple',
      'encode': 'base64',
    };
    if (categoryId != null) {
      params['category'] = '$categoryId';
    }
    if (difficulty != null && difficulty.isNotEmpty && difficulty != 'any') {
      params['difficulty'] = difficulty.toLowerCase();
    }

    final uri = Uri.https('opentdb.com', '/api.php', params);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final responseCode = data['response_code'] as int? ?? -1;

        if (responseCode == 0) {
          final results = data['results'] as List<dynamic>? ?? [];
          final list = results
              .map((q) => TriviaQuestion.fromBase64Json(q as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {
      // Network failed or timed out — fall back to offline questions
    }

    return _getFallbackQuestions(categoryId: categoryId);
  }

  /// Curated offline fallback questions when network is unavailable.
  List<TriviaQuestion> _getFallbackQuestions({int? categoryId}) {
    final pool = <TriviaQuestion>[
      TriviaQuestion.raw(
        category: 'Science: Mathematics',
        difficulty: 'easy',
        question: 'What prime number comes next after 19?',
        correctAnswer: '23',
        incorrectAnswers: ['21', '25', '27'],
      ),
      TriviaQuestion.raw(
        category: 'Science: Mathematics',
        difficulty: 'easy',
        question: 'Which ancient Greek mathematician shouted "Eureka!"?',
        correctAnswer: 'Archimedes',
        incorrectAnswers: ['Euclid', 'Pythagoras', 'Aristotle'],
      ),
      TriviaQuestion.raw(
        category: 'Science: Mathematics',
        difficulty: 'medium',
        question: 'What is the sum of angles in a triangle?',
        correctAnswer: '180°',
        incorrectAnswers: ['90°', '270°', '360°'],
      ),
      TriviaQuestion.raw(
        category: 'Science: Mathematics',
        difficulty: 'medium',
        question: 'Who is regarded as the "Prince of Mathematicians"?',
        correctAnswer: 'Carl Friedrich Gauss',
        incorrectAnswers: ['Isaac Newton', 'Leonhard Euler', 'René Descartes'],
      ),
      TriviaQuestion.raw(
        category: 'Science: Mathematics',
        difficulty: 'hard',
        question: 'What is the value of Euler\'s number (e) rounded to two decimal places?',
        correctAnswer: '2.72',
        incorrectAnswers: ['3.14', '1.62', '2.41'],
      ),
      TriviaQuestion.raw(
        category: 'Science & Nature',
        difficulty: 'easy',
        question: 'What is the chemical symbol for Gold?',
        correctAnswer: 'Au',
        incorrectAnswers: ['Ag', 'Gd', 'Fe'],
      ),
      TriviaQuestion.raw(
        category: 'Science: Computers',
        difficulty: 'easy',
        question: 'How many bits are in a single byte?',
        correctAnswer: '8',
        incorrectAnswers: ['4', '16', '32'],
      ),
      TriviaQuestion.raw(
        category: 'Science: Computers',
        difficulty: 'medium',
        question: 'Who is often credited as the world\'s first computer programmer?',
        correctAnswer: 'Ada Lovelace',
        incorrectAnswers: ['Alan Turing', 'Charles Babbage', 'Grace Hopper'],
      ),
      TriviaQuestion.raw(
        category: 'General Knowledge',
        difficulty: 'easy',
        question: 'How many degrees are in a full circle?',
        correctAnswer: '360',
        incorrectAnswers: ['180', '240', '400'],
      ),
      TriviaQuestion.raw(
        category: 'Science: Mathematics',
        difficulty: 'medium',
        question: 'What is the Fibonacci sequence number after 0, 1, 1, 2, 3, 5, 8?',
        correctAnswer: '13',
        incorrectAnswers: ['11', '12', '15'],
      ),
    ];

    if (categoryId == 19) {
      final mathOnly = pool.where((q) => q.category.contains('Mathematics')).toList();
      if (mathOnly.length >= 4) return mathOnly;
    }

    return pool;
  }
}
