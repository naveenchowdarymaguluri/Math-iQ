import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/challenge_level.dart';
import '../models/session_result.dart';
import '../models/wrong_answer_item.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/level_service.dart';
import '../services/player_data_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/ad_rewarded_button.dart';
import 'level_play_screen.dart';
import 'level_select_screen.dart';
import 'wrong_answers_review_screen.dart';

class LevelResultsScreen extends StatefulWidget {
  final ChallengeMode mode;
  final int level;
  final int correct;
  final int total;
  final ChallengeLevel cfg;
  final List<WrongAnswerItem> wrongAnswers;

  const LevelResultsScreen({
    super.key,
    required this.mode,
    required this.level,
    required this.correct,
    required this.total,
    required this.cfg,
    this.wrongAnswers = const [],
  });

  @override
  State<LevelResultsScreen> createState() => _LevelResultsScreenState();
}

class _LevelResultsScreenState extends State<LevelResultsScreen>
    with TickerProviderStateMixin {
  late final int _stars;
  late final int _xpEarned;
  bool _recorded = false;
  final List<bool> _starVisible = [false, false, false];

  @override
  void initState() {
    super.initState();
    _stars = widget.cfg.starsForScore(widget.correct, widget.total);
    // XP scales: 1 star = 33%, 2 stars = 66%, 3 stars = 100% of level reward
    _xpEarned = _stars > 0
        ? (widget.cfg.xpReward * _stars / 3).round()
        : 0;
    _record();
    _animateStars();
    if (_stars > 0) _maybeShowInterstitial();
  }

  void _maybeShowInterstitial() {
    // Count this completion, then show the right full-screen ad after the
    // stars finish animating (~350 + 2*280 = 910 ms; wait 1.4 s).
    final ads = AdService.instance;
    ads.onLevelCompleted();
    if (ads.shouldOfferRewardedBonus) {
      // Every 10 completions: opt-in rewarded XP bonus beats an interstitial.
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        _showMilestoneRewardOffer();
      });
    } else if (ads.shouldShowInterstitial) {
      // Every 3 completions: interstitial.
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        ads.maybeShowInterstitial();
      });
    }
  }

  static const _milestoneBonusXp = 100;

  void _showMilestoneRewardOffer() {
    AdService.instance.clearRewardedOffer();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(
              '10 Levels Milestone!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF005DA7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Watch a short video to earn a +$_milestoneBonusXp XP bonus!',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: const Color(0xFF616161),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  AdService.instance.showRewarded(
                    placement: AdPlacement.milestoneRewarded,
                    onReward: () => PlayerDataService.instance
                        .addBonusXP(_milestoneBonusXp),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005DA7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  '🎬  Watch & Earn +$_milestoneBonusXp XP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'No thanks',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _record() async {
    if (_recorded) return;
    _recorded = true;
    await LevelService.instance.recordResult(
      mode: widget.mode,
      level: widget.level,
      correct: widget.correct,
      total: widget.total,
    );
    if (_xpEarned > 0) {
      await PlayerDataService.instance.recordSession(SessionResult(
        mode: '${widget.mode.displayName} L${widget.level}',
        correct: widget.correct,
        wrong: widget.total - widget.correct,
        total: widget.total,
        xpEarned: _xpEarned,
        highestStreak: widget.correct,
        date: DateTime.now(),
      ));
    }
    // Analytics — log the level outcome regardless of pass/fail
    AnalyticsService.instance.logLevelCompleted(
      modeName: widget.mode.name,
      levelNumber: widget.level,
      stars: _stars,
      correct: widget.correct,
      total: widget.total,
      xpEarned: _xpEarned,
    );
  }

  void _animateStars() {
    for (int i = 0; i < _stars; i++) {
      Future.delayed(Duration(milliseconds: 350 + i * 280), () {
        if (!mounted) return;
        setState(() => _starVisible[i] = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Color(widget.mode.primaryColorValue);
    final passed = _stars > 0;
    final pct = widget.total > 0
        ? (widget.correct / widget.total * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const SafeArea(
        child: AdBanner(placement: 'levelResultsBanner'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Row(
                children: [
                  _IconBtn(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LevelSelectScreen(mode: widget.mode),
                      ),
                      (r) => r.isFirst,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    passed ? '🎉 Level Complete!' : 'Try Again!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: passed ? primary : const Color(0xFFE53935),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),

              const SizedBox(height: 28),

              // ── Mode badge ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${widget.mode.emoji}  ${widget.mode.displayName}  ·  Level ${widget.level}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: primary,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Animated stars ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final earned = i < _stars && _starVisible[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: AnimatedScale(
                      scale: earned ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.elasticOut,
                      child: AnimatedOpacity(
                        opacity: earned || i >= _stars ? 1.0 : 0.4,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          (i < _stars && _starVisible[i])
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: i == 1 ? 84 : 66,
                          color: (i < _stars && _starVisible[i])
                              ? Colors.amber
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // ── Big score ────────────────────────────────────────────────
              Text(
                '${widget.correct} / ${widget.total}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: primary,
                ),
              ),
              Text(
                '$pct% Accuracy',
                style: GoogleFonts.beVietnamPro(
                  color: const Color(0xFF757575),
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 20),

              // ── XP earned ────────────────────────────────────────────────
              if (_xpEarned > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade400, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '+$_xpEarned XP earned',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF715D00),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFE53935), width: 2),
                  ),
                  child: Text(
                    'Need 50%+ to pass — keep going! 💪',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE53935),
                    ),
                  ),
                ),

              const Spacer(),

              // ── Review wrong answers ─────────────────────────────────────
              if (widget.wrongAnswers.isNotEmpty) ...[
                _BigButton(
                  label: '🔁  Review ${widget.wrongAnswers.length} Mistake${widget.wrongAnswers.length > 1 ? 's' : ''}',
                  color: const Color(0xFF6A1B9A),
                  shadowColor: const Color(0xFF4A148C),
                  textColor: Colors.white,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WrongAnswersReviewScreen(
                        wrongAnswers: widget.wrongAnswers,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Rewarded ad: free retry when failed ──────────────────────
              if (!passed) ...[
                AdRewardedButton(
                  label: 'Watch Ad → Free Retry',
                  rewardLabel: 'Free Retry',
                  color: const Color(0xFF1565C0),
                  shadowColor: const Color(0xFF003C8F),
                  onRewarded: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LevelPlayScreen(
                        mode: widget.mode,
                        level: widget.level,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Buttons ──────────────────────────────────────────────────
              if (passed && widget.level < 100) ...[
                _BigButton(
                  label: 'Next Level  →',
                  color: primary,
                  shadowColor: Color(widget.mode.shadowColorValue),
                  textColor: Colors.white,
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LevelPlayScreen(
                        mode: widget.mode,
                        level: widget.level + 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: _BigButton(
                      label: '↺  Retry',
                      color: const Color(0xFFEEEEEE),
                      shadowColor: const Color(0xFFBDBDBD),
                      textColor: const Color(0xFF424242),
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LevelPlayScreen(
                            mode: widget.mode,
                            level: widget.level,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigButton(
                      label: '≡  Levels',
                      color: const Color(0xFFEEEEEE),
                      shadowColor: const Color(0xFFBDBDBD),
                      textColor: const Color(0xFF424242),
                      onTap: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LevelSelectScreen(mode: widget.mode),
                        ),
                        (r) => r.isFirst,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _BigButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color shadowColor;
  final Color textColor;
  final VoidCallback onTap;

  const _BigButton({
    required this.label,
    required this.color,
    required this.shadowColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<_BigButton> {
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
        padding: const EdgeInsets.symmetric(vertical: 18),
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
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: widget.textColor,
          ),
        ),
      ),
    );
  }
}
