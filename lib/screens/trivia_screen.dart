import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/trivia_question.dart';
import '../models/session_result.dart';
import '../services/trivia_service.dart';
import '../services/player_data_service.dart';
import '../services/sound_service.dart';
import '../widgets/dotted_background.dart';
import '../widgets/tactile_button.dart';

class TriviaScreen extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialCategoryTitle;

  const TriviaScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryTitle,
  });

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  int? _selectedCategoryId;
  final String _difficulty = 'any';
  bool _isLoading = true;
  String? _errorMessage;

  List<TriviaQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _answered = false;

  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _xpEarned = 0;

  static const int _kSecsPerQuestion = 15;
  int _timeLeft = _kSecsPerQuestion;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId ?? 19; // Default to Mathematics
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentIndex = 0;
      _selectedOptionIndex = null;
      _answered = false;
      _score = 0;
      _streak = 0;
      _xpEarned = 0;
    });

    _timer?.cancel();

    try {
      final list = await TriviaService.instance.fetchQuestions(
        amount: 10,
        categoryId: _selectedCategoryId,
        difficulty: _difficulty == 'any' ? null : _difficulty,
      );

      if (!mounted) return;

      if (list.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No questions found. Try another category or difficulty!';
        });
      } else {
        setState(() {
          _questions = list;
          _isLoading = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load questions. Check your connection.';
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _kSecsPerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          if (_timeLeft <= 5 && _timeLeft > 0) {
            SoundService.instance.play(SoundType.tick);
          }
        } else {
          timer.cancel();
          _timeUp();
        }
      });
    });
  }

  void _timeUp() {
    if (_answered) return;
    _timer?.cancel();
    setState(() {
      _answered = true;
      _selectedOptionIndex = null;
      _streak = 0;
    });
    SoundService.instance.play(SoundType.wrong);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 1400), _nextQuestion);
  }

  void _selectOption(int index) {
    if (_answered) return;
    _timer?.cancel();

    final q = _questions[_currentIndex];
    final isCorrect = q.options[index] == q.correctAnswer;

    setState(() {
      _answered = true;
      _selectedOptionIndex = index;
    });

    if (isCorrect) {
      _score++;
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      _xpEarned += 15 + (_streak > 2 ? 5 : 0);
      SoundService.instance.play(SoundType.correct);
      HapticFeedback.lightImpact();
    } else {
      _streak = 0;
      SoundService.instance.play(SoundType.wrong);
      HapticFeedback.heavyImpact();
    }

    Future.delayed(const Duration(milliseconds: 1400), _nextQuestion);
  }

  void _nextQuestion() {
    if (!mounted) return;
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _answered = false;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    SoundService.instance.play(SoundType.levelUp);

    final result = SessionResult(
      mode: 'OpenTDB Trivia',
      correct: _score,
      wrong: _questions.length - _score,
      total: _questions.length,
      xpEarned: _xpEarned,
      highestStreak: _bestStreak,
      date: DateTime.now(),
    );
    PlayerDataService.instance.recordSession(result);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TriviaResultDialog(
        score: _score,
        total: _questions.length,
        xpEarned: _xpEarned,
        bestStreak: _bestStreak,
        onPlayAgain: () {
          Navigator.pop(context);
          _loadQuestions();
        },
        onExit: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
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
    return Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildCategorySelector(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : _errorMessage != null
                        ? _buildErrorView()
                        : _buildQuizBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'OpenTDB Trivia',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'LIVE API',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Powered by Open Trivia Database',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // XP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.secondary, size: 18),
                const SizedBox(width: 4),
                Text(
                  '+$_xpEarned XP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: TriviaService.categories.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = TriviaService.categories[i];
          final isSelected = _selectedCategoryId == cat.id;
          return ChoiceChip(
            label: Text('${cat.emoji} ${cat.title}'),
            selected: isSelected,
            selectedColor: AppColors.primary,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.onSurface,
            ),
            backgroundColor: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.surfaceContainerHighest,
              ),
            ),
            onSelected: (selected) {
              if (selected && _selectedCategoryId != cat.id) {
                setState(() => _selectedCategoryId = cat.id);
                _loadQuestions();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.mathRed),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TactileButton(
              color: AppColors.primary,
              shadowColor: AppColors.onPrimaryFixedVariant,
              onPressed: _loadQuestions,
              child: Text(
                'Retry',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizBody() {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress & Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of ${_questions.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (_streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.softOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '$_streak Streak',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.softOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              // Timer countdown
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: _timeLeft <= 5 ? AppColors.mathRed : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_timeLeft}s',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _timeLeft <= 5 ? AppColors.mathRed : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),

          // Question Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceContainerHighest, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.surfaceContainerHighest,
                  offset: Offset(0, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        q.difficulty.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.category,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  q.question,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPurple,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Options List
          ...List.generate(q.options.length, (idx) {
            final option = q.options[idx];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOptionTile(option, idx, q.correctAnswer),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String option, int index, String correctAnswer) {
    Color cardColor = AppColors.surfaceContainerLowest;
    Color borderColor = AppColors.surfaceContainerHighest;
    Color textColor = AppColors.onSurface;

    if (_answered) {
      if (option == correctAnswer) {
        cardColor = AppColors.mintGreen.withValues(alpha: 0.15);
        borderColor = AppColors.mintGreen;
        textColor = AppColors.mintGreen;
      } else if (index == _selectedOptionIndex) {
        cardColor = AppColors.mathRed.withValues(alpha: 0.15);
        borderColor = AppColors.mathRed;
        textColor = AppColors.mathRed;
      }
    }

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.6),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (_answered && option == correctAnswer)
              const Icon(Icons.check_circle_rounded, color: AppColors.mintGreen, size: 22)
            else if (_answered && index == _selectedOptionIndex)
              const Icon(Icons.cancel_rounded, color: AppColors.mathRed, size: 22),
          ],
        ),
      ),
    );
  }
}

class _TriviaResultDialog extends StatelessWidget {
  final int score;
  final int total;
  final int xpEarned;
  final int bestStreak;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _TriviaResultDialog({
    required this.score,
    required this.total,
    required this.xpEarned,
    required this.bestStreak,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score / total * 100).round();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pct >= 80 ? '🎉 Brilliant!' : pct >= 50 ? '👏 Well Done!' : '💪 Keep Practicing!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.inkPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'OpenTDB Trivia Results',
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statTile('Score', '$score/$total', AppColors.primary),
                _statTile('Accuracy', '$pct%', AppColors.mintGreen),
                _statTile('XP Earned', '+$xpEarned', AppColors.secondary),
              ],
            ),
            const SizedBox(height: 24),
            TactileButton(
              color: AppColors.primary,
              shadowColor: AppColors.onPrimaryFixedVariant,
              onPressed: onPlayAgain,
              child: Center(
                child: Text(
                  'Play Again',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onExit,
              child: Text(
                'Back to Home',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
