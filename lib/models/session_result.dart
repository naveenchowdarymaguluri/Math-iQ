class SessionResult {
  final String mode; // e.g. "Practice +", "Flag Quiz"
  final int correct;
  final int wrong;
  final int total;
  final int xpEarned;
  final int highestStreak; // consecutive correct answers in this session
  final DateTime date;

  const SessionResult({
    required this.mode,
    required this.correct,
    required this.wrong,
    required this.total,
    required this.xpEarned,
    required this.highestStreak,
    required this.date,
  });

  double get accuracy => total > 0 ? correct / total : 0.0;
  bool get isPerfect => total > 0 && wrong == 0;

  /// JSON round-trip for SharedPreferences storage.
  Map<String, dynamic> toJson() => {
        'mode': mode,
        'correct': correct,
        'wrong': wrong,
        'total': total,
        'xpEarned': xpEarned,
        'highestStreak': highestStreak,
        'date': date.toIso8601String(),
      };

  factory SessionResult.fromJson(Map<String, dynamic> j) => SessionResult(
        mode: j['mode'] as String? ?? '',
        correct: j['correct'] as int? ?? 0,
        wrong: j['wrong'] as int? ?? 0,
        total: j['total'] as int? ?? 0,
        xpEarned: j['xpEarned'] as int? ?? 0,
        highestStreak: j['highestStreak'] as int? ?? 0,
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
      );
}
