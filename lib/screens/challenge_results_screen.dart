import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/ad_service.dart';
import '../services/player_data_service.dart';
import '../services/sound_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/ad_rewarded_button.dart';
import '../widgets/dotted_background.dart';
import '../widgets/math_progress_bar.dart';
import '../widgets/tactile_button.dart';
import 'main_shell.dart';
import 'challenge_screen.dart';

class ChallengeResultsScreen extends StatefulWidget {
  final int waveReached;
  final int xpEarned;
  final int correct;
  final int total;
  final int highestStreak;

  const ChallengeResultsScreen({
    super.key,
    required this.waveReached,
    required this.xpEarned,
    required this.correct,
    required this.total,
    required this.highestStreak,
  });

  @override
  State<ChallengeResultsScreen> createState() =>
      _ChallengeResultsScreenState();
}

class _ChallengeResultsScreenState extends State<ChallengeResultsScreen>
    with TickerProviderStateMixin {
  final List<_Confetti> _confetti = [];
  late AnimationController _cardCtrl;
  late Animation<double> _cardScale;

  bool _isNewRecord = false;
  bool _recorded = false;
  bool _doubledXp = false;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardScale = CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut);
    _cardCtrl.forward();
    _record();
    _maybeShowInterstitial();
  }

  void _maybeShowInterstitial() {
    AdService.instance.onLevelCompleted();
    if (!AdService.instance.shouldShowInterstitial) return;
    // Let the result card + confetti land first.
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      AdService.instance.maybeShowInterstitial(
        placement: AdPlacement.challengeInterstitial,
      );
    });
  }

  void _doubleXp() {
    if (_doubledXp) return;
    PlayerDataService.instance.addBonusXP(widget.xpEarned);
    if (mounted) setState(() => _doubledXp = true);
  }

  Future<void> _record() async {
    if (_recorded) return;
    _recorded = true;
    _isNewRecord = await PlayerDataService.instance.recordChallenge(
      waveReached: widget.waveReached,
      xpEarned: widget.xpEarned,
      correct: widget.correct,
      total: widget.total,
      highestStreak: widget.highestStreak,
    );
    if (_isNewRecord && mounted) {
      SoundService.instance.play(SoundType.levelUp);
    }
    _spawnConfetti();
    Future.delayed(const Duration(seconds: 4), _spawnConfetti);
    if (mounted) setState(() {});
  }

  void _spawnConfetti() {
    if (!mounted) return;
    final rnd = Random();
    setState(() {
      _confetti.addAll(List.generate(40, (_) => _Confetti(rnd)));
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _confetti.clear());
    });
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = PlayerDataService.instance;
    final accuracy =
        widget.total > 0 ? (widget.correct / widget.total * 100).round() : 0;

    return Scaffold(
      body: DottedBackground(
        child: Stack(
          children: [
            ..._confetti.map((c) => _ConfettiWidget(data: c)),
            SafeArea(
              child: Column(
                children: [
                  _AppBar(),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: ScaleTransition(
                          scale: _cardScale,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color: AppColors.mathRed, width: 4),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.mathRed,
                                  offset: Offset(8, 8),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.mathRed
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                          color: AppColors.mathRed,
                                          offset: Offset(0, 4),
                                          blurRadius: 0)
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    color: AppColors.mathRed,
                                    size: 48,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Wave reached headline
                                Text(
                                  'WAVE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 3,
                                  ),
                                ),
                                Text(
                                  '${widget.waveReached}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 80,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.mathRed,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  'REACHED',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 3,
                                  ),
                                ),

                                // New record banner
                                if (_isNewRecord) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(
                                          color: AppColors.secondary,
                                          width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: AppColors.secondary,
                                            offset: Offset(0, 4),
                                            blurRadius: 0)
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('🏆',
                                            style:
                                                TextStyle(fontSize: 22)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'NEW PERSONAL BEST!',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: AppColors
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Best: Wave ${svc.bestChallengeWave}',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 13,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // Stats row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                        label: 'XP EARNED',
                                        value: '+${widget.xpEarned}',
                                        sub: 'Total: ${svc.totalXP}',
                                        bg: AppColors.primaryFixed,
                                        textColor: AppColors.onPrimaryFixed,
                                        subColor:
                                            AppColors.onPrimaryFixedVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatCard(
                                        label: 'ACCURACY',
                                        value: '$accuracy%',
                                        sub: '${widget.correct}/${widget.total} correct',
                                        bg: AppColors.mintGreen
                                            .withValues(alpha: 0.15),
                                        textColor: AppColors.inkPurple,
                                        subColor: AppColors.mintGreen,
                                        border: AppColors.mintGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Streak card
                                if (widget.highestStreak > 0)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.softOrange
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.softOrange,
                                          width: 2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('🔥',
                                            style:
                                                TextStyle(fontSize: 20)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Best streak: ${widget.highestStreak} in a row',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppColors.tertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 12),

                                // Level progress
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.creamBg,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.outlineVariant,
                                        width: 2),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Level ${svc.level} Progress',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                                fontSize: 13),
                                          ),
                                          Text(
                                            '${(svc.levelProgress * 100).round()}%',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      MathProgressBar(
                                          value: svc.levelProgress),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${svc.xpForNextLevel} XP to Level ${svc.level + 1}',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            color:
                                                AppColors.onSurfaceVariant,
                                            fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Rewarded ad: double the XP just earned
                                if (widget.xpEarned > 0 && !_doubledXp) ...[
                                  AdRewardedButton(
                                    label:
                                        'Watch Ad → 2× XP (+${widget.xpEarned})',
                                    rewardLabel: 'Double XP',
                                    color: const Color(0xFF6A1B9A),
                                    shadowColor: const Color(0xFF4A148C),
                                    placement:
                                        AdPlacement.challengeDoubleXpRewarded,
                                    onRewarded: _doubleXp,
                                  ),
                                  const SizedBox(height: 16),
                                ] else if (_doubledXp) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.mintGreen
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.mintGreen,
                                          width: 2),
                                    ),
                                    child: Text(
                                      '🎉 +${widget.xpEarned} bonus XP added!',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.mintGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Banner ad
                                const AdBanner(
                                    placement: 'challengeResultsBanner'),
                                const SizedBox(height: 20),

                                // Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: TactileButton(
                                        color:
                                            AppColors.surfaceContainerHigh,
                                        shadowColor:
                                            AppColors.outlineVariant,
                                        borderRadius: 16,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        onPressed: () =>
                                            Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const ChallengeScreen()),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.replay_rounded,
                                                color: AppColors
                                                    .onSurfaceVariant),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Again',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TactileButton(
                                        color: AppColors.mathRed,
                                        shadowColor:
                                            const Color(0xFF960000),
                                        borderRadius: 16,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        onPressed: () => Navigator.of(context)
                                            .pushAndRemoveUntil(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const MainShell()),
                                          (r) => false,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.home_rounded,
                                                color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Home',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
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
                        ),
                      ),
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

// ─── App bar ──────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom:
              BorderSide(color: AppColors.surfaceContainerHighest, width: 4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.mathRed, size: 28),
          const SizedBox(width: 8),
          Text(
            'Challenge Mode',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.mathRed),
          ),
        ],
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color bg;
  final Color textColor;
  final Color subColor;
  final Color? border;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.bg,
    required this.textColor,
    required this.subColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: border ?? AppColors.primaryContainer, width: 2),
      ),
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: subColor,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: textColor)),
          Text(sub,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 11, color: subColor),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Confetti (identical pattern to ResultsScreen) ────────────────────────────
class _Confetti {
  final double left;
  final double top;
  final Color color;
  final double size;
  final double duration;

  _Confetti(Random rnd)
      : left = rnd.nextDouble(),
        top = rnd.nextDouble() * -0.2,
        color = [
          AppColors.mathRed,
          AppColors.softOrange,
          AppColors.mintGreen,
          AppColors.secondaryContainer,
          AppColors.primary,
        ][rnd.nextInt(5)],
        size = rnd.nextDouble() * 8 + 6,
        duration = rnd.nextDouble() * 2 + 2;
}

class _ConfettiWidget extends StatefulWidget {
  final _Confetti data;
  const _ConfettiWidget({required this.data});

  @override
  State<_ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<_ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fall;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration:
          Duration(milliseconds: (widget.data.duration * 1000).round()),
    )..forward();
    _fall = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fall,
      builder: (context, child) => Positioned(
        left: widget.data.left * MediaQuery.of(context).size.width,
        top: widget.data.top * MediaQuery.of(context).size.height +
            _fall.value * MediaQuery.of(context).size.height * 1.2,
        child: Transform.rotate(
          angle: _fall.value * 6.28,
          child: Container(
            width: widget.data.size,
            height: widget.data.size,
            decoration: BoxDecoration(
              color: widget.data.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
