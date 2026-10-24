import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge_level.dart';

class LevelProgress {
  final int stars; // 0–3
  final int bestCorrect;

  const LevelProgress({required this.stars, required this.bestCorrect});
}

class LevelService extends ChangeNotifier {
  static final instance = LevelService._();
  LevelService._();

  final Map<String, LevelProgress> _progress = {};

  static String _key(ChallengeMode mode, int level) =>
      'lvl_${mode.name}_$level';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _progress.clear();
    for (final mode in ChallengeMode.values) {
      for (int level = 1; level <= 100; level++) {
        final k = _key(mode, level);
        final stars = prefs.getInt('${k}_s') ?? 0;
        final best = prefs.getInt('${k}_b') ?? 0;
        if (stars > 0 || best > 0) {
          _progress[k] = LevelProgress(stars: stars, bestCorrect: best);
        }
      }
    }
  }

  LevelProgress? progressFor(ChallengeMode mode, int level) =>
      _progress[_key(mode, level)];

  int starsFor(ChallengeMode mode, int level) =>
      _progress[_key(mode, level)]?.stars ?? 0;

  bool isUnlocked(ChallengeMode mode, int level) {
    if (level <= 1) return true;
    return starsFor(mode, level - 1) > 0;
  }

  int totalStarsFor(ChallengeMode mode) {
    int total = 0;
    for (int i = 1; i <= 100; i++) {
      total += starsFor(mode, i);
    }
    return total;
  }

  /// The first level that hasn't been fully completed (stars < 3).
  /// If all 100 are done, returns 100.
  int currentLevelFor(ChallengeMode mode) {
    for (int i = 1; i <= 100; i++) {
      if (starsFor(mode, i) < 3) return i;
    }
    return 100;
  }

  /// Highest level the player has unlocked (played at least once).
  int highestPlayedFor(ChallengeMode mode) {
    for (int i = 100; i >= 1; i--) {
      if (starsFor(mode, i) > 0) return i;
    }
    return 0;
  }

  int get grandTotalStars {
    int t = 0;
    for (final m in ChallengeMode.values) {
      t += totalStarsFor(m);
    }
    return t;
  }

  Future<void> recordResult({
    required ChallengeMode mode,
    required int level,
    required int correct,
    required int total,
  }) async {
    final cfg = ChallengeLevel.forMode(mode, level);
    final newStars = cfg.starsForScore(correct, total);
    final k = _key(mode, level);
    final existing = _progress[k];
    final bestStars =
        newStars > (existing?.stars ?? 0) ? newStars : (existing?.stars ?? 0);
    final bestCorrect = correct > (existing?.bestCorrect ?? 0)
        ? correct
        : (existing?.bestCorrect ?? 0);
    _progress[k] = LevelProgress(stars: bestStars, bestCorrect: bestCorrect);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${k}_s', bestStars);
    await prefs.setInt('${k}_b', bestCorrect);
    notifyListeners();
  }

  Future<void> resetAll() async {
    _progress.clear();
    final prefs = await SharedPreferences.getInstance();
    for (final mode in ChallengeMode.values) {
      for (int level = 1; level <= 100; level++) {
        final k = _key(mode, level);
        await prefs.remove('${k}_s');
        await prefs.remove('${k}_b');
      }
    }
    notifyListeners();
  }
}
