class WrongAnswerItem {
  final String questionText;
  final int correctAnswer;
  final int? givenAnswer; // null = timeout

  const WrongAnswerItem({
    required this.questionText,
    required this.correctAnswer,
    this.givenAnswer,
  });
}
