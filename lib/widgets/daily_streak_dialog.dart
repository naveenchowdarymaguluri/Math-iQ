import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/daily_streak_reward.dart';
import '../services/player_data_service.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import 'tactile_button.dart';

/// Shows the modal daily streak reward sheet.
Future<void> showDailyStreakDialog(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const DailyStreakSheet(),
  );
}

class DailyStreakSheet extends StatefulWidget {
  const DailyStreakSheet({super.key});

  @override
  State<DailyStreakSheet> createState() => _DailyStreakSheetState();
}

class _DailyStreakSheetState extends State<DailyStreakSheet> {
  DailyStreakClaimResult? _claimResult;
  bool _isClaiming = false;

  Future<void> _handleClaim(PlayerDataService svc) async {
    if (_isClaiming || !svc.canClaimDailyReward) return;

    setState(() => _isClaiming = true);
    SoundService.instance.play(SoundType.levelUp);

    final result = await svc.claimDailyStreakReward();
    if (mounted) {
      setState(() {
        _claimResult = result;
        _isClaiming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = PlayerDataService.instance;
    final canClaim = svc.canClaimDailyReward;
    final nextDayToClaim = svc.nextStreakDayToClaim;
    final currentStreak = svc.streakDays;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.primary, width: 3),
          left: BorderSide(color: AppColors.primary, width: 3),
          right: BorderSide(color: AppColors.primary, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary,
            offset: Offset(0, -4),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header Row
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.softOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.softOrange, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '$currentStreak Day Streak',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.softOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title & Subtitle
              Text(
                'Daily Streak Rewards',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check in every single day to unlock scaling XP rewards and claim the Grand Chest on Day 7!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // Celebration banner if just claimed
              if (_claimResult != null) ...[
                _ClaimSuccessCard(result: _claimResult!),
                const SizedBox(height: 18),
              ],

              // 7-Day Cycle Grid
              _CycleGrid(
                svc: svc,
                claimedResult: _claimResult,
                targetDay: nextDayToClaim,
                canClaim: canClaim,
              ),
              const SizedBox(height: 18),

              // Milestone Tracker Strip
              _MilestoneStrip(streakDays: svc.streakDays),
              const SizedBox(height: 20),

              // Action button
              if (canClaim)
                TactileButton(
                  color: AppColors.secondaryContainer,
                  shadowColor: AppColors.secondary,
                  borderRadius: 16,
                  border: Border.all(color: AppColors.secondary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: () => _handleClaim(svc),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.card_giftcard_rounded,
                          color: AppColors.onSecondaryContainer, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Claim Day $nextDayToClaim Reward (+${DailyStreakReward.xpForDay(nextDayToClaim)} XP)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.surfaceContainerHighest, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.mintGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Today\'s Reward Claimed! Come back tomorrow.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 7-Day Grid ─────────────────────────────────────────────────────────────
class _CycleGrid extends StatelessWidget {
  final PlayerDataService svc;
  final DailyStreakClaimResult? claimedResult;
  final int targetDay;
  final bool canClaim;

  const _CycleGrid({
    required this.svc,
    required this.claimedResult,
    required this.targetDay,
    required this.canClaim,
  });

  @override
  Widget build(BuildContext context) {
    final cycle = DailyStreakReward.weeklyCycle;
    final currentCycleDay = svc.currentStreakDayInCycle;
    final isAlreadyClaimedToday = !svc.canClaimDailyReward;

    // Days 1..6
    final days1To6 = cycle.sublist(0, 6);
    final day7 = cycle[6];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemCount: days1To6.length,
          itemBuilder: (context, index) {
            final reward = days1To6[index];
            final day = reward.day;

            // Determine status
            bool isClaimed = false;
            bool isTodayReady = false;

            if (isAlreadyClaimedToday) {
              if (day <= currentCycleDay) {
                isClaimed = true;
              }
            } else {
              if (day < targetDay) {
                isClaimed = true;
              } else if (day == targetDay) {
                isTodayReady = true;
              }
            }

            return _DayCard(
              reward: reward,
              isClaimed: isClaimed,
              isTodayReady: isTodayReady,
            );
          },
        ),
        const SizedBox(height: 10),

        // Day 7 Featured Card
        _Day7Card(
          reward: day7,
          isClaimed: isAlreadyClaimedToday && currentCycleDay == 7,
          isTodayReady: !isAlreadyClaimedToday && targetDay == 7,
        ),
      ],
    );
  }
}

// ─── Individual Day Card (Days 1–6) ──────────────────────────────────────────
class _DayCard extends StatelessWidget {
  final DailyStreakReward reward;
  final bool isClaimed;
  final bool isTodayReady;

  const _DayCard({
    required this.reward,
    required this.isClaimed,
    required this.isTodayReady,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isTodayReady
        ? AppColors.secondaryFixed.withValues(alpha: 0.35)
        : isClaimed
            ? AppColors.mintGreen.withValues(alpha: 0.12)
            : AppColors.surfaceContainerLowest;

    final borderColor = isTodayReady
        ? AppColors.secondary
        : isClaimed
            ? AppColors.mintGreen
            : AppColors.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isTodayReady ? 2.5 : 2,
        ),
        boxShadow: isTodayReady
            ? const [
                BoxShadow(
                  color: AppColors.secondary,
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Day ${reward.day}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isTodayReady
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (isClaimed)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.mintGreen, size: 26)
          else if (isTodayReady)
            const Text('🎁', style: TextStyle(fontSize: 24))
          else
            const Icon(Icons.lock_outline_rounded,
                color: AppColors.outlineVariant, size: 24),
          const SizedBox(height: 4),
          Text(
            '+${reward.xp} XP',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isTodayReady
                  ? AppColors.secondary
                  : isClaimed
                      ? AppColors.mintGreen
                      : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Day 7 Featured Card ─────────────────────────────────────────────────────
class _Day7Card extends StatelessWidget {
  final DailyStreakReward reward;
  final bool isClaimed;
  final bool isTodayReady;

  const _Day7Card({
    required this.reward,
    required this.isClaimed,
    required this.isTodayReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isTodayReady
            ? AppColors.secondaryFixed.withValues(alpha: 0.4)
            : isClaimed
                ? AppColors.mintGreen.withValues(alpha: 0.15)
                : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTodayReady
              ? AppColors.secondary
              : isClaimed
                  ? AppColors.mintGreen
                  : AppColors.secondaryFixedDim,
          width: 2.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.secondary,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary, width: 2),
            ),
            child: const Center(
              child: Text('👑', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Day 7: Grand Weekly Chest',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'MEGA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'The ultimate weekly milestone bonus!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${reward.xp} XP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                ),
              ),
              if (isClaimed)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.mintGreen, size: 20)
              else if (isTodayReady)
                Text(
                  'TODAY!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.softOrange,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Milestone Tracker Strip ─────────────────────────────────────────────────
class _MilestoneStrip extends StatelessWidget {
  final int streakDays;
  const _MilestoneStrip({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    // Milestones: 14, 30, 60, 100
    int nextMilestone = 14;
    int milestoneReward = 150;
    if (streakDays >= 60) {
      nextMilestone = 100;
      milestoneReward = 1200;
    } else if (streakDays >= 30) {
      nextMilestone = 60;
      milestoneReward = 600;
    } else if (streakDays >= 14) {
      nextMilestone = 30;
      milestoneReward = 300;
    }

    final daysRemaining = (nextMilestone - streakDays).clamp(0, 100);
    final progress = (streakDays / nextMilestone).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_rounded,
                  color: AppColors.softOrange, size: 18),
              const SizedBox(width: 6),
              Text(
                'Next Milestone: $nextMilestone Days (+$milestoneReward Bonus XP)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                daysRemaining == 0
                    ? 'Achieved!'
                    : '$daysRemaining days to go',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.softOrange),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Claim Success Celebration Card ──────────────────────────────────────────
class _ClaimSuccessCard extends StatelessWidget {
  final DailyStreakClaimResult result;
  const _ClaimSuccessCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.mintGreen, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.mintGreen,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reward Claimed! +${result.totalRewardXP} XP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.milestoneName != null
                      ? 'Includes ${result.milestoneName}! Streak extended to ${result.streakDays} days! 🔥'
                      : 'Streak extended to ${result.streakDays} days! Keep the flame alive tomorrow! 🔥',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
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
