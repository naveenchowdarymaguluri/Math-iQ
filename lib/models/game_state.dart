// Thin façade kept for backward compatibility with ResultsScreen.
// All real state lives in PlayerDataService.
import '../services/player_data_service.dart';

class GameState {
  static GameState get instance => _instance;
  static final _instance = GameState._();
  GameState._();

  final _svc = PlayerDataService.instance;

  int get totalXP => _svc.totalXP;
  int get level => _svc.level;
  double get levelProgress => _svc.levelProgress;
  int get streakDays => _svc.streakDays;
  List<bool> get weekStreak => _svc.weekActivity;

  // Set by GameplayScreen before pushing ResultsScreen
  int lastXpEarned = 0;
  int lastCorrect = 0;
  int lastWrong = 0;
  int lastTotalQuestions = 0;

  double get lastAccuracy =>
      lastTotalQuestions > 0 ? lastCorrect / lastTotalQuestions : 0;
}
