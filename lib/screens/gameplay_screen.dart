import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/quiz_question.dart';
import '../models/session_result.dart';
import '../services/analytics_service.dart';
import '../services/sound_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/dotted_background.dart';
import '../widgets/math_progress_bar.dart';
import '../widgets/tactile_button.dart';
import 'results_screen.dart';

class GameplayScreen extends StatefulWidget {
  // ── Finite mode: pass a pre-generated list (used by level play, etc.) ───────
  final List<QuizQuestion>? questions;

  // ── Unlimited mode: questions generated on-the-fly ──────────────────────────
  final bool isUnlimited;
  final List<Operation> operations; // one or more ops to cycle through
  final Difficulty difficulty;
  final int rangeStart;
  final int rangeEnd;

  // ── Shared ───────────────────────────────────────────────────────────────────
  /// Per-question countdown in seconds. 0 = no timer (relaxed practice mode).
  final int secondsPerQuestion;
  final String mode;

  /// When true the answer grid is replaced by an in-app number keypad.
  /// Ideal for hard mode where MCQ hints make it too easy.
  final bool useNumberKeyboard;

  const GameplayScreen({
    super.key,
    this.questions,
    this.isUnlimited = false,
    this.operations = const [Operation.addition],
    this.difficulty = Difficulty.easy,
    this.rangeStart = 1,
    this.rangeEnd = 99,
    this.secondsPerQuestion = 15,
    this.mode = 'Practice',
    this.useNumberKeyboard = false,
  });

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  // ── Finite mode tracking ────────────────────────────────────────────────────
  int _current = 0;

  // ── Unlimited mode — one question at a time ─────────────────────────────────
  QuizQuestion? _unlimitedQ;

  // ── Session stats ────────────────────────────────────────────────────────────
  int _correct = 0;
  int _wrong = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _timeLeft = 15;
  Timer? _timer;

  int _currentStreak = 0;
  int _highestStreak = 0;

  // ── Number-keyboard mode ─────────────────────────────────────────────────
  String _typedAnswer = '';
  bool? _keyboardWasCorrect; // null = not submitted yet

  // ── Milestone celebration ────────────────────────────────────────────────
  String? _milestoneMsg;

  late AnimationController _bounceCtrl;

  // ── Active question accessor ─────────────────────────────────────────────────
  QuizQuestion get _activeQ =>
      widget.isUnlimited ? _unlimitedQ! : widget.questions![_current];

  // ── Math tips ─────────────────────────────────────────────────────────────────
  static const _tips = {
    Operation.addition: 'Try adding tens first: 20 + 30 = 50, then add ones!',
    Operation.subtraction:
        'Count up from the smaller number to the larger one.',
    Operation.multiplication: 'Think of multiplication as equal groups.',
    Operation.division:
        'How many times does the divisor fit into the number?',
    Operation.modulo: 'Find the remainder after dividing: 17 % 5 is 2 because 15 + 2 = 17!',
    Operation.exponent: 'A square is multiplying the number by itself: 7² = 7 × 7 = 49.',
    Operation.squareRoot: 'Think in reverse: what number multiplied by itself gives this?',
    Operation.percentage: 'For 50% halve it, for 25% divide by 4, for 10% move decimal point!',
    Operation.preAlgebra: 'Isolate the unknown: subtract or divide both sides to solve!',
  };

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.isUnlimited) _unlimitedQ = _generateQuestion();
    _startQuestionTimer();
  }

  // ── Question generator (unlimited mode) ──────────────────────────────────────
  QuizQuestion _generateQuestion() {
    final ops = widget.operations;
    final op = ops[Random().nextInt(ops.length)];
    return QuizQuestion.generate(
      difficulty: widget.difficulty,
      operation: op,
      rangeStart: widget.rangeStart,
      rangeEnd: widget.rangeEnd,
      count: 1,
    ).first;
  }

  // ── Timer ──────────────────────────────────────────────────────────────────
  void _startQuestionTimer() {
    _timer?.cancel();
    _timeLeft = widget.secondsPerQuestion;
    if (widget.secondsPerQuestion == 0) return; // ── no-timer mode
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
      _wrong++;
      _currentStreak = 0;
    });
    SoundService.instance.play(SoundType.wrong);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bounceCtrl.dispose();
    super.dispose();
  }

  // ── Answer selection ────────────────────────────────────────────────────────
  void _selectAnswer(int idx) {
    if (_answered) return;
    _timer?.cancel();

    final q = _activeQ;
    final isCorrect = q.options[idx] == q.correctAnswer;

    setState(() {
      _selectedIndex = idx;
      _answered = true;
    });

    if (isCorrect) {
      _correct++;
      _currentStreak++;
      if (_currentStreak > _highestStreak) _highestStreak = _currentStreak;

      // Practice mode awards no XP
      SoundService.instance.play(SoundType.correct);
      HapticFeedback.lightImpact();
      _checkMilestone();
    } else {
      _wrong++;
      _currentStreak = 0;
      AnalyticsService.instance.logWrongAnswer(
        mode: widget.mode,
        difficulty: widget.difficulty.name,
        operation: q.operation.name,
      );
      SoundService.instance.play(SoundType.wrong);
      HapticFeedback.heavyImpact();
    }

    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  // ── Keyboard-mode answer submission ──────────────────────────────────────────
  void _submitTypedAnswer() {
    if (_answered || _typedAnswer.isEmpty) return;
    _timer?.cancel();

    final q = _activeQ;
    final typed = int.tryParse(_typedAnswer);
    final isCorrect = typed != null && typed == q.correctAnswer;

    setState(() {
      _answered = true;
      _keyboardWasCorrect = isCorrect;
    });

    if (isCorrect) {
      _correct++;
      _currentStreak++;
      if (_currentStreak > _highestStreak) _highestStreak = _currentStreak;
      // Practice mode awards no XP
      SoundService.instance.play(SoundType.correct);
      HapticFeedback.lightImpact();
      _checkMilestone();
    } else {
      _wrong++;
      _currentStreak = 0;
      AnalyticsService.instance.logWrongAnswer(
        mode: widget.mode,
        difficulty: widget.difficulty.name,
        operation: q.operation.name,
      );
      SoundService.instance.play(SoundType.wrong);
      HapticFeedback.heavyImpact();
    }
    Future.delayed(const Duration(milliseconds: 1200), _advance);
  }

  // ── Milestone celebration ─────────────────────────────────────────────────
  void _checkMilestone() {
    if (!widget.isUnlimited) return;
    if (_correct > 0 && _correct % 15 == 0) {
      setState(() => _milestoneMsg = '🎉 $_correct Correct!');
      SoundService.instance.play(SoundType.levelUp);
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _milestoneMsg = null);
      });
    }
  }

  // ── Advance ──────────────────────────────────────────────────────────────────
  void _advance() {
    if (!mounted) return;
    if (widget.isUnlimited) {
      // Generate next question immediately
      setState(() {
        _unlimitedQ = _generateQuestion();
        _selectedIndex = null;
        _answered = false;
        _typedAnswer = '';
        _keyboardWasCorrect = null;
      });
      _startQuestionTimer();
    } else {
      if (_current + 1 < widget.questions!.length) {
        setState(() {
          _current++;
          _selectedIndex = null;
          _answered = false;
          _typedAnswer = '';
          _keyboardWasCorrect = null;
        });
        _startQuestionTimer();
      } else {
        _finishSession();
      }
    }
  }

  // ── Session end ──────────────────────────────────────────────────────────────
  void _finishSession() {
    _timer?.cancel();

    SoundService.instance.play(SoundType.gameOver);

    final total =
        widget.isUnlimited ? _correct + _wrong : widget.questions!.length;

    final result = SessionResult(
      mode: widget.mode,
      correct: _correct,
      wrong: _wrong,
      total: total,
      xpEarned: 0, // practice mode awards no XP
      highestStreak: _highestStreak,
      date: DateTime.now(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
    );
  }

  // ── Close / quit ─────────────────────────────────────────────────────────────
  void _handleClose() {
    if (widget.isUnlimited) {
      _timer?.cancel();
      _showQuitDialog();
    } else {
      Navigator.pop(context);
    }
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PracticeQuitDialog(
        correct: _correct,
        wrong: _wrong,
        highestStreak: _highestStreak,
        onKeepPlaying: () {
          Navigator.pop(ctx);
          if (!_answered) _startQuestionTimer();
        },
        onEnd: () {
          Navigator.pop(ctx);
          _finishSession();
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final q = _activeQ;
    final hasTimer = widget.secondsPerQuestion > 0;
    final timerFraction =
        hasTimer ? _timeLeft / widget.secondsPerQuestion : 1.0;
    final tip = _tips[q.operation] ?? 'Take a breath and calculate!';

    // Finite mode only
    final progress = widget.isUnlimited
        ? null
        : (_current + 1) / widget.questions!.length;

    return Scaffold(
      // ── Banner ad pinned at the very bottom ──────────────────────────────
      bottomNavigationBar: const AdBanner(placement: 'practiceGameplay'),
      body: DottedBackground(
        child: Column(
          children: [
            _AppBar(
              isUnlimited: widget.isUnlimited,
              correct: _correct,
              wrong: _wrong,
              current: _current,
              total: widget.isUnlimited ? null : widget.questions!.length,
              onClose: _handleClose,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  children: [
                    // ── Top score / counter row ────────────────────────────
                    if (!widget.isUnlimited)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CORRECT',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 1),
                              ),
                              Text(
                                '$_correct ✓',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Q ${_current + 1}/${widget.questions!.length}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 1),
                              ),
                              _TimerChip(
                                  timeLeft: _timeLeft,
                                  totalSecs: widget.secondsPerQuestion),
                            ],
                          ),
                        ],
                      ),

                    // Unlimited mode: live ✓/✗ + optional timer
                    if (widget.isUnlimited)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _ScoreChip(
                                  icon: Icons.check_rounded,
                                  value: _correct,
                                  bg: AppColors.mintGreen
                                      .withValues(alpha: 0.15),
                                  border: AppColors.mintGreen,
                                  color: AppColors.mintGreen),
                              const SizedBox(width: 8),
                              _ScoreChip(
                                  icon: Icons.close_rounded,
                                  value: _wrong,
                                  bg: AppColors.mathRed.withValues(alpha: 0.1),
                                  border:
                                      AppColors.mathRed.withValues(alpha: 0.5),
                                  color: AppColors.mathRed),
                            ],
                          ),
                          if (hasTimer)
                            _TimerChip(
                                timeLeft: _timeLeft,
                                totalSecs: widget.secondsPerQuestion),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // Timer bar — hidden in no-timer mode
                    if (hasTimer)
                      MathProgressBar(
                        value: timerFraction,
                        fillColor: _timeLeft <= 5
                            ? AppColors.mathRed
                            : AppColors.mintGreen,
                      ),

                    // Overall progress bar (finite only)
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      MathProgressBar(value: progress),
                    ],

                    // Streak badge
                    if (_currentStreak >= 3) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.softOrange,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '🔥 $_currentStreak in a row!',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── Milestone celebration banner ───────────────────────
                    if (_milestoneMsg != null) ...[
                      AnimatedOpacity(
                        opacity: _milestoneMsg != null ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6BCB77),
                                Color(0xFF2EC4B6)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🎉',
                                  style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Text(
                                _milestoneMsg!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Problem card
                    _ProblemCard(
                        question: q,
                        useKeyboard: widget.useNumberKeyboard),
                    const SizedBox(height: 20),

                    // Answer input — keypad OR MCQ grid
                    if (widget.useNumberKeyboard)
                      _NumberKeypad(
                        typed: _typedAnswer,
                        answered: _answered,
                        wasCorrect: _keyboardWasCorrect,
                        correctAnswer: q.correctAnswer,
                        onDigit: (d) {
                          if (!_answered && _typedAnswer.length < 6) {
                            setState(() => _typedAnswer += d);
                          }
                        },
                        onBackspace: () {
                          if (!_answered && _typedAnswer.isNotEmpty) {
                            setState(() => _typedAnswer = _typedAnswer
                                .substring(0, _typedAnswer.length - 1));
                          }
                        },
                        onSubmit: _submitTypedAnswer,
                      )
                    else
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
                        itemBuilder: (context, i) => _AnswerButton(
                          value: q.options[i],
                          isCorrect: q.options[i] == q.correctAnswer,
                          isSelected: _selectedIndex == i,
                          isAnswered: _answered,
                          onTap: () => _selectAnswer(i),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Math tip card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.creamBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primaryFixed,
                            width: 3,
                            style: BorderStyle.solid),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                    color: AppColors.onPrimaryFixedVariant,
                                    offset: Offset(0, 4),
                                    blurRadius: 0)
                              ],
                            ),
                            child: const Icon(Icons.lightbulb_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MATH TIP',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(tip,
                                    style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable timer chip ──────────────────────────────────────────────────────
class _TimerChip extends StatelessWidget {
  final int timeLeft;
  final int totalSecs;
  const _TimerChip({required this.timeLeft, required this.totalSecs});

  @override
  Widget build(BuildContext context) {
    final isLow = timeLeft <= 5;
    return Row(
      children: [
        Icon(Icons.timer_rounded,
            color: isLow ? AppColors.mathRed : AppColors.mintGreen, size: 20),
        const SizedBox(width: 4),
        Text(
          '$timeLeft s',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isLow ? AppColors.mathRed : AppColors.mintGreen,
          ),
        ),
      ],
    );
  }
}

// ─── Score chip (unlimited mode ✓ / ✗) ───────────────────────────────────────
class _ScoreChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color bg, border, color;
  const _ScoreChip(
      {required this.icon,
      required this.value,
      required this.bg,
      required this.border,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            '$value',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 17, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final bool isUnlimited;
  final int correct;
  final int wrong;
  final int current;
  final int? total; // null = unlimited
  final VoidCallback onClose;

  const _AppBar({
    required this.isUnlimited,
    required this.correct,
    required this.wrong,
    required this.current,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom:
                BorderSide(color: AppColors.surfaceContainerHighest, width: 4),
          ),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.primary),
              onPressed: onClose,
            ),
            Text(
              'Math IQ',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
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
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$correct correct',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Problem card ─────────────────────────────────────────────────────────────
class _ProblemCard extends StatelessWidget {
  final QuizQuestion question;
  final bool useKeyboard;
  const _ProblemCard(
      {required this.question, this.useKeyboard = false});

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
            useKeyboard ? 'TYPE THE ANSWER' : 'CHOOSE THE CORRECT ANSWER',
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
                TextSpan(text: question.questionText.replaceAll('?', '')),
                const TextSpan(
                    text: '?',
                    style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Answer button ────────────────────────────────────────────────────────────
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
                      blurRadius: 0),
                ],
        ),
        child: Center(
          child: Text(
            '${widget.value}',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _textColor),
          ),
        ),
      ),
    );
  }
}

// ─── Unlimited mode quit dialog ───────────────────────────────────────────────
class _PracticeQuitDialog extends StatelessWidget {
  final int correct;
  final int wrong;
  final int highestStreak;
  final VoidCallback onKeepPlaying;
  final VoidCallback onEnd;

  const _PracticeQuitDialog({
    required this.correct,
    required this.wrong,
    required this.highestStreak,
    required this.onKeepPlaying,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final total = correct + wrong;
    final accuracy = total > 0 ? (correct / total * 100).round() : 0;

    return AlertDialog(
      backgroundColor: AppColors.creamBg,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                    color: AppColors.onPrimaryFixedVariant,
                    offset: Offset(0, 4),
                    blurRadius: 0)
              ],
            ),
            child: const Icon(Icons.pause_rounded,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'Session Paused',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary),
          ),
          Text(
            'Keep going or save your progress.',
            style: GoogleFonts.beVietnamPro(
                fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _QStat(
                      label: 'Correct',
                      value: '$correct',
                      color: AppColors.mintGreen)),
              const SizedBox(width: 10),
              Expanded(
                  child: _QStat(
                      label: 'Wrong',
                      value: '$wrong',
                      color: AppColors.mathRed)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _QStat(
                      label: 'Best Streak',
                      value: '$highestStreak',
                      color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                  child: _QStat(
                      label: 'Accuracy',
                      value: '$accuracy%',
                      color: AppColors.softOrange)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TactileButton(
                  color: AppColors.surfaceContainerHigh,
                  shadowColor: AppColors.outlineVariant,
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: onKeepPlaying,
                  child: Text(
                    'Keep Playing',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TactileButton(
                  color: AppColors.primary,
                  shadowColor: AppColors.onPrimaryFixedVariant,
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: onEnd,
                  child: Text(
                    'End Session',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _QStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 11, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─── Number keypad (type-answer mode) ────────────────────────────────────────
class _NumberKeypad extends StatelessWidget {
  final String typed;
  final bool answered;
  final bool? wasCorrect;
  final int correctAnswer;
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  const _NumberKeypad({
    required this.typed,
    required this.answered,
    required this.wasCorrect,
    required this.correctAnswer,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    // Determine display box colour after answer is submitted
    Color boxBg = AppColors.surfaceContainerLowest;
    Color boxBorder = AppColors.primaryFixed;
    if (answered && wasCorrect == true) {
      boxBg = AppColors.mintGreen;
      boxBorder = const Color(0xFF247A33);
    } else if (answered && wasCorrect == false) {
      boxBg = AppColors.errorContainer;
      boxBorder = AppColors.error;
    }

    return Column(
      children: [
        // ── Answer display ─────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: boxBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: boxBorder, width: 2),
            boxShadow: [
              BoxShadow(
                  color: boxBorder.withValues(alpha: 0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 0),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  typed.isEmpty ? '_' : typed,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: typed.isEmpty
                        ? AppColors.onSurfaceVariant
                        : answered && wasCorrect == true
                            ? Colors.white
                            : answered && wasCorrect == false
                                ? AppColors.error
                                : AppColors.onSurface,
                  ),
                ),
                // Show correct answer after wrong submission
                if (answered && wasCorrect == false) ...[
                  const SizedBox(width: 12),
                  Text(
                    '→ $correctAnswer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Numpad (hidden after submission) ──────────────────────────
        if (!answered) ...[
          _row(['7', '8', '9']),
          const SizedBox(height: 8),
          _row(['4', '5', '6']),
          const SizedBox(height: 8),
          _row(['1', '2', '3']),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _KeyBtn(
                  label: '⌫',
                  bg: AppColors.softOrange.withValues(alpha: 0.15),
                  fg: AppColors.softOrange,
                  onTap: onBackspace,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: _KeyBtn(
                      label: '0',
                      onTap: () => onDigit('0'))),
              const SizedBox(width: 8),
              Expanded(
                child: _KeyBtn(
                  label: '✓',
                  bg: typed.isEmpty
                      ? AppColors.surfaceContainerHigh
                      : AppColors.mintGreen,
                  fg: typed.isEmpty
                      ? AppColors.onSurfaceVariant
                      : Colors.white,
                  onTap: typed.isEmpty ? null : onSubmit,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _row(List<String> digits) => Row(
        children: digits.asMap().entries.expand((e) {
          return [
            if (e.key > 0) const SizedBox(width: 8),
            Expanded(
                child:
                    _KeyBtn(label: e.value, onTap: () => onDigit(e.value))),
          ];
        }).toList(),
      );
}

class _KeyBtn extends StatefulWidget {
  final String label;
  final Color? bg;
  final Color? fg;
  final VoidCallback? onTap;
  const _KeyBtn({required this.label, this.bg, this.fg, this.onTap});

  @override
  State<_KeyBtn> createState() => _KeyBtnState();
}

class _KeyBtnState extends State<_KeyBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.bg ?? AppColors.secondaryContainer;
    final fg = widget.fg ?? AppColors.onSecondaryContainer;
    final disabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            },
      onTapCancel:
          disabled ? null : () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: _pressed
            ? Matrix4.translationValues(0, 4, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: bg.withValues(alpha: 0.7), width: 1.5),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                      color: bg.withValues(alpha: 0.5),
                      offset: const Offset(0, 4),
                      blurRadius: 0),
                ],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: disabled ? AppColors.onSurfaceVariant : fg,
            ),
          ),
        ),
      ),
    );
  }
}
