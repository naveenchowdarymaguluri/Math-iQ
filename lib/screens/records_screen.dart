import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/challenge_level.dart';
import '../services/level_service.dart';
import '../services/player_data_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/dotted_background.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const SafeArea(
        child: AdBanner(placement: 'recordsBanner'),
      ),
      body: DottedBackground(
      child: Column(
        children: [
          _AppBar(),
          Expanded(
            child: ListenableBuilder(
              listenable: LevelService.instance,
              builder: (context, _) {
                return ListenableBuilder(
                  listenable: PlayerDataService.instance,
                  builder: (context, _) {
                    final lvl = LevelService.instance;
                    final p = PlayerDataService.instance;
                    return SingleChildScrollView(
                      padding:
                          const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GrandTotalCard(total: lvl.grandTotalStars),
                          const SizedBox(height: 16),
                          _PlayerStatsRow(svc: p),
                          const SizedBox(height: 24),
                          _SectionLabel(text: 'CHALLENGE MODES'),
                          const SizedBox(height: 12),
                          ...ChallengeMode.values.map(
                            (mode) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ModeCard(
                                mode: mode,
                                stars: lvl.totalStarsFor(mode),
                                highest: lvl.highestPlayedFor(mode),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _SectionLabel(text: 'QUICK PLAY'),
                          const SizedBox(height: 12),
                          _QuickPlayCard(svc: p),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ─── App bar ─────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Text(
              'Records',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            const Text('📊', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Colors.grey,
      ),
    );
  }
}

// ─── Grand total stars card ───────────────────────────────────────────────────
class _GrandTotalCard extends StatelessWidget {
  final int total;
  const _GrandTotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF0D0D1A),
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 52)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total / 1500',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                  ),
                ),
                Text(
                  'Total Stars Earned',
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (total / 1500).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.amber),
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

// ─── Player stats row ─────────────────────────────────────────────────────────
class _PlayerStatsRow extends StatelessWidget {
  final PlayerDataService svc;
  const _PlayerStatsRow({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFFE0E0E0), offset: Offset(0, 4), blurRadius: 0)
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _StatCol('⚡', '${svc.totalXP}', 'TOTAL XP')),
          _Divider(),
          Expanded(child: _StatCol('🏆', '${svc.level}', 'LEVEL')),
          _Divider(),
          Expanded(child: _StatCol('🔥', '${svc.streakDays}d', 'STREAK')),
          _Divider(),
          Expanded(child: _StatCol('✅', '${svc.totalCorrectEver}', 'CORRECT')),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 40, width: 1, color: const Color(0xFFEEEEEE));
  }
}

class _StatCol extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatCol(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.grey),
        ),
      ],
    );
  }
}

// ─── Mode record card ─────────────────────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final ChallengeMode mode;
  final int stars;
  final int highest;
  const _ModeCard(
      {required this.mode, required this.stars, required this.highest});

  @override
  Widget build(BuildContext context) {
    final primary = Color(mode.primaryColorValue);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: primary.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(mode.emoji,
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.displayName,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  mode.opsLabel,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (stars / 300).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        primary.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.star_rounded,
                      color: Colors.amber.shade600, size: 16),
                  const SizedBox(width: 3),
                  Text(
                    '$stars / 300',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                highest > 0 ? 'Lvl $highest reached' : 'Not started',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: highest > 0 ? primary : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick play records ───────────────────────────────────────────────────────
class _QuickPlayCard extends StatelessWidget {
  final PlayerDataService svc;
  const _QuickPlayCard({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFFE0E0E0), offset: Offset(0, 4), blurRadius: 0)
        ],
      ),
      child: Column(
        children: [
          _QuickRow(
            emoji: '🌍',
            label: 'Flag Quiz',
            sub: 'Best Streak',
            value: svc.bestFlagStreak > 0
                ? '${svc.bestFlagStreak} in a row'
                : '—',
            color: const Color(0xFF2EC4B6),
          ),
          const Divider(height: 20, color: Color(0xFFF0F0F0)),
          _QuickRow(
            emoji: '⚡',
            label: 'Survival Mode',
            sub: 'Best Wave',
            value: svc.bestChallengeWave > 0
                ? 'Wave ${svc.bestChallengeWave}'
                : '—',
            color: const Color(0xFFFF6B6B),
          ),
        ],
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String sub;
  final String value;
  final Color color;
  const _QuickRow({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text(sub,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: color),
        ),
      ],
    );
  }
}
