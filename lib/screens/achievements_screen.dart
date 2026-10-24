import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/achievement.dart';
import '../models/challenge_level.dart';
import '../services/player_data_service.dart';
import '../services/level_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/dotted_background.dart';
import '../widgets/math_progress_bar.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerDataService.instance,
      builder: (context, _) {
        final svc = PlayerDataService.instance;
        final unlocked = svc.unlockedAchievements;
        final unlockedList =
            Achievement.all.where((a) => unlocked.contains(a.id)).toList();
        final lockedList =
            Achievement.all.where((a) => !unlocked.contains(a.id)).toList();
        final progress = _buildProgress(svc);

        return DottedBackground(
          child: Column(
            children: [
              _AchievementsAppBar(),
              // ── Summary card ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SummaryCard(
                  unlocked: unlockedList.length,
                  total: Achievement.all.length,
                  xp: svc.totalXP,
                  level: svc.level,
                ),
              ),
              const SizedBox(height: 12),
              // ── Tabs ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.surfaceContainerHighest, width: 2),
                  ),
                  child: TabBar(
                    controller: _tab,
                    labelStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500, fontSize: 13),
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.onSurfaceVariant,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'All (${Achievement.all.length})'),
                      Tab(text: 'Earned (${unlockedList.length})'),
                      Tab(text: 'Locked (${lockedList.length})'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // ── Tab content ───────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // All
                    _AchievementList(
                      items: Achievement.all,
                      unlocked: unlocked,
                      progress: progress,
                    ),
                    // Earned
                    _AchievementList(
                      items: unlockedList,
                      unlocked: unlocked,
                      progress: progress,
                    ),
                    // Locked
                    _AchievementList(
                      items: lockedList,
                      unlocked: unlocked,
                      progress: progress,
                    ),
                  ],
                ),
              ),
              const AdBanner(placement: 'achievementsBanner'),
            ],
          ),
        );
      },
    );
  }

  /// Build progress fractions 0.0–1.0 for each achievement ID.
  Map<String, double> _buildProgress(PlayerDataService svc) {
    final lvlSvc = LevelService.instance;
    return {
      'first_win': svc.recentSessions.isNotEmpty ? 1.0 : 0.0,
      'perfect_score': svc.recentSessions
              .any((s) => s.isPerfect && s.total >= 10)
          ? 1.0
          : 0.0,
      'century': (svc.totalCorrectEver / 100).clamp(0.0, 1.0),
      'millennium': (svc.totalCorrectEver / 1000).clamp(0.0, 1.0),
      'streak_3': (svc.streakDays / 3).clamp(0.0, 1.0),
      'streak_7': (svc.streakDays / 7).clamp(0.0, 1.0),
      'streak_30': (svc.streakDays / 30).clamp(0.0, 1.0),
      'level_5': (svc.level / 5).clamp(0.0, 1.0),
      'level_10': (svc.level / 10).clamp(0.0, 1.0),
      'level_20': (svc.level / 20).clamp(0.0, 1.0),
      'flag_expert': (svc.bestFlagStreak / 10).clamp(0.0, 1.0),
      'flag_master': (svc.bestFlagStreak / 25).clamp(0.0, 1.0),
      'combo_5': svc.recentSessions
              .any((s) => s.highestStreak >= 5)
          ? 1.0
          : 0.0,
      'daily_all': svc.questClaimed.every((c) => c) ? 1.0 : 0.0,
      'xp_10000': (svc.totalXP / 10000).clamp(0.0, 1.0),
      'speed_demon': 0.0, // tracked in-game
      'beginner_25': (lvlSvc.highestPlayedFor(
                  ChallengeMode.values.first) /
              25)
          .clamp(0.0, 1.0),
      'explorer_25': (lvlSvc.highestPlayedFor(
                  ChallengeMode.values[1]) /
              25)
          .clamp(0.0, 1.0),
      'grandmaster_1': lvlSvc.highestPlayedFor(
                  ChallengeMode.values.last) >=
              1
          ? 1.0
          : 0.0,
      'all_stars': (lvlSvc.grandTotalStars / 1500).clamp(0.0, 1.0),
    };
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────
class _AchievementsAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.creamBg,
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Text(
              'Achievements',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
            const Spacer(),
            const Text('🏅', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int unlocked;
  final int total;
  final int xp;
  final int level;
  const _SummaryCard(
      {required this.unlocked,
      required this.total,
      required this.xp,
      required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [
          BoxShadow(
              color: AppColors.primary,
              offset: Offset(4, 4),
              blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$unlocked / $total Earned',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Keep playing to unlock more!',
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.secondary,
                        offset: Offset(0, 3),
                        blurRadius: 0)
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: AppColors.onSecondaryContainer, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MathProgressBar(value: total > 0 ? unlocked / total : 0),
          const SizedBox(height: 14),
          // Stat chips
          Row(
            children: [
              _Chip(label: '$xp XP', icon: Icons.stars_rounded,
                  color: AppColors.secondaryContainer,
                  textColor: AppColors.onSecondaryContainer),
              const SizedBox(width: 8),
              _Chip(label: 'Level $level', icon: Icons.trending_up_rounded,
                  color: AppColors.primaryFixed,
                  textColor: AppColors.onPrimaryFixed),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  const _Chip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
        ],
      ),
    );
  }
}

// ─── Achievement list ─────────────────────────────────────────────────────────
class _AchievementList extends StatelessWidget {
  final List<Achievement> items;
  final Set<String> unlocked;
  final Map<String, double> progress;

  const _AchievementList({
    required this.items,
    required this.unlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Nothing here yet!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              'Keep playing to earn achievements.',
              style: GoogleFonts.beVietnamPro(
                  color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = items[i];
        final isUnlocked = unlocked.contains(a.id);
        final prog = progress[a.id] ?? 0.0;
        return _AchievementTile(
          achievement: a,
          isUnlocked: isUnlocked,
          progress: prog,
          onTap: () => _showDetail(context, a, isUnlocked, prog),
        );
      },
    );
  }

  void _showDetail(BuildContext context, Achievement a, bool isUnlocked,
      double prog) {
    final accent = Color(a.colorValue);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? accent.withValues(alpha: 0.15)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isUnlocked ? accent : const Color(0xFFE0E0E0),
                    width: 2),
              ),
              child: Center(
                child: Text(
                  isUnlocked ? a.iconEmoji : '🔒',
                  style: const TextStyle(fontSize: 34),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              a.title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              a.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            if (!isUnlocked && prog > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('${(prog * 100).round()}%',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: accent)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: prog,
                  minHeight: 10,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF4CAF50), size: 20),
                    const SizedBox(width: 8),
                    Text('Achievement Unlocked!',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Achievement tile (interactive) ──────────────────────────────────────────
class _AchievementTile extends StatefulWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final double progress; // 0.0 – 1.0
  final VoidCallback onTap;

  const _AchievementTile({
    required this.achievement,
    required this.isUnlocked,
    required this.progress,
    required this.onTap,
  });

  @override
  State<_AchievementTile> createState() => _AchievementTileState();
}

class _AchievementTileState extends State<_AchievementTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnim = Tween<double>(begin: 0, end: widget.progress)
        .animate(CurvedAnimation(
            parent: _progressCtrl, curve: Curves.easeOut));
    // Delay to let the list settle
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _progressCtrl.forward();
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    final accent = Color(a.colorValue);
    final isUnlocked = widget.isUnlocked;

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
            ? Matrix4.translationValues(0, 2, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? accent.withValues(alpha: 0.45)
                : AppColors.surfaceContainerHighest,
            width: 2,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.22),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? accent.withValues(alpha: 0.13)
                        : AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      isUnlocked ? a.iconEmoji : '🔒',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isUnlocked
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        a.description,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isUnlocked)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.mintGreen, size: 22)
                else
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.onSurfaceVariant
                          .withValues(alpha: 0.4),
                      size: 20),
              ],
            ),
            // Progress bar for locked (only show if some progress made)
            if (!isUnlocked && widget.progress > 0) ...[
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${(_progressAnim.value * 100).round()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _progressAnim.value,
                          minHeight: 6,
                          backgroundColor: accent.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

