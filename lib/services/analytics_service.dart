import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Central analytics + crash-reporting facade for Math IQ.
///
/// All public methods are **void / fire-and-forget** — they never throw,
/// so an analytics failure can never break gameplay.
class AnalyticsService {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  FirebaseAnalytics get _fa => FirebaseAnalytics.instance;
  FirebaseCrashlytics get _fc => FirebaseCrashlytics.instance;

  /// Attach to [MaterialApp.navigatorObservers] for automatic screen tracking.
  NavigatorObserver get observer => Firebase.apps.isNotEmpty
      ? FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)
      : NavigatorObserver();

  // ─── Internal safe runner ──────────────────────────────────────────────────
  void _run(Future<void> Function() fn) {
    try {
      if (Firebase.apps.isEmpty) return;
      fn().catchError((_) {}); // fire-and-forget; swallow all errors
    } catch (_) {}
  }

  // ─── XP bucket helper ─────────────────────────────────────────────────────
  static String _xpBucket(int xp) {
    if (xp < 100) return '0-99';
    if (xp < 500) return '100-499';
    if (xp < 1000) return '500-999';
    if (xp < 5000) return '1k-5k';
    if (xp < 10000) return '5k-10k';
    return '10k+';
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  USER PROPERTIES
  // ══════════════════════════════════════════════════════════════════════════

  /// Update Firebase user properties + Crashlytics context after XP/level
  /// changes.  Call after every [PlayerDataService.recordSession] etc.
  void updateUserProperties({
    required int level,
    required int totalXP,
    required int streakDays,
  }) {
    _run(() async {
      await Future.wait([
        _fa.setUserProperty(name: 'player_level', value: '$level'),
        _fa.setUserProperty(name: 'xp_bucket', value: _xpBucket(totalXP)),
        _fa.setUserProperty(name: 'day_streak', value: '$streakDays'),
        _fc.setCustomKey('player_level', level),
        _fc.setCustomKey('total_xp', totalXP),
        _fc.setCustomKey('day_streak', streakDays),
      ]);
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SCREEN VIEWS
  // ══════════════════════════════════════════════════════════════════════════

  /// Log a manual screen view (for screens that don't use named routes).
  void logScreenView(String screenName) =>
      _run(() => _fa.logScreenView(screenName: screenName));

  // ══════════════════════════════════════════════════════════════════════════
  //  SESSION EVENTS
  // ══════════════════════════════════════════════════════════════════════════

  /// Fired when a practice / level-play session ends.
  ///
  /// [mode] — human-readable label e.g. "Practice +" or "Beginner L12".
  void logPracticeSession({
    required String mode,
    required int correct,
    required int wrong,
    required int total,
    required int xpEarned,
    required bool isPerfect,
  }) {
    _run(() => _fa.logEvent(
          name: 'practice_session_completed',
          parameters: {
            'mode': mode,
            'correct': correct,
            'wrong': wrong,
            'total': total,
            'xp_earned': xpEarned,
            'is_perfect': isPerfect ? 1 : 0,
            'accuracy_pct': total > 0 ? (correct * 100 ~/ total) : 0,
          },
        ));
  }

  // ─── Flag Quiz ─────────────────────────────────────────────────────────────

  /// Fired when the player quits a flag-quiz session.
  void logFlagQuizEnded({
    required int correct,
    required int total,
    required int xpEarned,
    required int bestStreak,
    required bool isNewRecord,
  }) {
    _run(() => _fa.logEvent(
          name: 'flag_quiz_ended',
          parameters: {
            'correct': correct,
            'total': total,
            'xp_earned': xpEarned,
            'best_streak': bestStreak,
            'is_new_record': isNewRecord ? 1 : 0,
            'accuracy_pct': total > 0 ? (correct * 100 ~/ total) : 0,
          },
        ));
  }

  // ─── Challenge / Survival ─────────────────────────────────────────────────

  /// Fired when the player runs out of lives in challenge (survival) mode.
  void logChallengeEnded({
    required int waveReached,
    required int xpEarned,
    required int correct,
    required int total,
    required int highestStreak,
    required bool isNewRecord,
  }) {
    _run(() => _fa.logEvent(
          name: 'challenge_ended',
          parameters: {
            'wave_reached': waveReached,
            'xp_earned': xpEarned,
            'correct': correct,
            'total': total,
            'highest_streak': highestStreak,
            'is_new_record': isNewRecord ? 1 : 0,
            'accuracy_pct': total > 0 ? (correct * 100 ~/ total) : 0,
          },
        ));
  }

  // ─── Structured Level Play ────────────────────────────────────────────────

  /// Fired whenever a level in any [ChallengeMode] is completed (pass or fail).
  void logLevelCompleted({
    required String modeName, // 'beginner' / 'explorer' / etc.
    required int levelNumber,
    required int stars, // 0–3
    required int correct,
    required int total,
    required int xpEarned,
  }) {
    _run(() => _fa.logEvent(
          name: 'level_completed',
          parameters: {
            'mode': modeName,
            'level': levelNumber,
            'stars': stars,
            'correct': correct,
            'total': total,
            'xp_earned': xpEarned,
            'accuracy_pct': total > 0 ? (correct * 100 ~/ total) : 0,
            'passed': stars > 0 ? 1 : 0,
          },
        ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PLAYER PROGRESSION
  // ══════════════════════════════════════════════════════════════════════════

  /// Uses Firebase's built-in level-up event for funnel analysis.
  void logPlayerLevelUp(int newLevel, int totalXP) {
    _run(() async {
      await _fa.logLevelUp(character: 'player', level: newLevel);
      // Also set the Crashlytics key immediately.
      await _fc.setCustomKey('player_level', newLevel);
      await _fc.setCustomKey('total_xp', totalXP);
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DAILY QUESTS
  // ══════════════════════════════════════════════════════════════════════════

  void logQuestClaimed({
    required int questIndex,
    required String questType, // e.g. 'playRounds', 'earnXP'
    required int xpReward,
  }) {
    _run(() => _fa.logEvent(
          name: 'quest_claimed',
          parameters: {
            'quest_index': questIndex,
            'quest_type': questType,
            'xp_reward': xpReward,
          },
        ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ACHIEVEMENTS & STICKERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Uses Firebase's standard `unlock_achievement` event for Play Console
  /// integration.
  void logAchievementUnlocked(String achievementId) =>
      _run(() => _fa.logUnlockAchievement(id: achievementId));

  void logStickerUnlocked({
    required String stickerId,
    required String stickerName,
  }) {
    _run(() => _fa.logEvent(
          name: 'sticker_unlocked',
          parameters: {
            'sticker_id': stickerId,
            'sticker_name': stickerName,
          },
        ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ANSWER-LEVEL TRACKING
  // ══════════════════════════════════════════════════════════════════════════

  /// Logged per wrong answer — useful for identifying hard operation/difficulty
  /// combos.
  void logWrongAnswer({
    required String mode,
    required String difficulty, // 'easy' / 'medium' / 'hard' / 'flag'
    required String operation,  // 'addition' / 'subtraction' / … / 'flag_id'
  }) {
    _run(() => _fa.logEvent(
          name: 'wrong_answer',
          parameters: {
            'mode': mode,
            'difficulty': difficulty,
            'operation': operation,
          },
        ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SETTINGS
  // ══════════════════════════════════════════════════════════════════════════

  void logSettingChanged({
    required String settingName, // 'sfx' / 'music' / 'daily_time_limit'
    required String newValue,
  }) {
    _run(() => _fa.logEvent(
          name: 'setting_changed',
          parameters: {
            'setting': settingName,
            'new_value': newValue,
          },
        ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ADS
  // ══════════════════════════════════════════════════════════════════════════

  /// Track ad lifecycle events (impression, click, completion) per placement.
  void logAdEvent({
    required String placement, // e.g. 'levelInterstitial'
    required String event,     // 'shown' / 'clicked' / 'dismissed' / 'completed'
  }) {
    _run(() => _fa.logEvent(
          name: 'ad_event',
          parameters: {
            'placement': placement,
            'event': event,
          },
        ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CRASHLYTICS
  // ══════════════════════════════════════════════════════════════════════════

  /// Record a non-fatal error (ad failures, data errors, etc.).
  void recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    _run(() => _fc.recordError(
          exception,
          stack,
          reason: reason,
          fatal: fatal,
        ));
  }

  /// Set Crashlytics custom keys so crash reports include app context.
  void setCrashlyticsContext({
    required int level,
    required int totalXP,
    required String currentScreen,
  }) {
    _run(() async {
      await Future.wait([
        _fc.setCustomKey('player_level', level),
        _fc.setCustomKey('total_xp', totalXP),
        _fc.setCustomKey('current_screen', currentScreen),
      ]);
    });
  }
}
