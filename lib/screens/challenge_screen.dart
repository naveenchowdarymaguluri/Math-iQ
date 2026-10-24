import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/quiz_question.dart';
import '../services/analytics_service.dart';
import '../services/sound_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/dotted_background.dart';
import '../widgets/math_progress_bar.dart';
import 'challenge_results_screen.dart';

const int _kQuestionsPerWave = 5;
const int _kMaxLives = 3;

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  int _lives = _kMaxLives;
  int _wave = 1;
  int _qInWave = 0;
  int _xpEarned = 0;
  int _totalCorrect = 0;
  int _totalQuestions = 0;
  int _currentStreak = 0;
  int _highestStreak = 0;

  List<QuizQuestion> _waveQuestions = [];
  int? _selectedIndex;
  bool _answered = false;
  int _timeLeft = 15;
  Timer? _timer;
  bool _showWaveComplete = false;
  bool _lifeLostFlash = false;

  @override
  void initState() {
    super.initState();
    _loadWave(1);
  }

  void _loadWave(int wave) {
    _timer?.cancel();
    setState(() {
      _wave = wave;
      _qInWave = 0;
      _selectedIndex = null;
      _answered = false;
      _showWaveComplete = false;
      _waveQuestions = QuizQuestion.generateMixed(
        difficulty: _diffForWave(wave),
        operations: _opsForWave(wave),
        rangeStart: 1,
        rangeEnd: _rangeForWave(wave),
        count: _kQuestionsPerWave,
      );
    });
    _startTimer();
  }

  List<Operation> _opsForWave(int w) {
    if (w <= 2) return [Operation.addition, Operation.subtraction];
    if (w <= 4) {
      return [
        Operation.addition,
        Operation.subtraction,
        Operation.multiplication,
      ];
    }
    if (w <= 6) {
      return [
        Operation.addition,
        Operation.subtraction,
        Operation.multiplication,
        Operation.division,
      ];
    }
    return Operation.values;
  }

  int _rangeForWave(int w) {
    if (w <= 2) return 20;
    if (w <= 4) return 50;
    if (w <= 6) return 99;
    return 200;
  }

  Difficulty _diffForWave(int w) {
    if (w <= 2) return Difficulty.easy;
    if (w <= 5) return Difficulty.medium;
    return Difficulty.hard;
  }

  int _secsForWave(int w) {
    if (w <= 2) return 15;
    if (w <= 4) return 12;
    if (w <= 6) return 10;
    return 8;
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _secsForWave(_wave);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          if (_timeLeft <= 5 && _timeLeft > 0) {
            SoundService.instance.play(SoundType.tick);
          }
        } else {
          t.cancel();
          _timeUp();
        }
      });
    });
  }

  void _timeUp() {
    _timer?.cancel();
    setState(() {
      _answered = true;
      _selectedIndex = null;
      _totalQuestions++;
      _lives--;
      _currentStreak = 0;
      _xpEarned = max(0, _xpEarned - 1);
    });
    SoundService.instance.play(SoundType.wrong);
    HapticFeedback.heavyImpact();
    _flashLifeLost();
    Future.delayed(const Duration(milliseconds: 1000), _advance);
  }

  void _selectAnswer(int idx) {
    if (_answered) return;
    _timer?.cancel();

    final q = _waveQuestions[_qInWave];
    final isCorrect = q.options[idx] == q.correctAnswer;

    setState(() {
      _selectedIndex = idx;
      _answered = true;
      _totalQuestions++;
    });

    if (isCorrect) {
      _totalCorrect++;
      _currentStreak++;
      if (_currentStreak > _highestStreak) _highestStreak = _currentStreak;
      _xpEarned += 15;
      if (_currentStreak % 3 == 0) _xpEarned += 10; // streak bonus
      SoundService.instance.play(SoundType.correct);
      HapticFeedback.lightImpact();
    } else {
      _lives--;
      _currentStreak = 0;
      _xpEarned = max(0, _xpEarned - 1);
      AnalyticsService.instance.logWrongAnswer(
        mode: 'challenge',
        difficulty: _diffForWave(_wave).name,
        operation: _waveQuestions[_qInWave].operation.name,
      );
      SoundService.instance.play(SoundType.wrong);
      HapticFeedback.heavyImpact();
      _flashLifeLost();
    }

    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  void _flashLifeLost() {
    setState(() => _lifeLostFlash = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _lifeLostFlash = false);
    });
  }

  void _advance() {
    if (!mounted) return;
    if (_lives <= 0) {
      _endGame();
      return;
    }
    if (_qInWave + 1 >= _kQuestionsPerWave) {
      setState(() => _showWaveComplete = true);
      SoundService.instance.play(SoundType.levelUp);
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) _loadWave(_wave + 1);
      });
    } else {
      setState(() {
        _qInWave++;
        _selectedIndex = null;
        _answered = false;
      });
      _startTimer();
    }
  }

  void _endGame() {
    _timer?.cancel();
    SoundService.instance.play(SoundType.gameOver);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeResultsScreen(
          waveReached: _wave,
          xpEarned: _xpEarned,
          correct: _totalCorrect,
          total: _totalQuestions,
          highestStreak: _highestStreak,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_waveQuestions.isEmpty) return const Scaffold();

    final q = _waveQuestions[_qInWave];
    final timerFrac = _timeLeft / _secsForWave(_wave);

    return Scaffold(
      bottomNavigationBar: const SafeArea(
        child: AdBanner(placement: 'challengeBanner'),
      ),
      body: DottedBackground(
        child: Stack(
          children: [
            if (_lifeLostFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: AppColors.mathRed.withValues(alpha: 0.20),
                  ),
                ),
              ),
            Column(
              children: [
                _AppBar(
                  lives: _lives,
                  wave: _wave,
                  xpEarned: _xpEarned,
                ),
                Expanded(
                  child: _showWaveComplete
                      ? _WaveCompleteView(wave: _wave)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            children: [
                              MathProgressBar(
                                value: timerFrac,
                                fillColor: _timeLeft <= 5
                                    ? AppColors.mathRed
                                    : AppColors.mintGreen,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer_rounded,
                                        color: _timeLeft <= 5
                                            ? AppColors.mathRed
                                            : AppColors.mintGreen,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_timeLeft s',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: _timeLeft <= 5
                                              ? AppColors.mathRed
                                              : AppColors.mintGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Q ${_qInWave + 1}/$_kQuestionsPerWave',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              if (_currentStreak >= 3) ...[
                                const SizedBox(height: 8),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.softOrange,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '🔥 $_currentStreak in a row!',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              _ProblemCard(question: q),
                              const SizedBox(height: 20),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 2.2,
                                ),
                                itemCount: q.options.length,
                                itemBuilder: (context, i) {
                                  return _AnswerButton(
                                    value: q.options[i],
                                    isCorrect: q.options[i] == q.correctAnswer,
                                    isSelected: _selectedIndex == i,
                                    isAnswered: _answered,
                                    onTap: () => _selectAnswer(i),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App bar with lives ───────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final int lives;
  final int wave;
  final int xpEarned;

  const _AppBar({
    required this.lives,
    required this.wave,
    required this.xpEarned,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(
                color: AppColors.surfaceContainerHighest, width: 4),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.mathRed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'WAVE $wave',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+$xpEarned XP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              children: List.generate(
                _kMaxLives,
                (i) => Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    i < lives
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: i < lives
                        ? AppColors.mathRed
                        : AppColors.outlineVariant,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wave-complete overlay ────────────────────────────────────────────────────
class _WaveCompleteView extends StatelessWidget {
  final int wave;
  const _WaveCompleteView({required this.wave});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.mintGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF247A33),
                  offset: Offset(0, 8),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 56),
          ),
          const SizedBox(height: 24),
          Text(
            'Wave $wave\nComplete!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Get ready for Wave ${wave + 1}...',
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Problem card (mirrors GameplayScreen) ────────────────────────────────────
class _ProblemCard extends StatelessWidget {
  final QuizQuestion question;
  const _ProblemCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryFixed, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryFixed,
            offset: Offset(0, 8),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'CHOOSE THE CORRECT ANSWER',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.inkPurple,
              ),
              children: [
                TextSpan(
                  text: question.questionText.replaceAll('?', ''),
                ),
                const TextSpan(
                  text: '?',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Answer button (mirrors GameplayScreen) ───────────────────────────────────
class _AnswerButton extends StatefulWidget {
  final int value;
  final bool isCorrect;
  final bool isSelected;
  final bool isAnswered;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.value,
    required this.isCorrect,
    required this.isSelected,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton> {
  bool _pressed = false;

  Color get _bg {
    if (widget.isAnswered && widget.isCorrect) return AppColors.mintGreen;
    if (widget.isAnswered && widget.isSelected && !widget.isCorrect) {
      return AppColors.errorContainer;
    }
    return AppColors.secondaryContainer;
  }

  Color get _border {
    if (widget.isAnswered && widget.isCorrect) return const Color(0xFF247A33);
    if (widget.isAnswered && widget.isSelected && !widget.isCorrect) {
      return AppColors.error;
    }
    return AppColors.secondary;
  }

  Color get _shadow {
    if (widget.isAnswered && widget.isCorrect) return const Color(0xFF1E5C28);
    if (widget.isAnswered && widget.isSelected && !widget.isCorrect) {
      return AppColors.error;
    }
    return AppColors.secondary;
  }

  Color get _textColor {
    if (widget.isAnswered && widget.isCorrect) return Colors.white;
    if (widget.isAnswered && widget.isSelected && !widget.isCorrect) {
      return AppColors.error;
    }
    return AppColors.onSecondaryContainer;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.isAnswered ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isAnswered
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel:
          widget.isAnswered ? null : () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: _pressed
            ? Matrix4.translationValues(0, 6, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 2),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: _shadow,
                    offset: const Offset(0, 6),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: Text(
            '${widget.value}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
        ),
      ),
    );
  }
}
