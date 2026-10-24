import 'dart:math';

enum QuestType { playRounds, earnXP, correctAnswers, perfectScore, flagQuiz }

enum QuestStatus { locked, inProgress, completed }

class DailyQuest {
  final String id;
  final QuestType type;
  final String title;
  final String subtitle;
  final int xpReward;
  final int target; // 1 for boolean quests (perfectScore, flagQuiz)
  final String iconName;
  final int colorValue;

  // Mutable state (set by PlayerDataService)
  int progress;
  bool claimed;

  DailyQuest({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.xpReward,
    required this.target,
    required this.iconName,
    required this.colorValue,
    this.progress = 0,
    this.claimed = false,
  });

  bool get completed => progress >= target;

  double get fraction =>
      target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  QuestStatus get status {
    if (claimed || completed) return QuestStatus.completed;
    if (progress > 0) return QuestStatus.inProgress;
    return QuestStatus.locked;
  }

  // ──────────────────────────────────────────────────────────────
  // Date-seeded generation
  // ──────────────────────────────────────────────────────────────

  /// Pool of all possible quest templates.
  static List<DailyQuest> _pool() => [
        DailyQuest(
          id: 'play5',
          type: QuestType.playRounds,
          title: 'Play 5 Rounds',
          subtitle: 'Complete 5 practice sessions today.',
          xpReward: 50,
          target: 5,
          iconName: 'star',
          colorValue: 0xFF6BCB77,
        ),
        DailyQuest(
          id: 'play10',
          type: QuestType.playRounds,
          title: 'Play 10 Rounds',
          subtitle: 'Complete 10 practice sessions today.',
          xpReward: 100,
          target: 10,
          iconName: 'star',
          colorValue: 0xFF6BCB77,
        ),
        DailyQuest(
          id: 'xp100',
          type: QuestType.earnXP,
          title: 'Earn 100 XP',
          subtitle: 'Accumulate 100 XP in today\'s sessions.',
          xpReward: 60,
          target: 100,
          iconName: 'bolt',
          colorValue: 0xFF005DA7,
        ),
        DailyQuest(
          id: 'xp200',
          type: QuestType.earnXP,
          title: 'Earn 200 XP',
          subtitle: 'Accumulate 200 XP in today\'s sessions.',
          xpReward: 120,
          target: 200,
          iconName: 'bolt',
          colorValue: 0xFF005DA7,
        ),
        DailyQuest(
          id: 'correct30',
          type: QuestType.correctAnswers,
          title: 'Answer 30 Correctly',
          subtitle: 'Get 30 correct answers across all sessions.',
          xpReward: 80,
          target: 30,
          iconName: 'check',
          colorValue: 0xFF2EC4B6,
        ),
        DailyQuest(
          id: 'correct50',
          type: QuestType.correctAnswers,
          title: 'Answer 50 Correctly',
          subtitle: 'Get 50 correct answers across all sessions.',
          xpReward: 150,
          target: 50,
          iconName: 'check',
          colorValue: 0xFF2EC4B6,
        ),
        DailyQuest(
          id: 'perfect',
          type: QuestType.perfectScore,
          title: 'Perfect Session',
          subtitle: 'Get 100% accuracy in any single session.',
          xpReward: 100,
          target: 1,
          iconName: 'star',
          colorValue: 0xFFFFD93D,
        ),
        DailyQuest(
          id: 'flag',
          type: QuestType.flagQuiz,
          title: 'Globe Trotter',
          subtitle: 'Complete the Flag Quiz once today.',
          xpReward: 75,
          target: 1,
          iconName: 'flag',
          colorValue: 0xFFFF9248,
        ),
      ];

  /// Generate the 3 quests for a given [date], using date as RNG seed so the
  /// same 3 quests are shown all day.
  static List<DailyQuest> questsForDate(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final rng = Random(seed);
    final pool = _pool()..shuffle(rng);
    final selected = <DailyQuest>[];
    final usedTypes = <QuestType>{};
    for (final q in pool) {
      if (usedTypes.add(q.type)) {
        selected.add(q);
        if (selected.length == 3) break;
      }
    }
    return selected;
  }
}
