/// Model and configuration for daily streak-based rewards.
class DailyStreakReward {
  final int day;
  final int xp;
  final String title;
  final String description;
  final bool isWeeklyChest;

  const DailyStreakReward({
    required this.day,
    required this.xp,
    required this.title,
    required this.description,
    this.isWeeklyChest = false,
  });

  /// The standard 7-day recurring reward cycle.
  static const List<DailyStreakReward> weeklyCycle = [
    DailyStreakReward(
      day: 1,
      xp: 50,
      title: 'Day 1 Spark',
      description: 'Start your daily streak!',
    ),
    DailyStreakReward(
      day: 2,
      xp: 75,
      title: 'Day 2 Momentum',
      description: 'Building the daily habit.',
    ),
    DailyStreakReward(
      day: 3,
      xp: 100,
      title: 'Day 3 Flame',
      description: 'You\'re on fire!',
    ),
    DailyStreakReward(
      day: 4,
      xp: 125,
      title: 'Day 4 Dedication',
      description: 'Consistency pays off.',
    ),
    DailyStreakReward(
      day: 5,
      xp: 150,
      title: 'Day 5 Power',
      description: 'Unstoppable learning power.',
    ),
    DailyStreakReward(
      day: 6,
      xp: 200,
      title: 'Day 6 Master',
      description: 'One day away from the grand chest!',
    ),
    DailyStreakReward(
      day: 7,
      xp: 350,
      title: 'Day 7 Grand Chest',
      description: 'Weekly champion mega reward!',
      isWeeklyChest: true,
    ),
  ];

  /// Get base XP reward for a given 1-7 day in cycle.
  static int xpForDay(int day) {
    if (day < 1) return weeklyCycle[0].xp;
    final index = (day - 1) % 7;
    return weeklyCycle[index].xp;
  }
}

/// Result returned after attempting to claim a daily streak reward.
class DailyStreakClaimResult {
  final bool alreadyClaimed;
  final int dayInCycle; // 1 to 7
  final int streakDays;
  final int baseXP;
  final int milestoneBonus;
  final String? milestoneName;
  final int totalRewardXP;

  const DailyStreakClaimResult({
    required this.alreadyClaimed,
    this.dayInCycle = 1,
    this.streakDays = 0,
    this.baseXP = 0,
    this.milestoneBonus = 0,
    this.milestoneName,
    this.totalRewardXP = 0,
  });
}
