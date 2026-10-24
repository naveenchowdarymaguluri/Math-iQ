import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/player_data_service.dart';
import '../widgets/math_progress_bar.dart';
import '../screens/practice_setup_screen.dart';
import '../screens/flag_quiz_screen.dart';
import '../screens/challenge_screen.dart';

// ─── Public helpers ───────────────────────────────────────────────────────────

/// Shows the quick-navigation menu bottom sheet.
void showAppMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.creamBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AppMenuSheet(parentContext: context),
  );
}

/// Shows the player profile bottom sheet.
void showProfileSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.creamBg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _ProfileSheet(),
  );
}

// ─── App menu sheet ───────────────────────────────────────────────────────────
class _AppMenuSheet extends StatelessWidget {
  final BuildContext parentContext;
  const _AppMenuSheet({required this.parentContext});

  void _go(BuildContext sheetCtx, Widget screen) {
    Navigator.pop(sheetCtx);
    Navigator.push(
      parentContext,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Quick Play',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.inkPurple,
            ),
          ),
          Text(
            'Jump straight into the action.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _MenuTile(
            emoji: '🧮',
            title: 'Practice',
            sub: 'Choose operation & difficulty',
            color: AppColors.primary,
            onTap: () => _go(context, const PracticeSetupScreen()),
          ),
          _MenuTile(
            emoji: '🌍',
            title: 'Flag Quiz',
            sub: 'Guess 10 country flags',
            color: const Color(0xFF2EC4B6),
            onTap: () => _go(context, const FlagQuizScreen()),
          ),
          _MenuTile(
            emoji: '⚡',
            title: 'Survival Mode',
            sub: 'Waves & 3 lives — how far can you go?',
            color: AppColors.mathRed,
            onTap: () => _go(context, const ChallengeScreen()),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatefulWidget {
  final String emoji;
  final String title;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuTile({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.color,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            transform: _pressed
                ? Matrix4.translationValues(0, 2, 0)
                : Matrix4.identity(),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: widget.color.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Center(
                    child: Text(widget.emoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        widget.sub,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
        if (widget.showDivider)
          const Divider(
              height: 1, color: AppColors.surfaceContainerHighest),
      ],
    );
  }
}

// ─── Profile sheet ────────────────────────────────────────────────────────────
class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet();

  static String _titleForLevel(int l) {
    if (l < 3) return 'Newcomer';
    if (l < 5) return 'Apprentice';
    if (l < 7) return 'Solver';
    if (l < 10) return 'Math Wizard';
    if (l < 15) return 'Math Master';
    if (l < 20) return 'Grand Wizard';
    if (l < 25) return 'Grand Master';
    return 'Math God ⚡';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerDataService.instance,
      builder: (context, _) {
        final svc = PlayerDataService.instance;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Avatar + level ring
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryFixed,
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.primary,
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.face_rounded,
                        color: AppColors.primary, size: 48),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        'LVL ${svc.level}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                _titleForLevel(svc.level),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkPurple,
                ),
              ),
              if (svc.streakDays > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.softOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppColors.softOrange.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '🔥 ${svc.streakDays}-day streak!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.softOrange,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // XP progress bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryFixed, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level ${svc.level} → ${svc.level + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${svc.xpForNextLevel} XP to go',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    MathProgressBar(value: svc.levelProgress),
                    const SizedBox(height: 6),
                    Text(
                      '${svc.totalXP} XP total',
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats grid (2×3)
              Row(
                children: [
                  _StatBox(
                      label: 'Correct', value: '${svc.totalCorrectEver}'),
                  const SizedBox(width: 10),
                  _StatBox(
                      label: 'Sessions',
                      value: '${svc.recentSessions.length}'),
                  const SizedBox(width: 10),
                  _StatBox(
                      label: 'Best Wave',
                      value: '${svc.bestChallengeWave}'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatBox(label: 'Streak', value: '${svc.streakDays}d'),
                  const SizedBox(width: 10),
                  _StatBox(
                      label: 'Badges',
                      value: '${svc.unlockedAchievements.length}'),
                  const SizedBox(width: 10),
                  _StatBox(
                      label: 'Flag Streak',
                      value: '${svc.bestFlagStreak}'),
                ],
              ),
              const SizedBox(height: 24),

              // Close
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Stat box ─────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.surfaceContainerHighest, width: 2),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
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
        ),
      ),
    );
  }
}
