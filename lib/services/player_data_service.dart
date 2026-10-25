import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_result.dart';
import '../models/daily_quest.dart';
import '../models/daily_streak_reward.dart';
import 'analytics_service.dart';

class PlayerDataService extends ChangeNotifier {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  static final PlayerDataService instance = PlayerDataService._();
  PlayerDataService._();

  // ─── Persistent state ──────────────────────────────────────────────────────
  int totalXP = 0;
  int totalCorrectEver = 0;
  int totalSessionsEver = 0;
  List<SessionResult> recentSessions = []; // up to 20
  Set<String> unlockedAchievements = {};

  // Challenge high score
  int bestChallengeWave = 0;

  // Flag quiz high score (best streak ever)
  int bestFlagStreak = 0;

  // Onboarding
  bool hasSeenOnboarding = false;

  // Settings
  bool sfxOn = true;
  bool musicOn = true;
  int dailyTimeLimitMins = 60;

  // Referral / social
  int totalShares = 0;
  static const _maxReferralShares = 10;

  // Streak persistence (avoids the 20-session cap bug) and daily rewards
  int _persistedStreakDays = 0;
  String _streakUpdatedDate = '';
  String _lastStreakClaimDate = '';
  bool _bonusAwardedToday = false;

  // ─── Daily state (resets when date changes) ────────────────────────────────
  String _todayDate = ''; // YYYY-MM-DD
  int todayRounds = 0;
  int todayXP = 0;
  int todayCorrect = 0;
  bool todayPerfect = false;
  bool todayFlagQuiz = false;
  List<bool> questClaimed = [false, false, false];

  // ─── Computed properties ───────────────────────────────────────────────────
  int get level => levelFromXP(totalXP);
  double get levelProgress => levelProgressFromXP(totalXP);
  int get xpForNextLevel => xpForLevel(level + 1) - totalXP;

  int get streakDays => _persistedStreakDays;
  List<bool> get weekActivity => _computeWeekActivity();

  /// Whether the player has not yet claimed their daily streak reward today.
  bool get canClaimDailyReward {
    final today = _dateKey(DateTime.now());
    return _lastStreakClaimDate != today;
  }

  /// Day in 7-day reward cycle (1 to 7) for the currently active streak.
  int get currentStreakDayInCycle {
    if (_persistedStreakDays <= 0) return 1;
    return ((_persistedStreakDays - 1) % 7) + 1;
  }

  /// Which day in the 7-day cycle the player will claim next.
  int get nextStreakDayToClaim {
    final today = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    if (_lastStreakClaimDate == today) {
      return currentStreakDayInCycle;
    }
    if (_streakUpdatedDate == yesterday || _lastStreakClaimDate == yesterday) {
      return ((_persistedStreakDays) % 7) + 1;
    }
    return 1;
  }

  /// Returns today's quests with current progress filled in.
  List<DailyQuest> get todayQuestsWithProgress {
    _ensureTodayReset();
    final quests = DailyQuest.questsForDate(DateTime.now());
    for (int i = 0; i < quests.length; i++) {
      final q = quests[i];
      q.progress = _progressForQuest(q);
      q.claimed = i < questClaimed.length ? questClaimed[i] : false;
    }
    return quests;
  }

  int _progressForQuest(DailyQuest q) => switch (q.type) {
        QuestType.playRounds => todayRounds,
        QuestType.earnXP => todayXP,
        QuestType.correctAnswers => todayCorrect,
        QuestType.perfectScore => todayPerfect ? 1 : 0,
        QuestType.flagQuiz => todayFlagQuiz ? 1 : 0,
      };

  // ─── Initialisation ────────────────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    totalXP = prefs.getInt('totalXP') ?? 0;
    totalCorrectEver = prefs.getInt('totalCorrect') ?? 0;
    totalSessionsEver = prefs.getInt('totalSessionsEver') ?? 0;
    sfxOn = prefs.getBool('sfxOn') ?? true;
    musicOn = prefs.getBool('musicOn') ?? true;
    dailyTimeLimitMins = prefs.getInt('dailyTimeLimit') ?? 60;

    // Sessions
    final sessionsJson = prefs.getStringList('sessions') ?? [];
    recentSessions = sessionsJson
        .map((s) => SessionResult.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList();

    bestChallengeWave = prefs.getInt('bestChallengeWave') ?? 0;
    bestFlagStreak = prefs.getInt('bestFlagStreak') ?? 0;
    totalShares          = prefs.getInt('totalShares') ?? 0;
    _persistedStreakDays = prefs.getInt('persistedStreakDays') ?? 0;
    _streakUpdatedDate   = prefs.getString('streakUpdatedDate') ?? '';
    _lastStreakClaimDate = prefs.getString('lastStreakClaimDate') ?? '';

    // Achievements
    final achList = prefs.getStringList('achievements') ?? [];
    unlockedAchievements = achList.toSet();

    // Daily state — load saved date first, then check if a new day has started.
    // Only restore daily counters when the date matches; otherwise keep the
    // zeroed values that _ensureTodayReset sets, so stale yesterday data is
    // never shown on the first open of a new day.
    _todayDate = prefs.getString('todayDate') ?? '';
    final isNewDay = _todayDate != _dateKey(DateTime.now());
    _ensureTodayReset(prefs: prefs);

    if (!isNewDay) {
      todayRounds        = prefs.getInt('todayRounds') ?? 0;
      todayXP            = prefs.getInt('todayXP') ?? 0;
      todayCorrect       = prefs.getInt('todayCorrect') ?? 0;
      todayPerfect       = prefs.getBool('todayPerfect') ?? false;
      todayFlagQuiz      = prefs.getBool('todayFlagQuiz') ?? false;
      _bonusAwardedToday = prefs.getBool('bonusAwardedToday') ?? false;
      questClaimed = List.generate(
          3, (i) => prefs.getBool('questClaimed_$i') ?? false);
    }
  }

  // ─── Record a gameplay session ─────────────────────────────────────────────
  Future<void> recordSession(SessionResult result) async {
    _ensureTodayReset();

    final prevLevel = level; // capture before XP update
    final prevAchievements = Set<String>.from(unlockedAchievements);

    totalXP += result.xpEarned;
    totalCorrectEver += result.correct;
    totalSessionsEver++;

    // Keep last 20 sessions
    recentSessions.insert(0, result);
    if (recentSessions.length > 20) recentSessions.removeLast();

    // Persist streak (fixes 20-session cap bug) and award daily login bonus
    _updateStreak();
    final streakBonus = _awardDailyBonus();
    if (streakBonus > 0) {
      totalXP  += streakBonus;
      todayXP  += streakBonus;
    }

    // Today stats
    todayRounds++;
    todayXP += result.xpEarned;
    todayCorrect += result.correct;
    if (result.isPerfect && result.total >= 5) todayPerfect = true;

    // Check achievements
    _checkAchievements(result);

    // Quest auto-complete check (no manual claim needed for UX simplicity)
    // Just persist updated progress; quests are evaluated via todayQuestsWithProgress

    await _save();
    notifyListeners();

    // ── Analytics (fire-and-forget) ──────────────────────────────────────────
    final svc = AnalyticsService.instance;
    svc.logPracticeSession(
      mode: result.mode,
      correct: result.correct,
      wrong: result.wrong,
      total: result.total,
      xpEarned: result.xpEarned,
      isPerfect: result.isPerfect,
    );
    final newLevel = level;
    if (newLevel > prevLevel) svc.logPlayerLevelUp(newLevel, totalXP);
    for (final id in unlockedAchievements.difference(prevAchievements)) {
      svc.logAchievementUnlocked(id);
    }
    svc.updateUserProperties(
      level: newLevel,
      totalXP: totalXP,
      streakDays: streakDays,
    );
  }

  /// Call this when the player finishes a flag quiz session.
  /// [bestStreak] is the highest consecutive-correct run achieved this session.
  /// Returns true if [bestStreak] is a new all-time high.
  Future<bool> recordFlagQuiz({
    required int correct,
    required int total,
    required int xpEarned,
    int bestStreak = 0,
  }) async {
    _ensureTodayReset();
    totalXP += xpEarned;
    totalCorrectEver += correct;
    totalSessionsEver++;
    todayFlagQuiz = true;
    todayXP += xpEarned;
    todayCorrect += correct;

    final isNewRecord = bestStreak > bestFlagStreak;
    if (isNewRecord) bestFlagStreak = bestStreak;

    final result = SessionResult(
      mode: 'Flag Quiz',
      correct: correct,
      wrong: total - correct,
      total: total,
      xpEarned: xpEarned,
      highestStreak: bestStreak,
      date: DateTime.now(),
    );
    recentSessions.insert(0, result);
    if (recentSessions.length > 20) recentSessions.removeLast();

    _updateStreak();
    final streakBonus = _awardDailyBonus();
    if (streakBonus > 0) {
      totalXP  += streakBonus;
      todayXP  += streakBonus;
    }

    final prevLevel = level;
    final prevAchievements = Set<String>.from(unlockedAchievements);

    // Flag streak achievements
    if (bestStreak >= 10) unlockedAchievements.add('flag_expert');
    if (bestStreak >= 25) unlockedAchievements.add('flag_master');
    if (bestStreak >= 50) unlockedAchievements.add('flag_streak_50');
    _checkAchievements(result);

    await _save();
    notifyListeners();

    // ── Analytics ────────────────────────────────────────────────────────────
    final svc = AnalyticsService.instance;
    svc.logFlagQuizEnded(
      correct: correct,
      total: total,
      xpEarned: xpEarned,
      bestStreak: bestStreak,
      isNewRecord: isNewRecord,
    );
    final newLevel = level;
    if (newLevel > prevLevel) svc.logPlayerLevelUp(newLevel, totalXP);
    for (final id in unlockedAchievements.difference(prevAchievements)) {
      svc.logAchievementUnlocked(id);
    }
    svc.updateUserProperties(
      level: newLevel,
      totalXP: totalXP,
      streakDays: streakDays,
    );

    return isNewRecord;
  }

  /// Returns true if this is a new personal best wave.
  Future<bool> recordChallenge({
    required int waveReached,
    required int xpEarned,
    required int correct,
    required int total,
    required int highestStreak,
  }) async {
    _ensureTodayReset();
    final isNewRecord = waveReached > bestChallengeWave;
    if (isNewRecord) bestChallengeWave = waveReached;

    final prevLevel = level;
    final prevAchievements = Set<String>.from(unlockedAchievements);

    totalXP += xpEarned;
    totalCorrectEver += correct;
    totalSessionsEver++;
    todayRounds++;
    todayXP += xpEarned;
    todayCorrect += correct;

    final result = SessionResult(
      mode: 'Challenge Wave $waveReached',
      correct: correct,
      wrong: total - correct,
      total: total,
      xpEarned: xpEarned,
      highestStreak: highestStreak,
      date: DateTime.now(),
    );
    recentSessions.insert(0, result);
    if (recentSessions.length > 20) recentSessions.removeLast();

    _updateStreak();
    final streakBonus = _awardDailyBonus();
    if (streakBonus > 0) {
      totalXP  += streakBonus;
      todayXP  += streakBonus;
    }

    // Challenge achievements
    if (waveReached >= 5)  unlockedAchievements.add('challenge_wave_5');
    if (waveReached >= 10) unlockedAchievements.add('challenge_wave_10');
    if (waveReached >= 15) unlockedAchievements.add('challenge_wave_15');
    if (waveReached >= 20) unlockedAchievements.add('challenge_wave_20');
    _checkAchievements(result);

    await _save();
    notifyListeners();

    // ── Analytics ────────────────────────────────────────────────────────────
    final svc = AnalyticsService.instance;
    svc.logChallengeEnded(
      waveReached: waveReached,
      xpEarned: xpEarned,
      correct: correct,
      total: total,
      highestStreak: highestStreak,
      isNewRecord: isNewRecord,
    );
    final newLevel = level;
    if (newLevel > prevLevel) svc.logPlayerLevelUp(newLevel, totalXP);
    for (final id in unlockedAchievements.difference(prevAchievements)) {
      svc.logAchievementUnlocked(id);
    }
    svc.updateUserProperties(
      level: newLevel,
      totalXP: totalXP,
      streakDays: streakDays,
    );

    return isNewRecord;
  }

  /// Claim the XP reward for a completed quest.
  Future<void> claimQuest(int index) async {
    final quests = todayQuestsWithProgress;
    if (index >= quests.length) return;
    final quest = quests[index];
    if (!quest.completed || questClaimed[index]) return;

    totalXP += quest.xpReward;
    questClaimed[index] = true;

    // Check daily champion achievement
    if (questClaimed.every((c) => c)) {
      unlockedAchievements.add('daily_all');
    }

    await _save();
    notifyListeners();

    // ── Analytics ────────────────────────────────────────────────────────────
    AnalyticsService.instance.logQuestClaimed(
      questIndex: index,
      questType: quest.type.name,
      xpReward: quest.xpReward,
    );
  }

  /// Claim today's daily streak reward.
  Future<DailyStreakClaimResult> claimDailyStreakReward() async {
    _ensureTodayReset();
    final today = _dateKey(DateTime.now());
    final yesterday =
        _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    if (_lastStreakClaimDate == today) {
      return DailyStreakClaimResult(
        alreadyClaimed: true,
        dayInCycle: currentStreakDayInCycle,
        streakDays: _persistedStreakDays,
        totalRewardXP: 0,
      );
    }

    if (_streakUpdatedDate == yesterday || _lastStreakClaimDate == yesterday) {
      _persistedStreakDays++;
    } else if (_streakUpdatedDate == today) {
      // Gameplay session already bumped streak today
      if (_persistedStreakDays <= 0) _persistedStreakDays = 1;
    } else {
      // Streak broken or brand new user
      _persistedStreakDays = 1;
    }

    _lastStreakClaimDate = today;
    _streakUpdatedDate = today;
    _bonusAwardedToday = true;

    final cycleDay = ((_persistedStreakDays - 1) % 7) + 1;
    final baseXP = DailyStreakReward.xpForDay(cycleDay);

    int milestoneBonus = 0;
    String? milestoneName;
    if (_persistedStreakDays == 14) {
      milestoneBonus = 150;
      milestoneName = '14-Day Streak Milestone';
    } else if (_persistedStreakDays == 30) {
      milestoneBonus = 300;
      milestoneName = '30-Day Legend Milestone';
    } else if (_persistedStreakDays == 60) {
      milestoneBonus = 600;
      milestoneName = '60-Day Titan Milestone';
    } else if (_persistedStreakDays == 100) {
      milestoneBonus = 1200;
      milestoneName = '100-Day Centurion Milestone';
    }

    final totalEarned = baseXP + milestoneBonus;
    totalXP += totalEarned;
    todayXP += totalEarned;

    // Streak achievements
    if (_persistedStreakDays >= 3) unlockedAchievements.add('streak_3');
    if (_persistedStreakDays >= 7) unlockedAchievements.add('streak_7');
    if (_persistedStreakDays >= 14) unlockedAchievements.add('streak_14');
    if (_persistedStreakDays >= 30) unlockedAchievements.add('streak_30');
    if (_persistedStreakDays >= 60) unlockedAchievements.add('streak_60');
    if (_persistedStreakDays >= 100) unlockedAchievements.add('streak_100');

    await _save();
    notifyListeners();

    AnalyticsService.instance.updateUserProperties(
      level: level,
      totalXP: totalXP,
      streakDays: _persistedStreakDays,
    );

    return DailyStreakClaimResult(
      alreadyClaimed: false,
      dayInCycle: cycleDay,
      streakDays: _persistedStreakDays,
      baseXP: baseXP,
      milestoneBonus: milestoneBonus,
      milestoneName: milestoneName,
      totalRewardXP: totalEarned,
    );
  }

  /// Grant bonus XP outside a session (e.g. rewarded-ad 2× XP).
  Future<void> addBonusXP(int amount) async {
    if (amount <= 0) return;
    totalXP += amount;
    todayXP += amount;
    await _save();
    notifyListeners();
  }

  // ─── Referral / social ────────────────────────────────────────────────────

  /// Whether the user can still earn XP from sharing.
  bool get canEarnShareXP => totalShares < _maxReferralShares;

  /// How many more rewarded shares remain.
  int get sharesRemaining => (_maxReferralShares - totalShares).clamp(0, _maxReferralShares);

  /// XP that will be awarded for the next share (0 if cap reached).
  int get nextShareXp => totalShares < _maxReferralShares ? _xpForShare(totalShares + 1) : 0;

  /// Call each time the user successfully triggers the share sheet.
  /// Awards tiered XP: +100 for shares 1–3, +150 for 4–7, +200 for 8–10.
  Future<void> recordShare() async {
    totalShares++;
    // Award tiered XP for first N shares
    if (totalShares <= _maxReferralShares) totalXP += _xpForShare(totalShares);
    // Sticker unlocks
    if (totalShares >= 3)  unlockedAchievements.add('ambassador');
    if (totalShares >= 5)  unlockedAchievements.add('influencer');
    if (totalShares >= 10) unlockedAchievements.add('shares_10');
    await _save();
    notifyListeners();
  }

  // ─── Settings ──────────────────────────────────────────────────────────────
  Future<void> saveSfx(bool value) async {
    sfxOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfxOn', value);
    notifyListeners();
  }

  Future<void> saveMusic(bool value) async {
    musicOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicOn', value);
    notifyListeners();
  }

  Future<void> saveDailyTimeLimit(int mins) async {
    dailyTimeLimitMins = mins;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyTimeLimit', mins);
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    hasSeenOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  /// Wipe all progress (used in settings).
  Future<void> resetAll() async {
    totalXP = 0;
    totalCorrectEver = 0;
    totalSessionsEver = 0;
    bestChallengeWave = 0;
    bestFlagStreak = 0;
    totalShares = 0;
    _persistedStreakDays = 0;
    _streakUpdatedDate = '';
    _lastStreakClaimDate = '';
    _bonusAwardedToday = false;
    recentSessions = [];
    unlockedAchievements = {};
    todayRounds = 0;
    todayXP = 0;
    todayCorrect = 0;
    todayPerfect = false;
    todayFlagQuiz = false;
    questClaimed = [false, false, false];
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  // ─── Level formula ─────────────────────────────────────────────────────────
  /// XP required to reach level [n]. T(1)=0, T(2)=100, T(3)=250, T(4)=450 …
  static int xpForLevel(int n) => n <= 1 ? 0 : (n - 1) * (50 + 25 * n);

  /// Level corresponding to [xp].
  static int levelFromXP(int xp) {
    int n = 1;
    while (xpForLevel(n + 1) <= xp) {
      n++;
    }
    return n;
  }

  /// Progress within the current level as a fraction 0.0–1.0.
  static double levelProgressFromXP(int xp) {
    final n = levelFromXP(xp);
    final current = xpForLevel(n);
    final next = xpForLevel(n + 1);
    return (xp - current) / (next - current);
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  void _ensureTodayReset({SharedPreferences? prefs}) {
    final today = _dateKey(DateTime.now());
    if (_todayDate != today) {
      _todayDate = today;
      todayRounds = 0;
      todayXP = 0;
      todayCorrect = 0;
      todayPerfect = false;
      todayFlagQuiz = false;
      _bonusAwardedToday = false;
      questClaimed = [false, false, false];
    }
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _computeStreak() {
    if (recentSessions.isEmpty) return 0;
    final today = DateTime.now();
    final playedDays = recentSessions
        .map((s) => _dateKey(s.date))
        .toSet();

    int streak = 0;
    var check = today;
    while (playedDays.contains(_dateKey(check))) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<bool> _computeWeekActivity() {
    final playedDays = recentSessions.map((s) => _dateKey(s.date)).toSet();
    final today = DateTime.now();
    // Mon → Sun of current week
    final weekday = today.weekday; // 1=Mon, 7=Sun
    final monday = today.subtract(Duration(days: weekday - 1));
    return List.generate(
        7, (i) => playedDays.contains(_dateKey(monday.add(Duration(days: i)))));
  }

  // Tiered XP per share: 100 for 1-3, 150 for 4-7, 200 for 8-10.
  int _xpForShare(int n) {
    if (n <= 3) return 100;
    if (n <= 7) return 150;
    return 200;
  }

  // Persists the streak day count independently of recentSessions length.
  void _updateStreak() {
    final today     = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    if (_streakUpdatedDate == today) return;
    if (_streakUpdatedDate.isEmpty) {
      // First-ever call: bootstrap from legacy recentSessions data.
      _persistedStreakDays = _computeStreak();
    } else if (_streakUpdatedDate == yesterday || _lastStreakClaimDate == yesterday) {
      _persistedStreakDays++;
    } else {
      // Streak broken — reset to 1 for today.
      _persistedStreakDays = 1;
    }
    _streakUpdatedDate = today;
  }

  // XP bonus for maintaining a streak, awarded once per day.
  int _dailyStreakBonus() {
    if (_persistedStreakDays >= 30) return 150;
    if (_persistedStreakDays >= 14) return 75;
    if (_persistedStreakDays >= 7)  return 50;
    if (_persistedStreakDays >= 3)  return 25;
    return 0;
  }

  // Awards the daily streak bonus once per day; subsequent calls return 0.
  int _awardDailyBonus() {
    if (_bonusAwardedToday) return 0;
    final today = _dateKey(DateTime.now());
    if (_lastStreakClaimDate == today) return 0;
    final bonus = _dailyStreakBonus();
    if (bonus > 0) _bonusAwardedToday = true;
    return bonus;
  }

  void _checkAchievements(SessionResult result) {
    // First win
    if (recentSessions.isNotEmpty) {
      unlockedAchievements.add('first_win');
    }
    // Perfect score (10+ questions)
    if (result.isPerfect && result.total >= 10) {
      unlockedAchievements.add('perfect_score');
    }
    // Century / Millennium correct answers
    if (totalCorrectEver >= 100) unlockedAchievements.add('century');
    if (totalCorrectEver >= 1000) unlockedAchievements.add('millennium');
    // Streak achievements
    final streak = _persistedStreakDays;
    if (streak >= 3) unlockedAchievements.add('streak_3');
    if (streak >= 7) unlockedAchievements.add('streak_7');
    if (streak >= 30) unlockedAchievements.add('streak_30');
    // Level achievements
    final lv = levelFromXP(totalXP);
    if (lv >= 5) unlockedAchievements.add('level_5');
    if (lv >= 10) unlockedAchievements.add('level_10');
    if (lv >= 20) unlockedAchievements.add('level_20');
    // Combos (longest correct run in one session)
    if (result.highestStreak >= 5)  unlockedAchievements.add('combo_5');
    if (result.highestStreak >= 10) unlockedAchievements.add('combo_10');
    if (result.highestStreak >= 25) unlockedAchievements.add('combo_25');
    // XP milestones
    if (totalXP >= 1000) unlockedAchievements.add('xp_1000');
    if (totalXP >= 5000) unlockedAchievements.add('xp_5000');
    if (totalXP >= 10000) unlockedAchievements.add('xp_10000');
    if (totalXP >= 25000) unlockedAchievements.add('xp_25000');
    if (totalXP >= 50000) unlockedAchievements.add('xp_50000');
    // Session milestones (use lifetime counter, not the 20-entry recent list)
    if (totalSessionsEver >= 10)  unlockedAchievements.add('sessions_10');
    if (totalSessionsEver >= 50)  unlockedAchievements.add('sessions_50');
    if (totalSessionsEver >= 100) unlockedAchievements.add('sessions_100');
    if (totalSessionsEver >= 200) unlockedAchievements.add('sessions_200');
    if (totalSessionsEver >= 500) unlockedAchievements.add('sessions_500');
    // Correct-answer extras
    if (totalCorrectEver >= 250)   unlockedAchievements.add('two_fifty');
    if (totalCorrectEver >= 2500)  unlockedAchievements.add('correct_2500');
    if (totalCorrectEver >= 5000)  unlockedAchievements.add('five_thousand');
    if (totalCorrectEver >= 10000) unlockedAchievements.add('ten_thousand');
    // High player levels
    final lv2 = levelFromXP(totalXP);
    if (lv2 >= 30) unlockedAchievements.add('legend');
    if (lv2 >= 40) unlockedAchievements.add('level_40');
    if (lv2 >= 50) unlockedAchievements.add('immortal');
    // Extended streaks
    if (streak >= 14)  unlockedAchievements.add('streak_14');
    if (streak >= 60)  unlockedAchievements.add('streak_60');
    if (streak >= 100) unlockedAchievements.add('streak_100');
  }

  /// Check level-based achievements — call from LevelService after recording.
  void checkLevelAchievements({
    required int beginnerHighest,
    required int explorerHighest,
    required int grandmasterHighest,
    required int totalStars,
  }) {
    if (beginnerHighest >= 25) unlockedAchievements.add('beginner_25');
    if (explorerHighest >= 25) unlockedAchievements.add('explorer_25');
    if (grandmasterHighest >= 1) unlockedAchievements.add('grandmaster_1');
    if (totalStars >= 500) unlockedAchievements.add('all_stars');
    _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', hasSeenOnboarding);
    await prefs.setInt('totalXP', totalXP);
    await prefs.setInt('totalCorrect', totalCorrectEver);
    await prefs.setInt('totalSessionsEver', totalSessionsEver);
    await prefs.setInt('bestChallengeWave', bestChallengeWave);
    await prefs.setInt('bestFlagStreak', bestFlagStreak);
    await prefs.setInt('totalShares', totalShares);
    await prefs.setInt('persistedStreakDays', _persistedStreakDays);
    await prefs.setString('streakUpdatedDate', _streakUpdatedDate);
    await prefs.setString('lastStreakClaimDate', _lastStreakClaimDate);
    await prefs.setBool('sfxOn', sfxOn);
    await prefs.setBool('musicOn', musicOn);
    await prefs.setInt('dailyTimeLimit', dailyTimeLimitMins);

    // Sessions
    final sessionsJson =
        recentSessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('sessions', sessionsJson);

    // Achievements
    await prefs.setStringList(
        'achievements', unlockedAchievements.toList());

    // Daily
    await prefs.setString('todayDate', _todayDate);
    await prefs.setInt('todayRounds', todayRounds);
    await prefs.setInt('todayXP', todayXP);
    await prefs.setInt('todayCorrect', todayCorrect);
    await prefs.setBool('todayPerfect', todayPerfect);
    await prefs.setBool('todayFlagQuiz', todayFlagQuiz);
    await prefs.setBool('bonusAwardedToday', _bonusAwardedToday);
    for (int i = 0; i < 3; i++) {
      await prefs.setBool('questClaimed_$i', questClaimed[i]);
    }
  }
}
