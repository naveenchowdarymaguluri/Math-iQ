import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/challenge_level.dart';
import '../models/quiz_question.dart';
import '../models/wrong_answer_item.dart';
import '../services/sound_service.dart';
import '../widgets/ad_banner.dart';
import 'level_results_screen.dart';

class LevelPlayScreen extends StatefulWidget {
  final ChallengeMode mode;
  final int level;
  const LevelPlayScreen({super.key, required this.mode, required this.level});

  @override
  State<LevelPlayScreen> createState() => _LevelPlayScreenState();
}

class _LevelPlayScreenState extends State<LevelPlayScreen>
    with TickerProviderStateMixin {
  late final ChallengeLevel _cfg;
  late final List<QuizQuestion> _questions;

  int _currentQ = 0;
  int _correct = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _timeLeft = 0;
  Timer? _timer;
  bool _flashCorrect = false;
  bool _flashWrong = false;

  // Wrong answers accumulator
  final List<WrongAnswerItem> _wrongAnswers = [];

  // Per-mode: levels 51+ randomly choose keyboard vs MCQ each question
  bool _currentUseKeyboard = false;
  String _typedAnswer = '';
  bool? _keyboardWasCorrect;

  // track per-question result for the dot strip
  late final List<bool?> _results;

  // Question entrance animation
  late AnimationController _questionCtrl;
  late Animation<Offset> _questionSlide;
  late Animation<double> _questionFade;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _cfg = ChallengeLevel.forMode(widget.mode, widget.level);
    _questions = QuizQuestion.generateMixed(
      difficulty: Difficulty.easy,
      operations: widget.mode.operations,
      rangeStart: _cfg.rangeStart,
      rangeEnd: _cfg.rangeEnd,
      count: _cfg.questionCount,
    );
    _results = List.filled(_cfg.questionCount, null);

    _questionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _questionSlide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _questionCtrl, curve: Curves.easeOut));
    _questionFade = CurvedAnimation(parent: _questionCtrl, curve: Curves.easeOut);

    _pickKeyboardMode();
    _questionCtrl.forward();
    _startTimer();
  }

  void _pickKeyboardMode() {
    _currentUseKeyboard = _cfg.useRandomKeyboard && _rng.nextBool();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _cfg.timeLimitSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { t.cancel(); _onTimeout(); }
    });
  }

  void _onTimeout() {
    if (_answered) return;
    final q = _questions[_currentQ];
    HapticFeedback.heavyImpact();
    SoundService.instance.play(SoundType.wrong);
    _wrongAnswers.add(WrongAnswerItem(
      questionText: q.questionText,
      correctAnswer: q.correctAnswer,
    ));
    setState(() {
      _answered = true;
      _results[_currentQ] = false;
      _flashWrong = true;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _flashWrong = false);
      _nextQuestion();
    });
  }

  void _onAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();
    final q = _questions[_currentQ];
    final isCorrect = q.options[index] == q.correctAnswer;
    HapticFeedback.selectionClick();
    setState(() {
      _answered = true;
      _selectedIndex = index;
      _results[_currentQ] = isCorrect;
    });
    if (isCorrect) {
      _correct++;
      SoundService.instance.play(SoundType.correct);
      setState(() => _flashCorrect = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() => _flashCorrect = false);
        _nextQuestion();
      });
    } else {
      _wrongAnswers.add(WrongAnswerItem(
        questionText: q.questionText,
        correctAnswer: q.correctAnswer,
        givenAnswer: q.options[index],
      ));
      SoundService.instance.play(SoundType.wrong);
      setState(() => _flashWrong = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() => _flashWrong = false);
        _nextQuestion();
      });
    }
  }

  void _submitTypedAnswer() {
    if (_answered || _typedAnswer.isEmpty) return;
    _timer?.cancel();
    final q = _questions[_currentQ];
    final typed = int.tryParse(_typedAnswer);
    final isCorrect = typed != null && typed == q.correctAnswer;

    setState(() {
      _answered = true;
      _keyboardWasCorrect = isCorrect;
      _results[_currentQ] = isCorrect;
    });

    if (isCorrect) {
      _correct++;
      SoundService.instance.play(SoundType.correct);
      setState(() => _flashCorrect = true);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _flashCorrect = false);
        _nextQuestion();
      });
    } else {
      _wrongAnswers.add(WrongAnswerItem(
        questionText: q.questionText,
        correctAnswer: q.correctAnswer,
        givenAnswer: typed,
      ));
      SoundService.instance.play(SoundType.wrong);
      setState(() => _flashWrong = true);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _flashWrong = false);
        _nextQuestion();
      });
    }
  }

  void _nextQuestion() {
    if (_currentQ + 1 >= _questions.length) { _goToResults(); return; }
    _questionCtrl.reset();
    setState(() {
      _currentQ++;
      _selectedIndex = null;
      _answered = false;
      _typedAnswer = '';
      _keyboardWasCorrect = null;
    });
    _pickKeyboardMode();
    _questionCtrl.forward();
    _startTimer();
  }

  void _goToResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LevelResultsScreen(
          mode: widget.mode,
          level: widget.level,
          correct: _correct,
          total: _questions.length,
          cfg: _cfg,
          wrongAnswers: List.unmodifiable(_wrongAnswers),
        ),
      ),
    );
  }

  void _showQuitDialog() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Quit Level?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text('Your current progress will be lost.',
            style: GoogleFonts.beVietnamPro()),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _startTimer(); },
            child: const Text('Continue Playing'),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: Text('Quit',
                style: TextStyle(color: Color(widget.mode.primaryColorValue))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Color(widget.mode.primaryColorValue);
    final shadow = Color(widget.mode.shadowColorValue);
    final q = _questions[_currentQ];
    final timerFrac = (_timeLeft / _cfg.timeLimitSeconds).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F8),
      bottomNavigationBar: const SafeArea(
        child: AdBanner(placement: 'levelPlayBanner'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              _Header(
                mode: widget.mode,
                level: widget.level,
                currentQ: _currentQ,
                total: _questions.length,
                timeLeft: _timeLeft,
                totalTime: _cfg.timeLimitSeconds,
                primary: primary,
                shadow: shadow,
                onQuit: _showQuitDialog,
              ),

              // Question dot strip
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _QuestionDots(
                  total: _questions.length,
                  current: _currentQ,
                  results: _results,
                  primary: primary,
                ),
              ),

              // Keyboard/MCQ badge (levels 51+)
              if (_cfg.useRandomKeyboard)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(_currentUseKeyboard),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _currentUseKeyboard
                            ? const Color(0xFF6A1B9A)
                            : primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _currentUseKeyboard ? '⌨  Type the answer' : '🔘  Choose the answer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              // Question card (animated)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: FadeTransition(
                  opacity: _questionFade,
                  child: SlideTransition(
                    position: _questionSlide,
                    child: _QuestionCard(
                      question: q,
                      primary: primary,
                      timerFrac: timerFrac,
                    ),
                  ),
                ),
              ),

              // Answer input
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: _currentUseKeyboard
                      ? _NumberKeypad(
                          key: ValueKey('kb_$_currentQ'),
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
                      : _OptionsGrid(
                          key: ValueKey(_currentQ),
                          options: q.options,
                          correctAnswer: q.correctAnswer,
                          selectedIndex: _selectedIndex,
                          answered: _answered,
                          primary: primary,
                          shadow: shadow,
                          onTap: _answered ? null : _onAnswer,
                        ),
                ),
              ),
            ],
          ),

          // Flash overlays
          if (_flashCorrect)
            IgnorePointer(
              child: Container(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.15)),
            ),
          if (_flashWrong)
            IgnorePointer(
              child: Container(
                  color: const Color(0xFFE53935).withValues(alpha: 0.15)),
            ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final ChallengeMode mode;
  final int level;
  final int currentQ;
  final int total;
  final int timeLeft;
  final int totalTime;
  final Color primary;
  final Color shadow;
  final VoidCallback onQuit;

  const _Header({
    required this.mode,
    required this.level,
    required this.currentQ,
    required this.total,
    required this.timeLeft,
    required this.totalTime,
    required this.primary,
    required this.shadow,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    final timerFrac = (timeLeft / totalTime).clamp(0.0, 1.0);
    final timerRed = timerFrac < 0.3;

    return Container(
      decoration: BoxDecoration(
        color: primary,
        boxShadow: [
          BoxShadow(color: shadow, offset: const Offset(0, 4), blurRadius: 0)
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onQuit,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mode.emoji}  ${mode.displayName}  ·  Level $level',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: timerFrac,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: AlwaysStoppedAnimation(
                      timerRed ? Colors.red.shade300 : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: timerRed
                  ? Colors.red.shade700
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: timerRed
                  ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  timerRed ? Icons.timer_off_rounded : Icons.timer_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  '${timeLeft}s',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Question progress dots ────────────────────────────────────────────────────
class _QuestionDots extends StatelessWidget {
  final int total;
  final int current;
  final List<bool?> results;
  final Color primary;

  const _QuestionDots({
    required this.total,
    required this.current,
    required this.results,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final result = results[i];
        final isCurrent = i == current;
        Color dotColor;
        double size;

        if (result == true) {
          dotColor = const Color(0xFF4CAF50);
          size = 10;
        } else if (result == false) {
          dotColor = const Color(0xFFE53935);
          size = 10;
        } else if (isCurrent) {
          dotColor = primary;
          size = 12;
        } else {
          dotColor = const Color(0xFFD0D0D0);
          size = 8;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isCurrent ? 24 : size,
            height: size,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: Offset.zero,
                      )
                    ]
                  : [],
            ),
            child: result == true
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 7)
                : result == false
                    ? const Icon(Icons.close_rounded, color: Colors.white, size: 7)
                    : null,
          ),
        );
      }),
    );
  }
}

// ─── Question card ────────────────────────────────────────────────────────────
class _QuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final Color primary;
  final double timerFrac;

  const _QuestionCard({
    required this.question,
    required this.primary,
    required this.timerFrac,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.12),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            question.questionText,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: timerFrac,
              minHeight: 6,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation(
                timerFrac < 0.3
                    ? const Color(0xFFE53935)
                    : timerFrac < 0.6
                        ? const Color(0xFFFF9800)
                        : primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Options 2×2 grid ─────────────────────────────────────────────────────────
class _OptionsGrid extends StatefulWidget {
  final List<int> options;
  final int correctAnswer;
  final int? selectedIndex;
  final bool answered;
  final Color primary;
  final Color shadow;
  final void Function(int)? onTap;

  const _OptionsGrid({
    super.key,
    required this.options,
    required this.correctAnswer,
    required this.selectedIndex,
    required this.answered,
    required this.primary,
    required this.shadow,
    this.onTap,
  });

  @override
  State<_OptionsGrid> createState() => _OptionsGridState();
}

class _OptionsGridState extends State<_OptionsGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _labels = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterCtrl.forward();
  }

  @override
  void dispose() { _enterCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _OptionCard(label: _labels[0], value: widget.options[0], index: 0, correctAnswer: widget.correctAnswer, selectedIndex: widget.selectedIndex, answered: widget.answered, primary: widget.primary, shadow: widget.shadow, onTap: widget.onTap)),
                  const SizedBox(width: 14),
                  Expanded(child: _OptionCard(label: _labels[1], value: widget.options[1], index: 1, correctAnswer: widget.correctAnswer, selectedIndex: widget.selectedIndex, answered: widget.answered, primary: widget.primary, shadow: widget.shadow, onTap: widget.onTap)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _OptionCard(label: _labels[2], value: widget.options[2], index: 2, correctAnswer: widget.correctAnswer, selectedIndex: widget.selectedIndex, answered: widget.answered, primary: widget.primary, shadow: widget.shadow, onTap: widget.onTap)),
                  const SizedBox(width: 14),
                  Expanded(child: _OptionCard(label: _labels[3], value: widget.options[3], index: 3, correctAnswer: widget.correctAnswer, selectedIndex: widget.selectedIndex, answered: widget.answered, primary: widget.primary, shadow: widget.shadow, onTap: widget.onTap)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Individual option card ───────────────────────────────────────────────────
class _OptionCard extends StatefulWidget {
  final String label;
  final int value;
  final int index;
  final int correctAnswer;
  final int? selectedIndex;
  final bool answered;
  final Color primary;
  final Color shadow;
  final void Function(int)? onTap;

  const _OptionCard({
    required this.label,
    required this.value,
    required this.index,
    required this.correctAnswer,
    required this.selectedIndex,
    required this.answered,
    required this.primary,
    required this.shadow,
    this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.0).animate(_bounceCtrl);
  }

  @override
  void didUpdateWidget(_OptionCard old) {
    super.didUpdateWidget(old);
    if (!old.answered && widget.answered &&
        widget.selectedIndex == widget.index) {
      _bounceAnim = TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.94), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 40),
      ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _bounceCtrl.dispose(); super.dispose(); }

  bool get _isSelected => widget.selectedIndex == widget.index;
  bool get _isCorrect => widget.value == widget.correctAnswer;

  _CardState get _cardState {
    if (!widget.answered) return _CardState.idle;
    if (_isSelected && _isCorrect) return _CardState.correct;
    if (_isSelected && !_isCorrect) return _CardState.wrong;
    if (!_isSelected && _isCorrect) return _CardState.revealCorrect;
    return _CardState.dimmed;
  }

  Color get _bgColor => switch (_cardState) {
        _CardState.idle => Colors.white,
        _CardState.correct => const Color(0xFF4CAF50),
        _CardState.wrong => const Color(0xFFE53935),
        _CardState.revealCorrect => const Color(0xFFE8F5E9),
        _CardState.dimmed => const Color(0xFFF5F5F5),
      };

  Color get _borderColor => switch (_cardState) {
        _CardState.idle => widget.primary.withValues(alpha: 0.3),
        _CardState.correct => const Color(0xFF2E7D32),
        _CardState.wrong => const Color(0xFFB71C1C),
        _CardState.revealCorrect => const Color(0xFF4CAF50),
        _CardState.dimmed => const Color(0xFFE0E0E0),
      };

  Color get _shadowColor => switch (_cardState) {
        _CardState.idle => widget.shadow.withValues(alpha: 0.35),
        _CardState.correct => const Color(0xFF1B5E20),
        _CardState.wrong => const Color(0xFF7F0000),
        _CardState.revealCorrect => const Color(0xFF388E3C),
        _CardState.dimmed => Colors.transparent,
      };

  Color get _labelBg => switch (_cardState) {
        _CardState.idle => widget.primary,
        _CardState.correct => Colors.white.withValues(alpha: 0.3),
        _CardState.wrong => Colors.white.withValues(alpha: 0.3),
        _CardState.revealCorrect => const Color(0xFF4CAF50),
        _CardState.dimmed => const Color(0xFFBDBDBD),
      };

  Color get _valueColor => switch (_cardState) {
        _CardState.idle => const Color(0xFF1A1A1A),
        _CardState.correct => Colors.white,
        _CardState.wrong => Colors.white,
        _CardState.revealCorrect => const Color(0xFF2E7D32),
        _CardState.dimmed => const Color(0xFFBDBDBD),
      };

  @override
  Widget build(BuildContext context) {
    final canTap = widget.onTap != null && !widget.answered;

    return GestureDetector(
      onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
      onTapUp: canTap
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!(widget.index);
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _bounceAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _pressed ? 0.95 : _bounceAnim.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor, width: 2.5),
            boxShadow: _pressed || _cardState == _CardState.dimmed
                ? []
                : [
                    BoxShadow(
                      color: _shadowColor,
                      offset: const Offset(0, 5),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _labelBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          widget.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (widget.answered) ...[
                      if (_cardState == _CardState.correct)
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 22)
                      else if (_cardState == _CardState.wrong)
                        const Icon(Icons.cancel_rounded,
                            color: Colors.white, size: 22)
                      else if (_cardState == _CardState.revealCorrect)
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF4CAF50), size: 22)
                      else
                        const SizedBox(width: 22),
                    ],
                  ],
                ),
                const Spacer(),
                Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: _cardState == _CardState.idle ? 28 : 26,
                      fontWeight: FontWeight.w900,
                      color: _valueColor,
                    ),
                    child: Text('${widget.value}', textAlign: TextAlign.center),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CardState { idle, correct, wrong, revealCorrect, dimmed }

// ─── Number keypad (keyboard mode) ───────────────────────────────────────────
class _NumberKeypad extends StatelessWidget {
  final String typed;
  final bool answered;
  final bool? wasCorrect;
  final int correctAnswer;
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  const _NumberKeypad({
    super.key,
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
    Color boxBg = Colors.white;
    Color boxBorder = const Color(0xFFE0E0E0);
    if (answered && wasCorrect == true) {
      boxBg = const Color(0xFF4CAF50);
      boxBorder = const Color(0xFF2E7D32);
    } else if (answered && wasCorrect == false) {
      boxBg = const Color(0xFFFFEBEE);
      boxBorder = const Color(0xFFE53935);
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
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
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: typed.isEmpty
                        ? const Color(0xFFBDBDBD)
                        : answered && wasCorrect == true
                            ? Colors.white
                            : answered && wasCorrect == false
                                ? const Color(0xFFE53935)
                                : const Color(0xFF1A1A1A),
                  ),
                ),
                if (answered && wasCorrect == false) ...[
                  const SizedBox(width: 12),
                  Text(
                    '→ $correctAnswer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!answered) ...[
          _row(['7', '8', '9'], onDigit),
          const SizedBox(height: 8),
          _row(['4', '5', '6'], onDigit),
          const SizedBox(height: 8),
          _row(['1', '2', '3'], onDigit),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _KeyBtn(label: '⌫', bg: const Color(0xFFFF9800).withValues(alpha: 0.15), fg: const Color(0xFFFF9800), onTap: onBackspace)),
              const SizedBox(width: 8),
              Expanded(child: _KeyBtn(label: '0', onTap: () => onDigit('0'))),
              const SizedBox(width: 8),
              Expanded(child: _KeyBtn(
                label: '✓',
                bg: typed.isEmpty ? const Color(0xFFEEEEEE) : const Color(0xFF4CAF50),
                fg: typed.isEmpty ? const Color(0xFF9E9E9E) : Colors.white,
                onTap: typed.isEmpty ? null : onSubmit,
              )),
            ],
          ),
        ],
      ],
    );
  }

  Widget _row(List<String> digits, void Function(String) onDigit) => Row(
        children: digits.asMap().entries.expand((e) {
          return [
            if (e.key > 0) const SizedBox(width: 8),
            Expanded(child: _KeyBtn(label: e.value, onTap: () => onDigit(e.value))),
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
    final bg = widget.bg ?? const Color(0xFFF5F5F5);
    final fg = widget.fg ?? const Color(0xFF1A1A1A);
    final disabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            },
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: _pressed
            ? Matrix4.translationValues(0, 4, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bg.withValues(alpha: 0.7), width: 1.5),
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
              color: disabled ? const Color(0xFFBDBDBD) : fg,
            ),
          ),
        ),
      ),
    );
  }
}
