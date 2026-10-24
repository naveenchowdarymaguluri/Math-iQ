import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/challenge_level.dart';
import '../services/player_data_service.dart';
import '../services/level_service.dart';
import '../widgets/dotted_background.dart';
import '../widgets/math_progress_bar.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_menu_sheet.dart';
import '../widgets/share_card.dart';
import 'practice_setup_screen.dart';
import 'flag_quiz_screen.dart';
import 'daily_quests_screen.dart';
import 'achievements_screen.dart';
import 'level_select_screen.dart';
import 'records_screen.dart';
import 'challenge_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerDataService.instance,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: LevelService.instance,
          builder: (context, _) {
            final svc = PlayerDataService.instance;
            return DottedBackground(
              child: Column(
                children: [
                  _AppBar(xp: svc.totalXP),
                  Expanded(
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroStrip(svc: svc),
                          const SizedBox(height: 20),

                          // ── Quick play ────────────────────────────
                          _QuickPlayRow(),
                          const SizedBox(height: 20),

                          // ── Home banner ad ────────────────────────
                          const AdBanner(placement: 'homeBanner'),
                          const SizedBox(height: 20),

                          // ── Challenge Modes grid ──────────────────
                          _SectionTitle(
                            icon: Icons.grid_view_rounded,
                            title: 'Challenge Levels',
                            sub: '500+ levels across 5 modes',
                          ),
                          const SizedBox(height: 14),
                          _ChallengeModeGrid(),
                          const SizedBox(height: 24),

                          // ── Survival mode banner ──────────────────
                          _SurvivalBanner(),
                          const SizedBox(height: 24),

                          // ── Invite friends ───────────────────────
                          _InviteStrip(),
                          const SizedBox(height: 24),

                          // ── Recent activity ───────────────────────
                          _RecentActivity(svc: svc),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── App bar ─────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final int xp;
  const _AppBar({required this.xp});

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
          boxShadow: [
            BoxShadow(
              color: AppColors.surfaceContainerHighest,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => showAppMenu(context),
                child: const Icon(Icons.menu_rounded,
                    color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 12),
              Text(
                'Math IQ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              // XP badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: AppColors.secondary, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.secondary,
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: AppColors.secondary, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$xp XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => showProfileSheet(context),
                child: const Icon(Icons.account_circle_rounded,
                    color: AppColors.primary, size: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero strip (compact) ────────────────────────────────────────────────────
class _HeroStrip extends StatelessWidget {
  final PlayerDataService svc;
  const _HeroStrip({required this.svc});

  static String _titleForLevel(int l) {
    if (l < 5) return 'Apprentice';
    if (l < 10) return 'Solver';
    if (l < 15) return 'Wizard';
    if (l < 20) return 'Master';
    return 'Grand Master';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primary,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.primary, width: 2.5),
                  color: AppColors.primaryFixed,
                ),
                child: const Icon(Icons.face_rounded,
                    color: AppColors.primary, size: 30),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    'LVL ${svc.level}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      svc.streakDays > 0
                          ? '🔥 ${svc.streakDays}-Day Streak!'
                          : 'Math Learner',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _titleForLevel(svc.level),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${svc.level} → ${svc.level + 1}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      '${svc.xpForNextLevel} XP to go',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                MathProgressBar(value: svc.levelProgress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick play row ───────────────────────────────────────────────────────────
class _QuickPlayRow extends StatelessWidget {
  const _QuickPlayRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickBtn(
            label: 'Practice',
            emoji: '🧮',
            color: AppColors.primary,
            shadowColor: AppColors.onPrimaryFixedVariant,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PracticeSetupScreen())),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _QuickBtn(
            label: 'Flags',
            emoji: '🌍',
            color: const Color(0xFF2EC4B6),
            shadowColor: const Color(0xFF007A73),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const FlagQuizScreen())),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _QuickBtn(
            label: 'Quests',
            emoji: '🗓',
            color: AppColors.softOrange,
            shadowColor: AppColors.tertiary,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DailyQuestsScreen())),
          ),
        ),
      ],
    );
  }
}

class _QuickBtn extends StatefulWidget {
  final String label;
  final String emoji;
  final Color color;
  final Color shadowColor;
  final VoidCallback onTap;
  const _QuickBtn({
    required this.label,
    required this.emoji,
    required this.color,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_QuickBtn> createState() => _QuickBtnState();
}

class _QuickBtnState extends State<_QuickBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(0, 4, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  )
                ],
        ),
        child: Column(
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  const _SectionTitle(
      {required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Challenge mode grid (3 × 2) ──────────────────────────────────────────────
class _ChallengeModeGrid extends StatelessWidget {
  const _ChallengeModeGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.05,
      children: [
        ...ChallengeMode.values.map((mode) => _ModeCard(mode: mode)),
        _RecordsCard(),
      ],
    );
  }
}

class _ModeCard extends StatefulWidget {
  final ChallengeMode mode;
  const _ModeCard({required this.mode});

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final primary = Color(mode.primaryColorValue);
    final svc = LevelService.instance;
    final stars = svc.totalStarsFor(mode);
    final highest = svc.highestPlayedFor(mode);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LevelSelectScreen(mode: mode),
          ),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(0, 6, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.secondaryFixedDim, width: 2),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.secondary,
                    offset: const Offset(0, 6),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Emoji in colored circle
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                          width: 2),
                    ),
                    child: Center(
                      child: Text(mode.emoji,
                          style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mode.displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    mode.opsLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSecondaryContainer
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  if (highest > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded,
                            color: primary, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '$stars★  Lvl $highest',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Color accent bar at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordsCard extends StatefulWidget {
  @override
  State<_RecordsCard> createState() => _RecordsCardState();
}

class _RecordsCardState extends State<_RecordsCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final total = LevelService.instance.grandTotalStars;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RecordsScreen()));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(0, 6, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _pressed
              ? []
              : const [
                  BoxShadow(
                    color: Color(0xFF0A0A14),
                    offset: Offset(0, 6),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📊', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                'Records',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'View All Stats',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              if (total > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '$total / 1500',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Survival mode banner ─────────────────────────────────────────────────────
class _SurvivalBanner extends StatefulWidget {
  @override
  State<_SurvivalBanner> createState() => _SurvivalBannerState();
}

class _SurvivalBannerState extends State<_SurvivalBanner> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bestWave = PlayerDataService.instance.bestChallengeWave;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ChallengeScreen()));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(0, 6, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.mathRed,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _pressed
              ? []
              : const [
                  BoxShadow(
                    color: Color(0xFF960000),
                    offset: Offset(0, 6),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('⚡', style: TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Survival Mode',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '3 lives · waves get harder · how far can you go?',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  if (bestWave > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '🏆 Best: Wave $bestWave',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white60, size: 26),
          ],
        ),
      ),
    );
  }
}

// ─── Recent activity ──────────────────────────────────────────────────────────
class _RecentActivity extends StatelessWidget {
  final PlayerDataService svc;
  const _RecentActivity({required this.svc});

  @override
  Widget build(BuildContext context) {
    final sessions = svc.recentSessions.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.history_rounded,
          title: 'Recent Sessions',
          sub: 'Last ${sessions.length} games',
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.surfaceContainerHighest, width: 2),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.play_circle_outline_rounded,
                      color: AppColors.onSurfaceVariant, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'No sessions yet — start playing!',
                    style: GoogleFonts.beVietnamPro(
                        color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.surfaceContainerHighest, width: 2),
            ),
            child: Column(
              children: sessions.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final accuracy = (s.accuracy * 100).round();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accuracy >= 80
                                  ? AppColors.mintGreen
                                      .withValues(alpha: 0.15)
                                  : AppColors.softOrange
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              accuracy >= 80
                                  ? Icons.check_circle_rounded
                                  : Icons.bolt_rounded,
                              color: accuracy >= 80
                                  ? AppColors.mintGreen
                                  : AppColors.softOrange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.mode,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                Text(
                                  '${s.correct}/${s.total} · $accuracy%',
                                  style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color:
                                          AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '+${s.xpEarned} XP',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < sessions.length - 1)
                      const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.surfaceContainerHighest),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 20),
        // Awards quick link
        _AwardsStrip(),
      ],
    );
  }
}

// ─── Invite / referral strip ──────────────────────────────────────────────────
class _InviteStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = PlayerDataService.instance;
    final canEarn = svc.canEarnShareXP;
    return GestureDetector(
      onTap: () => ShareCard.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4D455D), Color(0xFF705D00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1A1A2E),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    canEarn
                        ? 'Invite Friends — Earn +100 XP each!'
                        : 'Invite Friends to Math IQ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    canEarn
                        ? '${5 - svc.totalShares} reward shares remaining'
                        : 'Help your friends level up their math!',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.share_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Awards strip ─────────────────────────────────────────────────────────────
class _AwardsStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = PlayerDataService.instance;
    final unlocked = svc.unlockedAchievements.length;
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AchievementsScreen())),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inkPurple,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1A1A2E),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$unlocked badges earned — tap to view all',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white54, size: 22),
          ],
        ),
      ),
    );
  }
}
