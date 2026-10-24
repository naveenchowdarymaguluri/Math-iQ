enum StickerUnlockType {
  always,
  level,
  challengeLevel,
  correctCount,
  streak,
  perfectSession,
  flagQuizDone,
  firstSession,
  shareCount,      // shared the app N times
  totalSessions,   // played N total sessions
  xpMilestone,     // earned N total XP
}

class StickerUnlock {
  final StickerUnlockType type;
  final int value; // milestone value (0 for always/boolean types)
  final String hint; // e.g. "Reach Level 5"

  const StickerUnlock(this.type, this.value, this.hint);
}

class Sticker {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int colorValue;
  final StickerUnlock unlock;

  const Sticker({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.colorValue,
    required this.unlock,
  });

  static const List<Sticker> all = [
    // ── Always / first session ──────────────────────────────────────────────
    Sticker(
      id: 'math_starter',
      name: 'Math Starter',
      description: 'Welcome to Math IQ!',
      emoji: '⭐',
      colorValue: 0xFFFFD93D,
      unlock: StickerUnlock(StickerUnlockType.always, 0, 'Awarded on first launch'),
    ),
    Sticker(
      id: 'first_step',
      name: 'First Step',
      description: 'Complete your first session.',
      emoji: '🎯',
      colorValue: 0xFF6BCB77,
      unlock: StickerUnlock(StickerUnlockType.firstSession, 0, 'Complete any session'),
    ),

    // ── Player level ────────────────────────────────────────────────────────
    Sticker(
      id: 'rising_star',
      name: 'Rising Star',
      description: 'Reach Player Level 3.',
      emoji: '🌟',
      colorValue: 0xFFFF9248,
      unlock: StickerUnlock(StickerUnlockType.level, 3, 'Reach Level 3'),
    ),
    Sticker(
      id: 'apprentice',
      name: 'Apprentice',
      description: 'Reach Player Level 5.',
      emoji: '📚',
      colorValue: 0xFF005DA7,
      unlock: StickerUnlock(StickerUnlockType.level, 5, 'Reach Level 5'),
    ),
    Sticker(
      id: 'math_solver',
      name: 'Math Solver',
      description: 'Reach Player Level 7.',
      emoji: '🧮',
      colorValue: 0xFF2EC4B6,
      unlock: StickerUnlock(StickerUnlockType.level, 7, 'Reach Level 7'),
    ),
    Sticker(
      id: 'math_wizard',
      name: 'Math Wizard',
      description: 'Reach Player Level 10.',
      emoji: '🧙',
      colorValue: 0xFF6A0572,
      unlock: StickerUnlock(StickerUnlockType.level, 10, 'Reach Level 10'),
    ),
    Sticker(
      id: 'math_master',
      name: 'Math Master',
      description: 'Reach Player Level 15.',
      emoji: '👑',
      colorValue: 0xFFE63946,
      unlock: StickerUnlock(StickerUnlockType.level, 15, 'Reach Level 15'),
    ),
    Sticker(
      id: 'grand_wizard',
      name: 'Grand Wizard',
      description: 'Reach Player Level 20.',
      emoji: '🔮',
      colorValue: 0xFF8B5CF6,
      unlock: StickerUnlock(StickerUnlockType.level, 20, 'Reach Level 20'),
    ),

    // ── Challenge levels ─────────────────────────────────────────────────────
    Sticker(
      id: 'chal_rookie',
      name: 'Challenge Rookie',
      description: 'Reach Challenge Level 3.',
      emoji: '🎮',
      colorValue: 0xFF4CC9F0,
      unlock: StickerUnlock(StickerUnlockType.challengeLevel, 3, 'Reach Challenge Level 3'),
    ),
    Sticker(
      id: 'chal_pro',
      name: 'Challenge Pro',
      description: 'Reach Challenge Level 5.',
      emoji: '🏆',
      colorValue: 0xFFFFD700,
      unlock: StickerUnlock(StickerUnlockType.challengeLevel, 5, 'Reach Challenge Level 5'),
    ),
    Sticker(
      id: 'chal_warrior',
      name: 'Challenge Warrior',
      description: 'Reach Challenge Level 10.',
      emoji: '⚔️',
      colorValue: 0xFFFF6B6B,
      unlock: StickerUnlock(StickerUnlockType.challengeLevel, 10, 'Reach Challenge Level 10'),
    ),
    Sticker(
      id: 'chal_legend',
      name: 'Challenge Legend',
      description: 'Reach Challenge Level 15.',
      emoji: '🎖',
      colorValue: 0xFFFF9500,
      unlock: StickerUnlock(StickerUnlockType.challengeLevel, 15, 'Reach Challenge Level 15'),
    ),
    Sticker(
      id: 'chal_master',
      name: 'Challenge Master',
      description: 'Reach Challenge Level 20.',
      emoji: '🌈',
      colorValue: 0xFF10B981,
      unlock: StickerUnlock(StickerUnlockType.challengeLevel, 20, 'Reach Challenge Level 20'),
    ),

    // ── Correct answer milestones ────────────────────────────────────────────
    Sticker(
      id: 'century',
      name: 'Century Club',
      description: '100 correct answers total.',
      emoji: '💯',
      colorValue: 0xFF6BCB77,
      unlock: StickerUnlock(StickerUnlockType.correctCount, 100, '100 correct answers'),
    ),
    Sticker(
      id: 'five_hundred',
      name: 'Answer Machine',
      description: '500 correct answers total.',
      emoji: '🤖',
      colorValue: 0xFF005DA7,
      unlock: StickerUnlock(StickerUnlockType.correctCount, 500, '500 correct answers'),
    ),
    Sticker(
      id: 'millennium',
      name: 'Millennium',
      description: '1 000 correct answers total.',
      emoji: '🏅',
      colorValue: 0xFFFFD700,
      unlock: StickerUnlock(StickerUnlockType.correctCount, 1000, '1000 correct answers'),
    ),

    // ── Streaks ──────────────────────────────────────────────────────────────
    Sticker(
      id: 'streak_3',
      name: 'Hat-Trick',
      description: '3-day daily streak.',
      emoji: '🔥',
      colorValue: 0xFFFF6B6B,
      unlock: StickerUnlock(StickerUnlockType.streak, 3, '3-day streak'),
    ),
    Sticker(
      id: 'streak_7',
      name: 'Hot Streak',
      description: '7-day daily streak.',
      emoji: '🌊',
      colorValue: 0xFF4CC9F0,
      unlock: StickerUnlock(StickerUnlockType.streak, 7, '7-day streak'),
    ),
    Sticker(
      id: 'streak_30',
      name: 'Dedication',
      description: '30-day daily streak.',
      emoji: '💫',
      colorValue: 0xFFFFD700,
      unlock: StickerUnlock(StickerUnlockType.streak, 30, '30-day streak'),
    ),

    // ── Special ──────────────────────────────────────────────────────────────
    Sticker(
      id: 'perfect',
      name: 'Flawless',
      description: 'Get a perfect score in any session.',
      emoji: '💎',
      colorValue: 0xFF4CC9F0,
      unlock: StickerUnlock(StickerUnlockType.perfectSession, 0, 'Perfect session (no wrong)'),
    ),
    Sticker(
      id: 'globe_trotter',
      name: 'Globe Trotter',
      description: 'Complete the Flag Quiz.',
      emoji: '🌍',
      colorValue: 0xFF2EC4B6,
      unlock: StickerUnlock(StickerUnlockType.flagQuizDone, 0, 'Complete the Flag Quiz'),
    ),
    Sticker(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Answer with a speed bonus.',
      emoji: '⚡',
      colorValue: 0xFFFFD93D,
      unlock: StickerUnlock(StickerUnlockType.correctCount, 10, 'Answer 10 questions correctly'),
    ),
    Sticker(
      id: 'ultimate_brain',
      name: 'Ultimate Brain',
      description: 'Reach Player Level 25.',
      emoji: '🧠',
      colorValue: 0xFF8B5CF6,
      unlock: StickerUnlock(StickerUnlockType.level, 25, 'Reach Level 25'),
    ),
    Sticker(
      id: 'math_god',
      name: 'Math God',
      description: 'Reach Challenge Level 25.',
      emoji: '👁',
      colorValue: 0xFF1A1A2E,
      unlock: StickerUnlock(StickerUnlockType.challengeLevel, 25, 'Reach Challenge Level 25'),
    ),

    // ── Higher player levels ─────────────────────────────────────────────────
    Sticker(
      id: 'legend',
      name: 'Legend',
      description: 'Reach Player Level 30.',
      emoji: '🦅',
      colorValue: 0xFF1565C0,
      unlock: StickerUnlock(StickerUnlockType.level, 30, 'Reach Level 30'),
    ),
    Sticker(
      id: 'immortal',
      name: 'Immortal',
      description: 'Reach Player Level 50.',
      emoji: '🌌',
      colorValue: 0xFF0D0D2B,
      unlock: StickerUnlock(StickerUnlockType.level, 50, 'Reach Level 50'),
    ),

    // ── Correct answer milestones ────────────────────────────────────────────
    Sticker(
      id: 'two_fifty',
      name: 'Sharp Mind',
      description: '250 correct answers total.',
      emoji: '🎯',
      colorValue: 0xFF8B5CF6,
      unlock: StickerUnlock(StickerUnlockType.correctCount, 250, '250 correct answers'),
    ),
    Sticker(
      id: 'five_thousand',
      name: 'Calculator',
      description: '5 000 correct answers total.',
      emoji: '🖥️',
      colorValue: 0xFF2EC4B6,
      unlock: StickerUnlock(StickerUnlockType.correctCount, 5000, '5000 correct answers'),
    ),
    Sticker(
      id: 'ten_thousand',
      name: 'God Mode',
      description: '10 000 correct answers total.',
      emoji: '⚗️',
      colorValue: 0xFF6A0572,
      unlock: StickerUnlock(StickerUnlockType.correctCount, 10000, '10000 correct answers'),
    ),

    // ── Streaks ──────────────────────────────────────────────────────────────
    Sticker(
      id: 'streak_14',
      name: 'Two Weeks',
      description: '14-day daily streak.',
      emoji: '🌙',
      colorValue: 0xFF1A237E,
      unlock: StickerUnlock(StickerUnlockType.streak, 14, '14-day streak'),
    ),
    Sticker(
      id: 'streak_60',
      name: 'Iron Will',
      description: '60-day daily streak.',
      emoji: '⚙️',
      colorValue: 0xFF546E7A,
      unlock: StickerUnlock(StickerUnlockType.streak, 60, '60-day streak'),
    ),
    Sticker(
      id: 'streak_100',
      name: 'Centurion',
      description: '100-day daily streak.',
      emoji: '🛡️',
      colorValue: 0xFFB71C1C,
      unlock: StickerUnlock(StickerUnlockType.streak, 100, '100-day streak'),
    ),

    // ── XP milestones ────────────────────────────────────────────────────────
    Sticker(
      id: 'xp_1000',
      name: 'Point Scorer',
      description: 'Earn 1 000 XP total.',
      emoji: '💰',
      colorValue: 0xFFF9A825,
      unlock: StickerUnlock(StickerUnlockType.xpMilestone, 1000, 'Earn 1000 XP'),
    ),
    Sticker(
      id: 'xp_5000',
      name: 'XP Hunter',
      description: 'Earn 5 000 XP total.',
      emoji: '💎',
      colorValue: 0xFF0288D1,
      unlock: StickerUnlock(StickerUnlockType.xpMilestone, 5000, 'Earn 5000 XP'),
    ),
    Sticker(
      id: 'xp_25000',
      name: 'Elite',
      description: 'Earn 25 000 XP total.',
      emoji: '🏆',
      colorValue: 0xFFFF6F00,
      unlock: StickerUnlock(StickerUnlockType.xpMilestone, 25000, 'Earn 25000 XP'),
    ),

    // ── Sessions ─────────────────────────────────────────────────────────────
    Sticker(
      id: 'sessions_10',
      name: 'Regular',
      description: 'Play 10 total sessions.',
      emoji: '📅',
      colorValue: 0xFF00838F,
      unlock: StickerUnlock(StickerUnlockType.totalSessions, 10, 'Play 10 sessions'),
    ),
    Sticker(
      id: 'sessions_50',
      name: 'Dedicated',
      description: 'Play 50 total sessions.',
      emoji: '📖',
      colorValue: 0xFF4527A0,
      unlock: StickerUnlock(StickerUnlockType.totalSessions, 50, 'Play 50 sessions'),
    ),
    Sticker(
      id: 'sessions_200',
      name: 'Veteran',
      description: 'Play 200 total sessions.',
      emoji: '🎓',
      colorValue: 0xFF2E7D32,
      unlock: StickerUnlock(StickerUnlockType.totalSessions, 200, 'Play 200 sessions'),
    ),

    // ── Social / referral ────────────────────────────────────────────────────
    Sticker(
      id: 'ambassador',
      name: 'Ambassador',
      description: 'Share Math IQ with 3 friends.',
      emoji: '📣',
      colorValue: 0xFFE91E63,
      unlock: StickerUnlock(StickerUnlockType.shareCount, 3, 'Share with 3 friends'),
    ),
    Sticker(
      id: 'influencer',
      name: 'Influencer',
      description: 'Share Math IQ 5 times.',
      emoji: '🌟',
      colorValue: 0xFFFF5722,
      unlock: StickerUnlock(StickerUnlockType.shareCount, 5, 'Share 5 times'),
    ),
  ];
}
