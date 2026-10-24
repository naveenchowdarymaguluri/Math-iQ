class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final int colorValue;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.colorValue,
  });

  static const List<Achievement> all = [
    // ── Getting started ──────────────────────────────────────────────────────
    Achievement(
      id: 'first_win',
      title: 'First Win',
      description: 'Complete your very first session.',
      iconEmoji: '🎉',
      colorValue: 0xFF6BCB77,
    ),
    Achievement(
      id: 'perfect_score',
      title: 'Flawless',
      description: 'Get 100% accuracy in a session with 10+ questions.',
      iconEmoji: '💎',
      colorValue: 0xFF4CC9F0,
    ),
    Achievement(
      id: 'daily_all',
      title: 'Daily Champion',
      description: 'Complete all 3 daily quests in one day.',
      iconEmoji: '🏅',
      colorValue: 0xFF6BCB77,
    ),

    // ── Correct answers ──────────────────────────────────────────────────────
    Achievement(
      id: 'century',
      title: 'Century',
      description: 'Answer 100 questions correctly in total.',
      iconEmoji: '💯',
      colorValue: 0xFFFF9248,
    ),
    Achievement(
      id: 'two_fifty',
      title: 'Sharp Mind',
      description: 'Answer 250 questions correctly in total.',
      iconEmoji: '🎯',
      colorValue: 0xFF8B5CF6,
    ),
    Achievement(
      id: 'millennium',
      title: 'Millennium',
      description: 'Answer 1 000 questions correctly in total.',
      iconEmoji: '🏆',
      colorValue: 0xFFFFD700,
    ),
    Achievement(
      id: 'correct_2500',
      title: 'Math Machine',
      description: 'Answer 2 500 questions correctly in total.',
      iconEmoji: '⚙️',
      colorValue: 0xFF546E7A,
    ),
    Achievement(
      id: 'five_thousand',
      title: 'Calculator',
      description: 'Answer 5 000 questions correctly in total.',
      iconEmoji: '🖥️',
      colorValue: 0xFF2EC4B6,
    ),
    Achievement(
      id: 'ten_thousand',
      title: 'God Mode',
      description: 'Answer 10 000 questions correctly in total.',
      iconEmoji: '⚗️',
      colorValue: 0xFF6A0572,
    ),

    // ── Daily streaks ────────────────────────────────────────────────────────
    Achievement(
      id: 'streak_3',
      title: 'Hat-Trick',
      description: 'Play for 3 days in a row.',
      iconEmoji: '🔥',
      colorValue: 0xFFFF6B6B,
    ),
    Achievement(
      id: 'streak_7',
      title: 'On Fire',
      description: 'Keep a 7-day daily streak.',
      iconEmoji: '🔥🔥',
      colorValue: 0xFFE63946,
    ),
    Achievement(
      id: 'streak_14',
      title: 'Two Weeks Strong',
      description: 'Maintain a 14-day streak.',
      iconEmoji: '🌙',
      colorValue: 0xFF1A237E,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Unstoppable',
      description: 'Maintain a 30-day streak.',
      iconEmoji: '🌟',
      colorValue: 0xFFFF9500,
    ),
    Achievement(
      id: 'streak_60',
      title: 'Iron Will',
      description: 'Maintain a 60-day streak.',
      iconEmoji: '⚙️',
      colorValue: 0xFF546E7A,
    ),
    Achievement(
      id: 'streak_100',
      title: 'Centurion',
      description: 'Maintain a 100-day streak.',
      iconEmoji: '🛡️',
      colorValue: 0xFFB71C1C,
    ),

    // ── Player levels ────────────────────────────────────────────────────────
    Achievement(
      id: 'level_5',
      title: 'Rising Star',
      description: 'Reach Level 5.',
      iconEmoji: '⭐',
      colorValue: 0xFF005DA7,
    ),
    Achievement(
      id: 'level_10',
      title: 'Math Wizard',
      description: 'Reach Level 10.',
      iconEmoji: '🧙',
      colorValue: 0xFF6A0572,
    ),
    Achievement(
      id: 'level_20',
      title: 'Grand Master',
      description: 'Reach Level 20.',
      iconEmoji: '👑',
      colorValue: 0xFFFFD700,
    ),
    Achievement(
      id: 'legend',
      title: 'Legend',
      description: 'Reach Level 30.',
      iconEmoji: '🦅',
      colorValue: 0xFF1565C0,
    ),
    Achievement(
      id: 'level_40',
      title: 'Mythic',
      description: 'Reach Level 40.',
      iconEmoji: '🐉',
      colorValue: 0xFF7B1FA2,
    ),
    Achievement(
      id: 'immortal',
      title: 'Immortal',
      description: 'Reach Level 50.',
      iconEmoji: '🌌',
      colorValue: 0xFF0D0D2B,
    ),

    // ── XP milestones ────────────────────────────────────────────────────────
    Achievement(
      id: 'xp_1000',
      title: 'Point Scorer',
      description: 'Earn a total of 1 000 XP.',
      iconEmoji: '🪙',
      colorValue: 0xFFF9A825,
    ),
    Achievement(
      id: 'xp_5000',
      title: 'XP Hunter',
      description: 'Earn a total of 5 000 XP.',
      iconEmoji: '🏹',
      colorValue: 0xFF0288D1,
    ),
    Achievement(
      id: 'xp_10000',
      title: 'XP Legend',
      description: 'Earn a total of 10 000 XP.',
      iconEmoji: '💰',
      colorValue: 0xFFFFD700,
    ),
    Achievement(
      id: 'xp_25000',
      title: 'Elite',
      description: 'Earn a total of 25 000 XP.',
      iconEmoji: '🏆',
      colorValue: 0xFFFF6F00,
    ),
    Achievement(
      id: 'xp_50000',
      title: 'XP Tycoon',
      description: 'Earn a total of 50 000 XP.',
      iconEmoji: '💎',
      colorValue: 0xFF00BCD4,
    ),

    // ── Sessions played ──────────────────────────────────────────────────────
    Achievement(
      id: 'sessions_10',
      title: 'Regular',
      description: 'Play 10 sessions in total.',
      iconEmoji: '📅',
      colorValue: 0xFF00838F,
    ),
    Achievement(
      id: 'sessions_50',
      title: 'Dedicated',
      description: 'Play 50 sessions in total.',
      iconEmoji: '📖',
      colorValue: 0xFF4527A0,
    ),
    Achievement(
      id: 'sessions_100',
      title: 'Committed',
      description: 'Play 100 sessions in total.',
      iconEmoji: '🗓️',
      colorValue: 0xFF00695C,
    ),
    Achievement(
      id: 'sessions_200',
      title: 'Veteran',
      description: 'Play 200 sessions in total.',
      iconEmoji: '🎓',
      colorValue: 0xFF2E7D32,
    ),
    Achievement(
      id: 'sessions_500',
      title: 'Math Addict',
      description: 'Play 500 sessions in total.',
      iconEmoji: '🧠',
      colorValue: 0xFFAD1457,
    ),

    // ── Combos (single session) ──────────────────────────────────────────────
    Achievement(
      id: 'combo_5',
      title: 'Combo King',
      description: 'Answer 5 questions correctly in a row.',
      iconEmoji: '🎯',
      colorValue: 0xFFFF9248,
    ),
    Achievement(
      id: 'combo_10',
      title: 'Combo Master',
      description: 'Answer 10 questions correctly in a row.',
      iconEmoji: '💥',
      colorValue: 0xFFEF6C00,
    ),
    Achievement(
      id: 'combo_25',
      title: 'Combo Legend',
      description: 'Answer 25 questions correctly in a row.',
      iconEmoji: '☄️',
      colorValue: 0xFFD32F2F,
    ),

    // ── Flag quiz ────────────────────────────────────────────────────────────
    Achievement(
      id: 'flag_expert',
      title: 'Globe Trotter',
      description: 'Reach a streak of 10 correct flags in a row.',
      iconEmoji: '🌍',
      colorValue: 0xFF2EC4B6,
    ),
    Achievement(
      id: 'flag_master',
      title: 'Flag Master',
      description: 'Reach a streak of 25 correct flags in a row.',
      iconEmoji: '🌐',
      colorValue: 0xFF2EC4B6,
    ),
    Achievement(
      id: 'flag_streak_50',
      title: 'Flag Immortal',
      description: 'Reach a streak of 50 correct flags in a row.',
      iconEmoji: '🗺️',
      colorValue: 0xFF00897B,
    ),

    // ── Survival challenge ───────────────────────────────────────────────────
    Achievement(
      id: 'challenge_wave_5',
      title: 'Wave Rider',
      description: 'Survive to Wave 5 in Survival Mode.',
      iconEmoji: '🌊',
      colorValue: 0xFF2196F3,
    ),
    Achievement(
      id: 'challenge_wave_10',
      title: 'Unstoppable Wave',
      description: 'Survive to Wave 10 in Survival Mode.',
      iconEmoji: '🌊🌊',
      colorValue: 0xFF0D47A1,
    ),
    Achievement(
      id: 'challenge_wave_15',
      title: 'Tsunami',
      description: 'Survive to Wave 15 in Survival Mode.',
      iconEmoji: '🌪️',
      colorValue: 0xFF01579B,
    ),
    Achievement(
      id: 'challenge_wave_20',
      title: 'Wave Legend',
      description: 'Survive to Wave 20 in Survival Mode.',
      iconEmoji: '🌀',
      colorValue: 0xFF1A237E,
    ),

    // ── Challenge levels ─────────────────────────────────────────────────────
    Achievement(
      id: 'beginner_25',
      title: 'Steady Climber',
      description: 'Complete Level 25 in Beginner mode.',
      iconEmoji: '😊',
      colorValue: 0xFF4CAF50,
    ),
    Achievement(
      id: 'explorer_25',
      title: 'Table Master',
      description: 'Complete Level 25 in Explorer mode.',
      iconEmoji: '🔭',
      colorValue: 0xFF2196F3,
    ),
    Achievement(
      id: 'grandmaster_1',
      title: 'Grandmaster Debut',
      description: 'Play your first Grandmaster level.',
      iconEmoji: '👑',
      colorValue: 0xFFE91E63,
    ),
    Achievement(
      id: 'all_stars',
      title: 'Star Collector',
      description: 'Earn 500 stars across all Challenge Modes.',
      iconEmoji: '⭐',
      colorValue: 0xFFFFD700,
    ),

    // ── Social / referral ────────────────────────────────────────────────────
    Achievement(
      id: 'ambassador',
      title: 'Ambassador',
      description: 'Share Math IQ with 3 friends.',
      iconEmoji: '📣',
      colorValue: 0xFFE91E63,
    ),
    Achievement(
      id: 'influencer',
      title: 'Influencer',
      description: 'Share Math IQ 5 times.',
      iconEmoji: '🌟',
      colorValue: 0xFFFF5722,
    ),
    Achievement(
      id: 'shares_10',
      title: 'Superstar',
      description: 'Share Math IQ 10 times.',
      iconEmoji: '🚀',
      colorValue: 0xFF6200EA,
    ),
  ];
}
