import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/challenge_level.dart';
import '../services/player_data_service.dart';
import '../services/level_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_menu_sheet.dart';
import '../widgets/dotted_background.dart';

// ─── Sticker catalogue (dynamic unlock conditions) ────────────────────────────
final List<_DynamicSticker> _catalogue = [
  _DynamicSticker(
    id: 'math_mage',
    name: 'Math Mage',
    emoji: '🧙',
    color: AppColors.primary,
    bgColor: AppColors.primaryFixed,
    description: 'Reach Level 5',
    unlockCheck: (p, l) => p.level >= 5,
    progressCalc: (p, l) => p.level / 5,
    progressText: (p, l) => 'Level ${p.level} / 5',
  ),
  _DynamicSticker(
    id: 'star_voyager',
    name: 'Star Voyager',
    emoji: '🚀',
    color: AppColors.softOrange,
    bgColor: const Color(0xFFFFEDD5),
    description: 'Reach Level 10',
    unlockCheck: (p, l) => p.level >= 10,
    progressCalc: (p, l) => p.level / 10,
    progressText: (p, l) => 'Level ${p.level} / 10',
  ),
  _DynamicSticker(
    id: 'speed_king',
    name: 'Speed King',
    emoji: '⚡',
    color: AppColors.secondaryContainer,
    bgColor: const Color(0xFFFFF9C4),
    description: 'Answer 100 questions correctly',
    unlockCheck: (p, l) => p.totalCorrectEver >= 100,
    progressCalc: (p, l) => p.totalCorrectEver / 100,
    progressText: (p, l) => '${p.totalCorrectEver} / 100 correct',
  ),
  _DynamicSticker(
    id: 'globe_trotter',
    name: 'Globe Trotter',
    emoji: '🌍',
    color: const Color(0xFF2EC4B6),
    bgColor: const Color(0xFFE0F7FA),
    description: 'Reach a 10-flag streak',
    unlockCheck: (p, l) => p.bestFlagStreak >= 10,
    progressCalc: (p, l) => p.bestFlagStreak / 10,
    progressText: (p, l) => '${p.bestFlagStreak} / 10 streak',
  ),
  _DynamicSticker(
    id: 'wave_rider',
    name: 'Wave Rider',
    emoji: '🌊',
    color: const Color(0xFF2196F3),
    bgColor: const Color(0xFFE3F2FD),
    description: 'Survive to Wave 5 in Survival Mode',
    unlockCheck: (p, l) => p.bestChallengeWave >= 5,
    progressCalc: (p, l) => p.bestChallengeWave / 5,
    progressText: (p, l) => 'Wave ${p.bestChallengeWave} / 5',
  ),
  _DynamicSticker(
    id: 'beginner_ace',
    name: 'Beginner Ace',
    emoji: '😊',
    color: const Color(0xFF4CAF50),
    bgColor: const Color(0xFFE8F5E9),
    description: 'Complete Level 10 in Beginner mode',
    unlockCheck: (p, l) => l.highestPlayedFor(ChallengeMode.beginner) >= 10,
    progressCalc: (p, l) =>
        l.highestPlayedFor(ChallengeMode.beginner) / 10,
    progressText: (p, l) =>
        'Level ${l.highestPlayedFor(ChallengeMode.beginner)} / 10',
  ),
  _DynamicSticker(
    id: 'explorer_ace',
    name: 'Explorer',
    emoji: '🔭',
    color: const Color(0xFF2196F3),
    bgColor: const Color(0xFFE3F2FD),
    description: 'Complete Level 10 in Explorer mode',
    unlockCheck: (p, l) => l.highestPlayedFor(ChallengeMode.explorer) >= 10,
    progressCalc: (p, l) =>
        l.highestPlayedFor(ChallengeMode.explorer) / 10,
    progressText: (p, l) =>
        'Level ${l.highestPlayedFor(ChallengeMode.explorer)} / 10',
  ),
  _DynamicSticker(
    id: 'challenger',
    name: 'Challenger',
    emoji: '🚩',
    color: const Color(0xFFFF9800),
    bgColor: const Color(0xFFFFF3E0),
    description: 'Complete Level 10 in Challenger mode',
    unlockCheck: (p, l) =>
        l.highestPlayedFor(ChallengeMode.challenger) >= 10,
    progressCalc: (p, l) =>
        l.highestPlayedFor(ChallengeMode.challenger) / 10,
    progressText: (p, l) =>
        'Level ${l.highestPlayedFor(ChallengeMode.challenger)} / 10',
  ),
  _DynamicSticker(
    id: 'master',
    name: 'Master',
    emoji: '🎓',
    color: const Color(0xFF9C27B0),
    bgColor: const Color(0xFFF3E5F5),
    description: 'Complete Level 10 in Master mode',
    unlockCheck: (p, l) => l.highestPlayedFor(ChallengeMode.master) >= 10,
    progressCalc: (p, l) =>
        l.highestPlayedFor(ChallengeMode.master) / 10,
    progressText: (p, l) =>
        'Level ${l.highestPlayedFor(ChallengeMode.master)} / 10',
  ),
  _DynamicSticker(
    id: 'grandmaster',
    name: 'Grandmaster',
    emoji: '👑',
    color: const Color(0xFFE91E63),
    bgColor: const Color(0xFFFCE4EC),
    description: 'Play your first Grandmaster level',
    unlockCheck: (p, l) =>
        l.highestPlayedFor(ChallengeMode.grandmaster) >= 1,
    progressCalc: (p, l) =>
        l.highestPlayedFor(ChallengeMode.grandmaster) > 0 ? 1.0 : 0.0,
    progressText: (p, l) =>
        l.highestPlayedFor(ChallengeMode.grandmaster) >= 1
            ? 'Unlocked!'
            : 'Play Grandmaster',
  ),
  _DynamicSticker(
    id: 'millennium',
    name: 'Millennium Hero',
    emoji: '💯',
    color: const Color(0xFFFFD700),
    bgColor: const Color(0xFFFFF9C4),
    description: 'Answer 1000 questions correctly',
    unlockCheck: (p, l) => p.totalCorrectEver >= 1000,
    progressCalc: (p, l) => p.totalCorrectEver / 1000,
    progressText: (p, l) => '${p.totalCorrectEver} / 1000',
  ),
  _DynamicSticker(
    id: 'xp_legend',
    name: 'XP Legend',
    emoji: '💰',
    color: const Color(0xFFFFD700),
    bgColor: const Color(0xFFFFF8E1),
    description: 'Earn 10,000 total XP',
    unlockCheck: (p, l) => p.totalXP >= 10000,
    progressCalc: (p, l) => p.totalXP / 10000,
    progressText: (p, l) => '${p.totalXP} / 10000 XP',
  ),

  // ── Player levels ────────────────────────────────────────────────────────
  _DynamicSticker(
    id: 'grand_wizard',
    name: 'Grand Wizard',
    emoji: '🔮',
    color: const Color(0xFF8B5CF6),
    bgColor: const Color(0xFFEDE7F6),
    description: 'Reach Level 20',
    unlockCheck: (p, l) => p.level >= 20,
    progressCalc: (p, l) => p.level / 20,
    progressText: (p, l) => 'Level ${p.level} / 20',
  ),
  _DynamicSticker(
    id: 'legend_eagle',
    name: 'Legend',
    emoji: '🦅',
    color: const Color(0xFF1565C0),
    bgColor: const Color(0xFFE3F2FD),
    description: 'Reach Level 30',
    unlockCheck: (p, l) => p.level >= 30,
    progressCalc: (p, l) => p.level / 30,
    progressText: (p, l) => 'Level ${p.level} / 30',
  ),
  _DynamicSticker(
    id: 'immortal_galaxy',
    name: 'Immortal',
    emoji: '🌌',
    color: const Color(0xFF311B92),
    bgColor: const Color(0xFFD1C4E9),
    description: 'Reach Level 50',
    unlockCheck: (p, l) => p.level >= 50,
    progressCalc: (p, l) => p.level / 50,
    progressText: (p, l) => 'Level ${p.level} / 50',
  ),

  // ── Daily streaks ────────────────────────────────────────────────────────
  _DynamicSticker(
    id: 'hat_trick',
    name: 'Hat-Trick',
    emoji: '🔥',
    color: const Color(0xFFFF6B6B),
    bgColor: const Color(0xFFFFEBEE),
    description: 'Play 3 days in a row',
    unlockCheck: (p, l) => p.streakDays >= 3,
    progressCalc: (p, l) => p.streakDays / 3,
    progressText: (p, l) => '${p.streakDays} / 3 days',
  ),
  _DynamicSticker(
    id: 'hot_streak',
    name: 'Hot Streak',
    emoji: '☄️',
    color: const Color(0xFFE63946),
    bgColor: const Color(0xFFFFE5E5),
    description: 'Keep a 7-day streak',
    unlockCheck: (p, l) => p.streakDays >= 7,
    progressCalc: (p, l) => p.streakDays / 7,
    progressText: (p, l) => '${p.streakDays} / 7 days',
  ),
  _DynamicSticker(
    id: 'dedication',
    name: 'Dedication',
    emoji: '💫',
    color: const Color(0xFFFF9500),
    bgColor: const Color(0xFFFFF3E0),
    description: 'Keep a 30-day streak',
    unlockCheck: (p, l) => p.streakDays >= 30,
    progressCalc: (p, l) => p.streakDays / 30,
    progressText: (p, l) => '${p.streakDays} / 30 days',
  ),

  // ── Correct answers ──────────────────────────────────────────────────────
  _DynamicSticker(
    id: 'sharp_mind',
    name: 'Sharp Mind',
    emoji: '🎯',
    color: const Color(0xFF8B5CF6),
    bgColor: const Color(0xFFEDE7F6),
    description: 'Answer 250 questions correctly',
    unlockCheck: (p, l) => p.totalCorrectEver >= 250,
    progressCalc: (p, l) => p.totalCorrectEver / 250,
    progressText: (p, l) => '${p.totalCorrectEver} / 250 correct',
  ),
  _DynamicSticker(
    id: 'calculator',
    name: 'Calculator',
    emoji: '🖥️',
    color: const Color(0xFF2EC4B6),
    bgColor: const Color(0xFFE0F7FA),
    description: 'Answer 5000 questions correctly',
    unlockCheck: (p, l) => p.totalCorrectEver >= 5000,
    progressCalc: (p, l) => p.totalCorrectEver / 5000,
    progressText: (p, l) => '${p.totalCorrectEver} / 5000 correct',
  ),

  // ── Flag quiz & survival ─────────────────────────────────────────────────
  _DynamicSticker(
    id: 'flag_master',
    name: 'Flag Master',
    emoji: '🌐',
    color: const Color(0xFF00897B),
    bgColor: const Color(0xFFE0F2F1),
    description: 'Reach a 25-flag streak',
    unlockCheck: (p, l) => p.bestFlagStreak >= 25,
    progressCalc: (p, l) => p.bestFlagStreak / 25,
    progressText: (p, l) => '${p.bestFlagStreak} / 25 streak',
  ),
  _DynamicSticker(
    id: 'storm_surfer',
    name: 'Storm Surfer',
    emoji: '🌀',
    color: const Color(0xFF0D47A1),
    bgColor: const Color(0xFFE3F2FD),
    description: 'Survive to Wave 10 in Survival Mode',
    unlockCheck: (p, l) => p.bestChallengeWave >= 10,
    progressCalc: (p, l) => p.bestChallengeWave / 10,
    progressText: (p, l) => 'Wave ${p.bestChallengeWave} / 10',
  ),

  // ── Sessions ─────────────────────────────────────────────────────────────
  _DynamicSticker(
    id: 'dedicated_player',
    name: 'Dedicated',
    emoji: '📖',
    color: const Color(0xFF4527A0),
    bgColor: const Color(0xFFEDE7F6),
    description: 'Play 50 total sessions',
    unlockCheck: (p, l) => p.totalSessionsEver >= 50,
    progressCalc: (p, l) => p.totalSessionsEver / 50,
    progressText: (p, l) => '${p.totalSessionsEver} / 50 sessions',
  ),
  _DynamicSticker(
    id: 'veteran',
    name: 'Veteran',
    emoji: '🎖️',
    color: const Color(0xFF2E7D32),
    bgColor: const Color(0xFFE8F5E9),
    description: 'Play 200 total sessions',
    unlockCheck: (p, l) => p.totalSessionsEver >= 200,
    progressCalc: (p, l) => p.totalSessionsEver / 200,
    progressText: (p, l) => '${p.totalSessionsEver} / 200 sessions',
  ),

  // ── XP milestones ────────────────────────────────────────────────────────
  _DynamicSticker(
    id: 'point_scorer',
    name: 'Point Scorer',
    emoji: '🪙',
    color: const Color(0xFFF9A825),
    bgColor: const Color(0xFFFFF8E1),
    description: 'Earn 1,000 total XP',
    unlockCheck: (p, l) => p.totalXP >= 1000,
    progressCalc: (p, l) => p.totalXP / 1000,
    progressText: (p, l) => '${p.totalXP} / 1000 XP',
  ),
  _DynamicSticker(
    id: 'elite',
    name: 'Elite',
    emoji: '🏆',
    color: const Color(0xFFFF6F00),
    bgColor: const Color(0xFFFFF3E0),
    description: 'Earn 25,000 total XP',
    unlockCheck: (p, l) => p.totalXP >= 25000,
    progressCalc: (p, l) => p.totalXP / 25000,
    progressText: (p, l) => '${p.totalXP} / 25000 XP',
  ),

  // ── Social / referral ────────────────────────────────────────────────────
  _DynamicSticker(
    id: 'ambassador',
    name: 'Ambassador',
    emoji: '📣',
    color: const Color(0xFFE91E63),
    bgColor: const Color(0xFFFCE4EC),
    description: 'Share Math IQ with 3 friends',
    unlockCheck: (p, l) => p.totalShares >= 3,
    progressCalc: (p, l) => p.totalShares / 3,
    progressText: (p, l) => '${p.totalShares} / 3 shares',
  ),
  _DynamicSticker(
    id: 'superstar',
    name: 'Superstar',
    emoji: '🚀',
    color: const Color(0xFF6200EA),
    bgColor: const Color(0xFFEDE7F6),
    description: 'Share Math IQ 10 times',
    unlockCheck: (p, l) => p.totalShares >= 10,
    progressCalc: (p, l) => p.totalShares / 10,
    progressText: (p, l) => '${p.totalShares} / 10 shares',
  ),

  // ── Stars ────────────────────────────────────────────────────────────────
  _DynamicSticker(
    id: 'star_hoarder',
    name: 'Star Hoarder',
    emoji: '⭐',
    color: const Color(0xFFFFD700),
    bgColor: const Color(0xFFFFF9C4),
    description: 'Earn 150 stars across all Challenge Modes',
    unlockCheck: (p, l) => _totalStars(l) >= 150,
    progressCalc: (p, l) => _totalStars(l) / 150,
    progressText: (p, l) => '${_totalStars(l)} / 150 stars',
  ),
];

int _totalStars(LevelService l) =>
    ChallengeMode.values.fold(0, (sum, m) => sum + l.totalStarsFor(m));

class _DynamicSticker {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final Color bgColor;
  final String description;
  final bool Function(PlayerDataService, LevelService) unlockCheck;
  final double Function(PlayerDataService, LevelService) progressCalc;
  final String Function(PlayerDataService, LevelService) progressText;

  const _DynamicSticker({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.description,
    required this.unlockCheck,
    required this.progressCalc,
    required this.progressText,
  });

  bool isUnlocked(PlayerDataService p, LevelService l) => unlockCheck(p, l);
  double progress(PlayerDataService p, LevelService l) =>
      isUnlocked(p, l) ? 1.0 : progressCalc(p, l).clamp(0.0, 0.99);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class StickerBookScreen extends StatelessWidget {
  const StickerBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerDataService.instance,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: LevelService.instance,
          builder: (context, _) {
            final p = PlayerDataService.instance;
            final l = LevelService.instance;
            final total = _catalogue.length;
            final collected = _catalogue.where((s) => s.isUnlocked(p, l)).length;
            final latestUnlocked = _catalogue
                .where((s) => s.isUnlocked(p, l))
                .toList()
                .reversed
                .firstOrNull;

            return DottedBackground(
              child: Column(
                children: [
                  _StickerAppBar(collected: collected, total: total),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress bar
                          _ProgressCard(collected: collected, total: total),
                          const SizedBox(height: 20),

                          // Featured (latest unlock or next to unlock)
                          if (latestUnlocked != null) ...[
                            _FeaturedCard(sticker: latestUnlocked, p: p, l: l),
                            const SizedBox(height: 20),
                          ] else ...[
                            _NextUnlockCard(p: p, l: l),
                            const SizedBox(height: 20),
                          ],

                          // How to earn hint
                          if (collected < total) ...[
                            _NextUnlockHint(p: p, l: l),
                            const SizedBox(height: 20),
                          ],

                          // Collected section
                          if (collected > 0) ...[
                            _SectionHeader(
                              label: 'COLLECTED',
                              count: '$collected',
                              color: AppColors.mintGreen,
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _catalogue
                                  .where((s) => s.isUnlocked(p, l))
                                  .length,
                              itemBuilder: (_, i) {
                                final sticker = _catalogue
                                    .where((s) => s.isUnlocked(p, l))
                                    .toList()[i];
                                return _StickerTile(
                                  sticker: sticker,
                                  p: p,
                                  l: l,
                                  collected: true,
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Locked section
                          if (collected < total) ...[
                            _SectionHeader(
                              label: 'LOCKED',
                              count: '${total - collected}',
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _catalogue
                                  .where((s) => !s.isUnlocked(p, l))
                                  .length,
                              itemBuilder: (_, i) {
                                final sticker = _catalogue
                                    .where((s) => !s.isUnlocked(p, l))
                                    .toList()[i];
                                return _StickerTile(
                                  sticker: sticker,
                                  p: p,
                                  l: l,
                                  collected: false,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const AdBanner(placement: 'stickerBanner'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────
class _StickerAppBar extends StatelessWidget {
  final int collected;
  final int total;
  const _StickerAppBar({required this.collected, required this.total});

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
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 28),
              onPressed: () => showAppMenu(context),
            ),
            Text('Math IQ',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: AppColors.secondary, width: 2),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.secondary,
                      offset: Offset(0, 3),
                      blurRadius: 0)
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 18,
                      color: AppColors.onSecondaryContainer),
                  const SizedBox(width: 6),
                  Text('$collected / $total',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSecondaryContainer)),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Progress card ────────────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final int collected;
  final int total;
  const _ProgressCard({required this.collected, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sticker Book',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkPurple),
            ),
            const Spacer(),
            Text(
              'Collect them all!',
              style: GoogleFonts.beVietnamPro(
                  fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.primaryFixed, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Collection Progress',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primary)),
                  Text('$collected/$total stickers',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: collected / total,
                  minHeight: 14,
                  backgroundColor:
                      AppColors.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation(
                      AppColors.secondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Featured card (latest unlock) ───────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final _DynamicSticker sticker;
  final PlayerDataService p;
  final LevelService l;
  const _FeaturedCard(
      {required this.sticker, required this.p, required this.l});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.primary,
                  offset: Offset(4, 4),
                  blurRadius: 0)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: sticker.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sticker.color.withValues(alpha: 0.35),
                      width: 2),
                ),
                child: Center(
                  child: Text(sticker.emoji,
                      style: const TextStyle(fontSize: 38)),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sticker.name,
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('Latest Unlock',
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: AppColors.mintGreen, width: 1),
                    ),
                    child: Text('✨ Collected!',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mintGreen)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: -10,
          right: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.secondary,
                    offset: Offset(0, 2),
                    blurRadius: 0)
              ],
            ),
            child: Text('NEW!',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSecondaryContainer)),
          ),
        ),
      ],
    );
  }
}

// ─── Next unlock card (when nothing collected yet) ────────────────────────────
class _NextUnlockCard extends StatelessWidget {
  final PlayerDataService p;
  final LevelService l;
  const _NextUnlockCard({required this.p, required this.l});

  @override
  Widget build(BuildContext context) {
    final next = _catalogue
        .where((s) => !s.isUnlocked(p, l) && s.progress(p, l) > 0)
        .toList();
    final s = next.isNotEmpty ? next.first : _catalogue.first;
    final prog = s.progress(p, l);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.color.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: s.color.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next: ${s.name}',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      s.description,
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.progressText(p, l),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: s.color)),
              Text('${(prog * 100).round()}%',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: s.color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: prog,
              minHeight: 10,
              backgroundColor: s.color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(s.color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Next unlock hint ─────────────────────────────────────────────────────────
class _NextUnlockHint extends StatelessWidget {
  final PlayerDataService p;
  final LevelService l;
  const _NextUnlockHint({required this.p, required this.l});

  @override
  Widget build(BuildContext context) {
    final nextList = _catalogue
        .where((s) => !s.isUnlocked(p, l))
        .toList()
      ..sort(
          (a, b) => b.progress(p, l).compareTo(a.progress(p, l)));
    if (nextList.isEmpty) return const SizedBox.shrink();
    final s = nextList.first;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.surfaceContainerHighest, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Almost there! ${s.progressText(p, l)} to unlock ${s.name} ${s.emoji}',
              style: GoogleFonts.beVietnamPro(
                  fontSize: 12, color: AppColors.onSurface, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  const _SectionHeader(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: color)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(count,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }
}

// ─── Sticker tile ─────────────────────────────────────────────────────────────
class _StickerTile extends StatefulWidget {
  final _DynamicSticker sticker;
  final PlayerDataService p;
  final LevelService l;
  final bool collected;

  const _StickerTile({
    required this.sticker,
    required this.p,
    required this.l,
    required this.collected,
  });

  @override
  State<_StickerTile> createState() => _StickerTileState();
}

class _StickerTileState extends State<_StickerTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sticker;
    final prog = s.progress(widget.p, widget.l);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showDetail(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(0, 4, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.collected
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.collected
                ? AppColors.secondary
                : AppColors.surfaceContainerHighest,
            width: 2,
          ),
          boxShadow: widget.collected && !_pressed
              ? const [
                  BoxShadow(
                      color: AppColors.secondary,
                      offset: Offset(0, 4),
                      blurRadius: 0)
                ]
              : [],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.collected
                ? Text(s.emoji, style: const TextStyle(fontSize: 34))
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(s.emoji,
                          style: TextStyle(
                              fontSize: 34,
                              color: Colors.black
                                  .withValues(alpha: 0.08))),
                      const Icon(Icons.lock_rounded,
                          size: 22,
                          color: AppColors.outlineVariant),
                    ],
                  ),
            const SizedBox(height: 6),
            Text(
              widget.collected ? s.name : '???',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: widget.collected
                    ? s.color
                    : AppColors.outlineVariant,
              ),
            ),
            // Progress mini-bar for locked stickers
            if (!widget.collected && prog > 0) ...[
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: prog,
                  minHeight: 4,
                  backgroundColor: s.color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(s.color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext ctx) {
    final s = widget.sticker;
    final prog = s.progress(widget.p, widget.l);
    final collected = widget.collected;

    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: collected ? s.bgColor : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: collected
                      ? s.color.withValues(alpha: 0.4)
                      : const Color(0xFFE0E0E0),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  collected ? s.emoji : '🔒',
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(s.name,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(s.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                    fontSize: 13, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 20),
            if (!collected) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(s.progressText(widget.p, widget.l),
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: s.color)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: prog,
                  minHeight: 12,
                  backgroundColor: s.color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(s.color),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
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
                    Text('Sticker Unlocked!',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: s.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  collected ? 'Awesome! 🎉' : 'Keep Playing!',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
