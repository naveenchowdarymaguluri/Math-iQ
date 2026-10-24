import 'quiz_question.dart';

enum ChallengeMode {
  beginner,
  explorer,
  challenger,
  master,
  grandmaster,
}

extension ChallengeModeX on ChallengeMode {
  String get displayName => switch (this) {
        ChallengeMode.beginner => 'Beginner',
        ChallengeMode.explorer => 'Explorer',
        ChallengeMode.challenger => 'Challenger',
        ChallengeMode.master => 'Master',
        ChallengeMode.grandmaster => 'Grandmaster',
      };

  String get emoji => switch (this) {
        ChallengeMode.beginner => '😊',
        ChallengeMode.explorer => '🔭',
        ChallengeMode.challenger => '🚩',
        ChallengeMode.master => '🎓',
        ChallengeMode.grandmaster => '👑',
      };

  String get description => switch (this) {
        ChallengeMode.beginner => 'Addition & Subtraction',
        ChallengeMode.explorer => 'Multiplication & Division',
        ChallengeMode.challenger => 'Addition, Subtraction & ×',
        ChallengeMode.master => 'All Four Operations',
        ChallengeMode.grandmaster => 'All Operations — Extreme!',
      };

  String get opsLabel => switch (this) {
        ChallengeMode.beginner => '＋  −',
        ChallengeMode.explorer => '×  ÷',
        ChallengeMode.challenger => '＋  −  ×',
        ChallengeMode.master => '＋  −  ×  ÷  %',
        ChallengeMode.grandmaster => 'All Operations — Extreme!',
      };

  List<Operation> get operations => switch (this) {
        ChallengeMode.beginner => [Operation.addition, Operation.subtraction],
        ChallengeMode.explorer => [
            Operation.multiplication,
            Operation.division,
          ],
        ChallengeMode.challenger => [
            Operation.addition,
            Operation.subtraction,
            Operation.multiplication,
          ],
        ChallengeMode.master => [
            Operation.addition,
            Operation.subtraction,
            Operation.multiplication,
            Operation.division,
            Operation.modulo,
          ],
        ChallengeMode.grandmaster => Operation.values,
      };

  int get primaryColorValue => switch (this) {
        ChallengeMode.beginner => 0xFF4CAF50,
        ChallengeMode.explorer => 0xFF2196F3,
        ChallengeMode.challenger => 0xFFFF9800,
        ChallengeMode.master => 0xFF9C27B0,
        ChallengeMode.grandmaster => 0xFFE91E63,
      };

  int get shadowColorValue => switch (this) {
        ChallengeMode.beginner => 0xFF2E7D32,
        ChallengeMode.explorer => 0xFF1565C0,
        ChallengeMode.challenger => 0xFFE65100,
        ChallengeMode.master => 0xFF6A1B9A,
        ChallengeMode.grandmaster => 0xFFAD1457,
      };
}

class ChallengeLevel {
  final ChallengeMode mode;
  final int level; // 1–100
  final int rangeStart;
  final int rangeEnd;
  final int questionCount;
  final int timeLimitSeconds;
  final int xpReward;
  /// True for levels 51–100: randomly alternate MCQ and keyboard per question.
  final bool useRandomKeyboard;

  const ChallengeLevel({
    required this.mode,
    required this.level,
    required this.rangeStart,
    required this.rangeEnd,
    required this.questionCount,
    required this.timeLimitSeconds,
    required this.xpReward,
    this.useRandomKeyboard = false,
  });

  /// Generate config for a given mode + level (1–100).
  /// 10 tiers × 10 levels each — range and difficulty grow every 10 levels.
  factory ChallengeLevel.forMode(ChallengeMode mode, int level) {
    final l = level.clamp(1, 100);
    final tier = ((l - 1) ~/ 10).clamp(0, 9);
    final hard = tier >= 5; // levels 51-100: random keyboard mode enabled
    return switch (mode) {
      ChallengeMode.beginner => _beginner(l, tier, hard),
      ChallengeMode.explorer => _explorer(l, tier, hard),
      ChallengeMode.challenger => _challenger(l, tier, hard),
      ChallengeMode.master => _master(l, tier, hard),
      ChallengeMode.grandmaster => _grandmaster(l, tier, hard),
    };
  }

  /// 3 stars = 100%, 2 stars = 70%+, 1 star = 50%+, 0 = fail.
  int starsForScore(int correct, int total) {
    if (total == 0) return 0;
    final pct = correct / total;
    if (pct >= 1.0) return 3;
    if (pct >= 0.7) return 2;
    if (pct >= 0.5) return 1;
    return 0;
  }

  // ── Beginner: addition & subtraction ─────────────────────────────────────
  // Range shifts upward every 10 levels: 1-20, 20-40, 40-60, 60-80, 80-100…
  static const _startsBeg = [1,   20,  40,  60,  80,  100, 150, 200, 300,  500];
  static const _endsBeg   = [20,  40,  60,  80,  100, 150, 200, 300, 500, 1000];
  static const _countsBeg = [5,   6,   7,   8,   8,   10,  10,  12,  12,   15];
  static const _timersBeg = [30,  28,  25,  22,  20,  18,  15,  13,  12,   10];
  static const _xpsBeg    = [15,  20,  25,  30,  35,  45,  55,  65,  80,  100];

  // ── Explorer: multiplication & division (smaller operands) ───────────────
  static const _startsExp = [1,  2,  2,  3,  4,   5,   6,   8,  10,  12];
  static const _endsExp   = [5,  8,  10, 12, 15,  18,  20,  22,  25,  30];
  static const _countsExp = [5,  6,  7,  8,  8,   10,  10,  12,  12,  15];
  static const _timersExp = [30, 28, 25, 22, 20,  18,  15,  13,  12,  10];
  static const _xpsExp    = [20, 25, 30, 35, 40,  50,  60,  72,  85, 100];

  // ── Challenger: add / sub / multiply ─────────────────────────────────────
  static const _startsCha = [1,  10, 20, 30, 40,  50,  60,  80, 100, 150];
  static const _endsCha   = [20, 40, 60, 80, 100, 130, 160, 200, 300, 500];
  static const _countsCha = [6,  7,  8,  8,  9,   10,  10,  12,  12,  15];
  static const _timersCha = [25, 22, 20, 18, 15,  14,  13,  11,  10,   9];
  static const _xpsCha    = [25, 30, 35, 40, 50,  60,  72,  85, 100, 120];

  // ── Master: all four operations ───────────────────────────────────────────
  static const _startsMas = [1,  5,  10, 15, 20,  30,  40,  50,  60,  80];
  static const _endsMas   = [20, 40, 70, 100, 140, 180, 220, 280, 360, 500];
  static const _countsMas = [7,  8,  9,  10, 10,  12,  12,  14,  14,  15];
  static const _timersMas = [20, 18, 16, 14, 13,  12,  11,  10,   9,   8];
  static const _xpsMas    = [30, 38, 46, 55, 65,  76,  88, 100, 115, 130];

  // ── Grandmaster: all ops, extreme numbers ─────────────────────────────────
  static const _startsGma = [10, 20, 50, 100, 150, 200, 300, 400, 500,  700];
  static const _endsGma   = [100, 200, 500, 800, 1200, 1600, 2000, 2500, 3500, 5000];
  static const _countsGma = [8,  10, 12, 14,  14,  15,  15,  18,  18,   20];
  static const _timersGma = [15, 13, 11, 10,   9,   8,   8,   7,   7,    6];
  static const _xpsGma    = [40, 52, 65, 78,  92, 108, 125, 145, 165,  180];

  static ChallengeLevel _beginner(int l, int t, bool hard) => ChallengeLevel(
      mode: ChallengeMode.beginner,
      level: l,
      rangeStart: _startsBeg[t],
      rangeEnd: _endsBeg[t],
      questionCount: _countsBeg[t],
      timeLimitSeconds: _timersBeg[t],
      xpReward: _xpsBeg[t],
      useRandomKeyboard: hard);

  static ChallengeLevel _explorer(int l, int t, bool hard) => ChallengeLevel(
      mode: ChallengeMode.explorer,
      level: l,
      rangeStart: _startsExp[t],
      rangeEnd: _endsExp[t],
      questionCount: _countsExp[t],
      timeLimitSeconds: _timersExp[t],
      xpReward: _xpsExp[t],
      useRandomKeyboard: hard);

  static ChallengeLevel _challenger(int l, int t, bool hard) => ChallengeLevel(
      mode: ChallengeMode.challenger,
      level: l,
      rangeStart: _startsCha[t],
      rangeEnd: _endsCha[t],
      questionCount: _countsCha[t],
      timeLimitSeconds: _timersCha[t],
      xpReward: _xpsCha[t],
      useRandomKeyboard: hard);

  static ChallengeLevel _master(int l, int t, bool hard) => ChallengeLevel(
      mode: ChallengeMode.master,
      level: l,
      rangeStart: _startsMas[t],
      rangeEnd: _endsMas[t],
      questionCount: _countsMas[t],
      timeLimitSeconds: _timersMas[t],
      xpReward: _xpsMas[t],
      useRandomKeyboard: hard);

  static ChallengeLevel _grandmaster(int l, int t, bool hard) => ChallengeLevel(
      mode: ChallengeMode.grandmaster,
      level: l,
      rangeStart: _startsGma[t],
      rangeEnd: _endsGma[t],
      questionCount: _countsGma[t],
      timeLimitSeconds: _timersGma[t],
      xpReward: _xpsGma[t],
      useRandomKeyboard: hard);
}
