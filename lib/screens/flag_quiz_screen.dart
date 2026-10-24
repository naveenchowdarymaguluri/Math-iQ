import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/flag_data.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';
import '../services/player_data_service.dart';
import '../services/sound_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/dotted_background.dart';
import '../widgets/math_progress_bar.dart';
import '../widgets/tactile_button.dart';

const int _kSecsPerQ = 15;

// ─── Question model ───────────────────────────────────────────────────────────
class _FlagQ {
  final FlagCountry correct;
  final List<FlagCountry> options;
  const _FlagQ({required this.correct, required this.options});
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class FlagQuizScreen extends StatefulWidget {
  const FlagQuizScreen({super.key});

  @override
  State<FlagQuizScreen> createState() => _FlagQuizScreenState();
}

class _FlagQuizScreenState extends State<FlagQuizScreen> {
  final _rng = Random();

  /// Circular pool — reshuffled whenever exhausted.
  late List<int> _pool;

  late _FlagQ _q;

  // ── Session stats ─────────────────────────────────────────────────────────
  int _streak = 0;      // current streak — resets to 0 on any wrong/timeout
  int _bestStreak = 0;  // best streak this session
  int _xpEarned = 0;
  int _totalAnswered = 0;
  int _totalCorrect = 0;

  // ── Per-question state ────────────────────────────────────────────────────
  int? _selected;
  bool _answered = false;
  int _timeLeft = _kSecsPerQ;
  Timer? _timer;
  bool _wrongFlash = false;

  // ── Connectivity (flag images need internet) ──────────────────────────────
  // null = checking, true = online, false = offline
  bool? _online;

  @override
  void initState() {
    super.initState();
    _pool = List.generate(kFlagPool.length, (i) => i)..shuffle(_rng);
    _q = _nextQ();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _online = null);
    final ok = await ConnectivityService.hasInternet();
    if (!mounted) return;
    setState(() => _online = ok);
    if (ok) _startTimer();
  }

  // ── Question generation ───────────────────────────────────────────────────
  _FlagQ _nextQ() {
    if (_pool.isEmpty) {
      _pool = List.generate(kFlagPool.length, (i) => i)..shuffle(_rng);
    }
    final correct = kFlagPool[_pool.removeLast()];
    final distractors = List<FlagCountry>.from(kFlagPool)
      ..removeWhere((c) => c.code == correct.code)
      ..shuffle(_rng);
    final options = [correct, ...distractors.take(3)]..shuffle(_rng);
    return _FlagQ(correct: correct, options: options);
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _kSecsPerQ;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          if (_timeLeft <= 5 && _timeLeft > 0) {
            SoundService.instance.play(SoundType.tick);
          }
        } else {
          _timer?.cancel();
          _timeUp();
        }
      });
    });
  }

  // ── Answer logic ──────────────────────────────────────────────────────────
  void _timeUp() {
    _timer?.cancel();
    setState(() {
      _answered = true;
      _selected = null;
      _totalAnswered++;
      _streak = 0; // ← RESET to 0
      _xpEarned = max(0, _xpEarned - 1);
    });
    SoundService.instance.play(SoundType.wrong);
    HapticFeedback.heavyImpact();
    _doWrongFlash();
    Future.delayed(const Duration(milliseconds: 1000), _advance);
  }

  void _answer(int idx) {
    if (_answered) return;
    _timer?.cancel();

    final isCorrect = _q.options[idx].code == _q.correct.code;
    setState(() {
      _selected = idx;
      _answered = true;
      _totalAnswered++;
    });

    if (isCorrect) {
      _totalCorrect++;
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      // XP: +5 per correct answer
      _xpEarned += 5;
      SoundService.instance.play(SoundType.correct);
      HapticFeedback.lightImpact();
    } else {
      _streak = 0; // ← RESET to 0
      _xpEarned = max(0, _xpEarned - 1);
      AnalyticsService.instance.logWrongAnswer(
        mode: 'flag_quiz',
        difficulty: 'flag',
        operation: 'identify_flag',
      );
      SoundService.instance.play(SoundType.wrong);
      HapticFeedback.heavyImpact();
      _doWrongFlash();
    }

    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  void _doWrongFlash() {
    setState(() => _wrongFlash = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _wrongFlash = false);
    });
  }

  void _advance() {
    if (!mounted) return;
    setState(() {
      _q = _nextQ();
      _selected = null;
      _answered = false;
    });
    _startTimer();
  }

  // ── Quit flow ─────────────────────────────────────────────────────────────
  void _tryQuit() {
    _timer?.cancel(); // pause game while dialog is open
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _QuitDialog(
        streak: _streak,
        bestStreak: _bestStreak,
        allTimeBest: PlayerDataService.instance.bestFlagStreak,
        xpEarned: _xpEarned,
        totalAnswered: _totalAnswered,
        totalCorrect: _totalCorrect,
        onKeepPlaying: () {
          Navigator.pop(ctx);
          if (!_answered) _startTimer(); // resume
        },
        onEnd: () {
          Navigator.pop(ctx);
          _endSession();
        },
      ),
    );
  }

  Future<void> _endSession() async {
    _timer?.cancel();
    await PlayerDataService.instance.recordFlagQuiz(
      correct: _totalCorrect,
      total: _totalAnswered,
      xpEarned: _xpEarned,
      bestStreak: _bestStreak,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Gate the quiz on connectivity — flag images come from the network.
    if (_online == null) {
      return const Scaffold(
        body: DottedBackground(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }
    if (_online == false) {
      return Scaffold(
        body: DottedBackground(
          child: _OfflineView(
            onRetry: _checkConnection,
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    }

    final timerFrac = _timeLeft / _kSecsPerQ;
    final allTimeBest = PlayerDataService.instance.bestFlagStreak;

    return Scaffold(
      bottomNavigationBar: const AdBanner(placement: 'flagQuizBanner'),
      body: DottedBackground(
        child: Stack(
          children: [
            // Wrong flash overlay
            if (_wrongFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: AppColors.mathRed.withValues(alpha: 0.18),
                  ),
                ),
              ),

            Column(
              children: [
                _AppBar(
                  bestStreak: _bestStreak,
                  allTimeBest: allTimeBest,
                  onQuit: _tryQuit,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: [
                        // Timer bar
                        MathProgressBar(
                          value: timerFrac,
                          fillColor: _timeLeft <= 5
                              ? AppColors.mathRed
                              : AppColors.softOrange,
                        ),
                        const SizedBox(height: 6),

                        // Timer + current streak row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Timer
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_rounded,
                                  color: _timeLeft <= 5
                                      ? AppColors.mathRed
                                      : AppColors.softOrange,
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
                                        : AppColors.softOrange,
                                  ),
                                ),
                              ],
                            ),
                            // Current streak badge
                            _StreakBadge(streak: _streak),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Flag card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: AppColors.secondaryContainer, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.secondaryContainer,
                                offset: Offset(0, 8),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Flag image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _q.correct.imageUrl,
                                  width: 140,
                                  height: 95,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      width: 140,
                                      height: 95,
                                      decoration: BoxDecoration(
                                        color: AppColors
                                            .surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, _, _) => Container(
                                    width: 140,
                                    height: 95,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.surfaceContainerHighest,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.flag_rounded,
                                            color:
                                                AppColors.onSurfaceVariant,
                                            size: 32),
                                        Text(
                                          _q.correct.code,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Which country is this?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Options grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.6,
                          ),
                          itemCount: _q.options.length,
                          itemBuilder: (_, i) {
                            final opt = _q.options[i];
                            final isCorrect = opt.code == _q.correct.code;
                            final isSelected = _selected == i;

                            Color bg = AppColors.surfaceContainerLowest;
                            Color border =
                                AppColors.surfaceContainerHighest;
                            Color shadow =
                                AppColors.surfaceContainerHighest;
                            Color text = AppColors.onSurface;

                            if (_answered) {
                              if (isCorrect) {
                                bg = AppColors.mintGreen;
                                border = const Color(0xFF247A33);
                                shadow = const Color(0xFF1E5C28);
                                text = Colors.white;
                              } else if (isSelected) {
                                bg = AppColors.errorContainer;
                                border = AppColors.error;
                                shadow = AppColors.error;
                                text = AppColors.error;
                              }
                            }

                            return _FlagOptionBtn(
                              label: opt.name,
                              bg: bg,
                              border: border,
                              shadow: shadow,
                              text: text,
                              answered: _answered,
                              onTap: () => _answer(i),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Stats strip at bottom
                        _StatsStrip(
                          totalAnswered: _totalAnswered,
                          totalCorrect: _totalCorrect,
                          xpEarned: _xpEarned,
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

// ─── App bar ──────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final int bestStreak;
  final int allTimeBest;
  final VoidCallback onQuit;

  const _AppBar({
    required this.bestStreak,
    required this.allTimeBest,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    final shown = max(bestStreak, allTimeBest);
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
              onPressed: onQuit,
            ),
            Text(
              'Flag Quiz',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: AppColors.secondary, width: 2),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    'BEST  $shown',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSecondaryContainer,
                    ),
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

// ─── Current streak badge ─────────────────────────────────────────────────────
class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'STREAK  0',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: streak >= 5
            ? AppColors.softOrange
            : AppColors.mintGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: streak >= 5 ? AppColors.tertiary : AppColors.mintGreen,
          width: 2,
        ),
      ),
      child: Text(
        streak >= 5 ? '🔥 STREAK  $streak' : '✅ STREAK  $streak',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: streak >= 5 ? Colors.white : const Color(0xFF1E7A2C),
        ),
      ),
    );
  }
}

// ─── Stats strip ──────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final int totalAnswered;
  final int totalCorrect;
  final int xpEarned;

  const _StatsStrip({
    required this.totalAnswered,
    required this.totalCorrect,
    required this.xpEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.surfaceContainerHighest, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StripItem(
              label: 'Answered', value: '$totalAnswered'),
          _divider(),
          _StripItem(
              label: 'Correct',
              value: '$totalCorrect',
              color: AppColors.mintGreen),
          _divider(),
          _StripItem(
              label: 'XP',
              value: '+$xpEarned',
              color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: AppColors.surfaceContainerHighest,
      );
}

class _StripItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StripItem(
      {required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color ?? AppColors.onSurface,
          ),
        ),
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

// ─── Quit dialog ──────────────────────────────────────────────────────────────
class _QuitDialog extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final int allTimeBest;
  final int xpEarned;
  final int totalAnswered;
  final int totalCorrect;
  final VoidCallback onKeepPlaying;
  final VoidCallback onEnd;

  const _QuitDialog({
    required this.streak,
    required this.bestStreak,
    required this.allTimeBest,
    required this.xpEarned,
    required this.totalAnswered,
    required this.totalCorrect,
    required this.onKeepPlaying,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isNewRecord = bestStreak > allTimeBest;
    final accuracy = totalAnswered > 0
        ? (totalCorrect / totalAnswered * 100).round()
        : 0;

    return AlertDialog(
      backgroundColor: AppColors.creamBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_rounded,
              color: AppColors.secondary, size: 52),
          const SizedBox(height: 12),

          Text(
            'Session Summary',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary),
          ),
          const SizedBox(height: 16),

          // Best streak highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isNewRecord
                  ? AppColors.secondaryContainer
                  : AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isNewRecord ? AppColors.secondary : AppColors.primaryFixedDim,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  isNewRecord ? '🏆 NEW RECORD!' : '🏆 BEST STREAK',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isNewRecord
                        ? AppColors.onSecondaryContainer
                        : AppColors.onPrimaryFixedVariant,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$bestStreak',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: isNewRecord
                        ? AppColors.onSecondaryContainer
                        : AppColors.primary,
                    height: 1,
                  ),
                ),
                if (!isNewRecord)
                  Text(
                    'All-time best: $allTimeBest',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _DialogStat(
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.mintGreen,
                  label: 'Correct',
                  value: '$totalCorrect / $totalAnswered',
                  sub: '$accuracy%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DialogStat(
                  icon: Icons.stars_rounded,
                  iconColor: AppColors.primary,
                  label: 'XP Earned',
                  value: '+$xpEarned',
                  sub: 'this session',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Buttons
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
                      color: AppColors.onSurface,
                    ),
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
                      color: Colors.white,
                    ),
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

class _DialogStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const _DialogStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Option button ────────────────────────────────────────────────────────────
class _FlagOptionBtn extends StatefulWidget {
  final String label;
  final Color bg, border, shadow, text;
  final bool answered;
  final VoidCallback onTap;

  const _FlagOptionBtn({
    required this.label,
    required this.bg,
    required this.border,
    required this.shadow,
    required this.text,
    required this.answered,
    required this.onTap,
  });

  @override
  State<_FlagOptionBtn> createState() => _FlagOptionBtnState();
}

class _FlagOptionBtnState extends State<_FlagOptionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.answered ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.answered
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: widget.answered
          ? null
          : () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(0, 6, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.border, width: 2),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: widget.shadow,
                    offset: const Offset(0, 6),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.text,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Offline view (flag images need internet) ─────────────────────────────────
class _OfflineView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _OfflineView({required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.outlineVariant,
                      offset: Offset(0, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    color: AppColors.onSurfaceVariant, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'No Internet Connection',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The Flag Quiz needs internet to load country flags.\n'
                'Connect to Wi-Fi or mobile data and try again.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TactileButton(
                color: AppColors.primary,
                shadowColor: AppColors.onPrimaryFixedVariant,
                borderRadius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                onPressed: onRetry,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onBack,
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
      ),
    );
  }
}
