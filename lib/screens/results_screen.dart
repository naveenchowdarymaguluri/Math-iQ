import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/session_result.dart';
import '../services/ad_service.dart';
import '../services/player_data_service.dart';
import '../services/sound_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_menu_sheet.dart';
import '../widgets/dotted_background.dart';
import '../widgets/math_progress_bar.dart';
import '../widgets/share_card.dart';
import '../widgets/tactile_button.dart';
import 'main_shell.dart';

class ResultsScreen extends StatefulWidget {
  final SessionResult result;
  const ResultsScreen({super.key, required this.result});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  final List<_Confetti> _confetti = [];
  late AnimationController _cardCtrl;
  late Animation<double> _cardScale;
  bool _leveledUp = false;
  int _levelBefore = 1;
  int _levelAfter = 1;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardScale = CurvedAnimation(
      parent: _cardCtrl,
      curve: Curves.elasticOut,
    );
    _cardCtrl.forward();
    _recordSession();
    _maybeShowInterstitial();
  }

  void _maybeShowInterstitial() {
    AdService.instance.onLevelCompleted();
    if (!AdService.instance.shouldShowInterstitial) return;
    // Let the result card + confetti land first.
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      AdService.instance.maybeShowInterstitial(
        placement: AdPlacement.practiceInterstitial,
      );
    });
  }

  Future<void> _recordSession() async {
    if (_recorded) return;
    _recorded = true;

    final svc = PlayerDataService.instance;
    _levelBefore = svc.level;

    await svc.recordSession(widget.result);

    _levelAfter = svc.level;
    _leveledUp = _levelAfter > _levelBefore;

    if (!mounted) return;
    if (_leveledUp) {
      SoundService.instance.play(SoundType.levelUp);
    }

    _spawnConfetti();
    Future.delayed(const Duration(seconds: 4), _spawnConfetti);
    setState(() {});
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
    final r = widget.result;
    final accuracy = (r.accuracy * 100).round();

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
                                  color: AppColors.primary, width: 4),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.primary,
                                  offset: Offset(8, 8),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Trophy icon
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                          color: AppColors.secondary,
                                          offset: Offset(0, 4),
                                          blurRadius: 0)
                                    ],
                                  ),
                                  child: const Icon(
                                      Icons.emoji_events_rounded,
                                      color:
                                          AppColors.onSecondaryContainer,
                                      size: 48),
                                ),
                                const SizedBox(height: 12),

                                // Title
                                Text(
                                  r.isPerfect
                                      ? 'Perfect Score! 🎉'
                                      : accuracy >= 80
                                          ? 'Well Done!'
                                          : 'Keep Going!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  r.mode,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      color: AppColors.onSurfaceVariant),
                                ),

                                // Level-up banner
                                if (_leveledUp) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding:
                                        const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.softOrange,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: AppColors.tertiary,
                                            offset: Offset(0, 4),
                                            blurRadius: 0)
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('⬆️',
                                            style: TextStyle(
                                                fontSize: 22)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'LEVEL UP!  $_levelBefore → $_levelAfter',
                                          style: GoogleFonts
                                              .plusJakartaSans(
                                            fontWeight:
                                                FontWeight.w800,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // Score + accuracy cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                        label: 'BEST STREAK',
                                        value: '${r.highestStreak}',
                                        sub: 'In a row',
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
                                        sub: accuracy >= 80
                                            ? 'Flawless!'
                                            : 'Keep going!',
                                        bg: AppColors.mintGreen
                                            .withValues(alpha: 0.2),
                                        textColor: AppColors.inkPurple,
                                        subColor: AppColors.mintGreen,
                                        border: AppColors.mintGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Correct / wrong inline cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _InlineStatCard(
                                        icon: Icons.check_circle_rounded,
                                        iconColor: AppColors.mintGreen,
                                        label:
                                            '${r.correct} Correct',
                                        sub:
                                            'Out of ${r.total} total',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _InlineStatCard(
                                        icon: Icons.cancel_rounded,
                                        iconColor: AppColors.mathRed,
                                        label: '${r.wrong} Wrong',
                                        sub: r.highestStreak > 0
                                            ? 'Best streak: ${r.highestStreak}'
                                            : 'Review these!',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

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
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Text(
                                              'Level ${svc.level} Progress',
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.primary,
                                                      fontSize: 13)),
                                          Text(
                                              '${(svc.levelProgress * 100).round()}%',
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.primary,
                                                      fontSize: 13)),
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
                                            fontStyle:
                                                FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Practice results banner ad
                                const AdBanner(
                                    placement: 'practiceResultsBanner'),
                                const SizedBox(height: 20),

                                // Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: TactileButton(
                                        color: AppColors.surfaceContainerHigh,
                                        shadowColor:
                                            AppColors.outlineVariant,
                                        borderRadius: 16,
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 16),
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                                Icons.replay_rounded,
                                                color: AppColors
                                                    .onSurfaceVariant),
                                            const SizedBox(width: 8),
                                            Text('Again',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: AppColors
                                                      .onSurfaceVariant,
                                                )),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TactileButton(
                                        color: AppColors.secondaryContainer,
                                        shadowColor: AppColors.secondary,
                                        borderRadius: 16,
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 16),
                                        onPressed: () =>
                                            Navigator.of(context)
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
                                                color: AppColors
                                                    .onSecondaryContainer),
                                            const SizedBox(width: 8),
                                            Text('Home',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: AppColors
                                                      .onSecondaryContainer,
                                                )),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // ── Share with friends ─────────────────
                                GestureDetector(
                                  onTap: () =>
                                      ShareCard.show(context),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.inkPurple,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Color(0xFF1A1A2E),
                                            offset: Offset(0, 4),
                                            blurRadius: 0)
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.share_rounded,
                                            color: Colors.white70,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          PlayerDataService.instance
                                                  .canEarnShareXP
                                              ? 'Challenge a Friend  •  +${PlayerDataService.instance.nextShareXp} XP'
                                              : 'Challenge a Friend',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
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

// ─── Widgets ──────────────────────────────────────────────────────────────────
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
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.primary),
            onPressed: () => showAppMenu(context),
          ),
          Text(
            'Math IQ',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary),
          ),
          const Spacer(),
          const Icon(Icons.stars_rounded,
              color: AppColors.primary, size: 28),
        ],
      ),
    );
  }
}

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
                  fontSize: 36, fontWeight: FontWeight.w800, color: textColor)),
          Text(sub,
              style:
                  GoogleFonts.beVietnamPro(fontSize: 12, color: subColor)),
        ],
      ),
    );
  }
}

class _InlineStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sub;

  const _InlineStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: iconColor, borderRadius: BorderRadius.circular(999)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                Text(sub,
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Confetti ─────────────────────────────────────────────────────────────────
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
          AppColors.primary,
          AppColors.softOrange,
          AppColors.mintGreen,
          AppColors.secondaryContainer,
          AppColors.mathRed,
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
            _fall.value *
                MediaQuery.of(context).size.height *
                1.2,
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
