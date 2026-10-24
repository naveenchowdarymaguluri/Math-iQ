import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/daily_quest.dart';
import '../services/player_data_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/dotted_background.dart';
import '../widgets/math_progress_bar.dart';
import '../widgets/tactile_button.dart';
import 'practice_setup_screen.dart';

class DailyQuestsScreen extends StatefulWidget {
  const DailyQuestsScreen({super.key});

  @override
  State<DailyQuestsScreen> createState() => _DailyQuestsScreenState();
}

class _DailyQuestsScreenState extends State<DailyQuestsScreen> {
  late int _secondsLeft;
  Timer? _timer;

  static int _secondsUntilMidnight() {
    final now = DateTime.now();
    final midnight =
        DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now).inSeconds;
  }

  @override
  void initState() {
    super.initState();
    _secondsLeft = _secondsUntilMidnight();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          // Past midnight — recalculate
          _secondsLeft = _secondsUntilMidnight();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final h = _secondsLeft ~/ 3600;
    final m = (_secondsLeft % 3600) ~/ 60;
    final s = _secondsLeft % 60;
    return 'Ends in ${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerDataService.instance,
      builder: (context, _) {
        final svc = PlayerDataService.instance;
        final quests = svc.todayQuestsWithProgress;
        final completedCount =
            quests.where((q) => q.completed).length;

        return DottedBackground(
          child: Column(
            children: [
              _AppBar(timerText: _timerText),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Quests',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fresh quests every day. Claim XP rewards!',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),

                      // Quest cards
                      ...quests.asMap().entries.map(
                            (e) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 16),
                              child: _QuestCard(
                                quest: e.value,
                                index: e.key,
                              ),
                            ),
                          ),

                      const SizedBox(height: 8),

                      // Summary row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.tertiary,
                                borderRadius:
                                    BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                      color:
                                          AppColors.tertiaryContainer,
                                      offset: Offset(0, 4),
                                      blurRadius: 0)
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                      Icons.military_tech_rounded,
                                      color: Colors.white,
                                      size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$completedCount/${quests.length}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white),
                                  ),
                                  Text('Done Today',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.surfaceContainerLowest,
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors
                                        .surfaceContainerHighest,
                                    width: 2),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Weekly Activity',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.inkPurple,
                                          fontSize: 13)),
                                  const SizedBox(height: 10),
                                  // Row 1: Mon–Thu (indices 0–3)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(4, (i) {
                                      final done = svc.weekActivity[i];
                                      const days = ['M', 'T', 'W', 'T'];
                                      return _DayDot(
                                          label: days[i], done: done);
                                    }),
                                  ),
                                  const SizedBox(height: 6),
                                  // Row 2: Fri–Sun (indices 4–6)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(3, (i) {
                                      final done =
                                          svc.weekActivity[4 + i];
                                      const days = ['F', 'S', 'S'];
                                      return _DayDot(
                                          label: days[i], done: done);
                                    }),
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
              const AdBanner(placement: 'dailyQuestsBanner'),
            ],
          ),
        );
      },
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final String timerText;
  const _AppBar({required this.timerText});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.creamBg,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(Icons.face_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Math IQ',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.tertiaryFixed,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: AppColors.tertiaryFixedDim, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: AppColors.tertiary),
                  const SizedBox(width: 4),
                  Text(timerText,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quest card ───────────────────────────────────────────────────────────────
class _QuestCard extends StatelessWidget {
  final DailyQuest quest;
  final int index;
  const _QuestCard({required this.quest, required this.index});

  Color get _borderColor => switch (quest.status) {
        QuestStatus.completed => AppColors.mintGreen,
        QuestStatus.inProgress => AppColors.primaryContainer,
        QuestStatus.locked => AppColors.softOrange,
      };

  @override
  Widget build(BuildContext context) {
    final iconColor = Color(quest.colorValue);
    final iconBg = iconColor.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: _borderColor.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: iconColor.withValues(alpha: 0.4),
                      width: 2),
                ),
                child: Icon(_questIcon(quest.iconName),
                    color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.title,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.onSurface)),
                    Text(quest.subtitle,
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              // XP reward badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: iconColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '+${quest.xpReward} XP',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: iconColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _statusLabel(quest.status),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                    letterSpacing: 1),
              ),
              Text(
                quest.type == QuestType.perfectScore ||
                        quest.type == QuestType.flagQuiz
                    ? (quest.completed ? 'Done!' : 'Not yet')
                    : '${quest.progress}/${quest.target}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          MathProgressBar(
            value: quest.fraction,
            fillColor: iconColor,
            height: 14,
          ),
          const SizedBox(height: 12),
          _ActionButton(quest: quest, index: index),
        ],
      ),
    );
  }

  IconData _questIcon(String name) => switch (name) {
        'star' => Icons.star_rounded,
        'bolt' => Icons.bolt_rounded,
        'flag' => Icons.flag_rounded,
        'check' => Icons.check_circle_rounded,
        _ => Icons.task_alt_rounded,
      };

  String _statusLabel(QuestStatus s) => switch (s) {
        QuestStatus.completed => 'COMPLETED',
        QuestStatus.inProgress => 'IN PROGRESS',
        QuestStatus.locked => 'NOT STARTED',
      };
}

// ─── Day dot (weekly activity) ────────────────────────────────────────────────
class _DayDot extends StatelessWidget {
  final String label;
  final bool done;
  const _DayDot({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: done
            ? AppColors.mintGreen
            : AppColors.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: done ? Colors.white : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

// ─── Action button inside quest card ─────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final DailyQuest quest;
  final int index;
  const _ActionButton({required this.quest, required this.index});

  @override
  Widget build(BuildContext context) {
    if (quest.claimed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('✓ REWARD CLAIMED',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.mintGreen)),
        ),
      );
    }

    if (quest.completed) {
      return TactileButton(
        color: AppColors.secondaryContainer,
        shadowColor: AppColors.secondary,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(vertical: 12),
        onPressed: () => PlayerDataService.instance.claimQuest(index),
        child: Center(
          child: Text('CLAIM +${quest.xpReward} XP',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.onSecondaryContainer)),
        ),
      );
    }

    // In progress or not started — navigate to Practice
    return TactileButton(
      color: AppColors.primary,
      shadowColor: AppColors.onPrimaryFixedVariant,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PracticeSetupScreen()),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text('KEEP PLAYING',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
