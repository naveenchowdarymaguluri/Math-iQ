import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../models/achievement.dart';
import '../services/player_data_service.dart';

/// Play Store listing — replace once the app is published.
const _kPlayStoreLink =
    'https://play.google.com/store/apps/details?id=com.naveen.iqmath';

/// Shows a bottom-sheet share card.
/// The progress card preview is rendered to a PNG and shared as an image
/// together with the referral text — much higher conversion than plain text.
/// Calling [ShareCard.show] is the main entry point.
class ShareCard extends StatefulWidget {
  const ShareCard({super.key});

  // ── Entry point ──────────────────────────────────────────────────────────
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShareCard(),
    );
  }

  @override
  State<ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends State<ShareCard> {
  /// Key around the preview card so it can be captured as an image.
  final GlobalKey _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final svc = PlayerDataService.instance;
    final canEarn = svc.canEarnShareXP;
    final sharesLeft = svc.sharesRemaining;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.creamBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

              // Title + reward chip
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Text(
                    'Invite Friends',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  if (canEarn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: AppColors.mintGreen, width: 1.5),
                      ),
                      child: Text(
                        '+${svc.nextShareXp} XP • $sharesLeft left',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mintGreen,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                canEarn
                    ? 'Share your progress card and earn bonus XP!'
                    : 'Keep sharing — your friends will thank you! 🎉',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // ── Share preview card (captured to PNG on share) ───────────
              RepaintBoundary(
                key: _cardKey,
                child: _ProgressCard(svc: svc),
              ),
              const SizedBox(height: 20),

              // ── Referral steps ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.surfaceContainerHighest, width: 2),
                ),
                child: Column(
                  children: [
                    _Step(
                      n: 1,
                      text: 'Share your progress card with a friend',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    _Step(
                      n: 2,
                      text: 'They download & play for free',
                      color: AppColors.softOrange,
                    ),
                    const SizedBox(height: 8),
                    _Step(
                      n: 3,
                      text:
                          'You earn +${svc.nextShareXp} XP per share (up to ${svc.sharesRemaining} more)!',
                      color: AppColors.mintGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Share button ────────────────────────────────────────────
              _ShareButton(svc: svc, canEarn: canEarn, cardKey: _cardKey),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── The shareable progress card (rendered to PNG) ────────────────────────────
class _ProgressCard extends StatelessWidget {
  final PlayerDataService svc;
  const _ProgressCard({required this.svc});

  @override
  Widget build(BuildContext context) {
    final nextLevel = svc.level + 1;
    final achievementsCount = svc.unlockedAchievements
        .where((id) => Achievement.all.any((a) => a.id == id))
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004C8A), Color(0xFF2976C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('🧮', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Math IQ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Can you beat my score?',
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
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Level ${svc.level}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Level progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: svc.levelProgress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.secondaryContainer),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lv $nextLevel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                child: _Stat(
                    icon: Icons.stars_rounded, label: '${svc.totalXP} XP'),
              ),
              _divider(),
              Flexible(
                child: _Stat(
                    icon: Icons.local_fire_department_rounded,
                    label: '${svc.streakDays}d streak'),
              ),
              _divider(),
              Flexible(
                child: _Stat(
                    icon: Icons.check_circle_rounded,
                    label: '${svc.totalCorrectEver} ✓'),
              ),
              _divider(),
              Flexible(
                child: _Stat(
                    icon: Icons.emoji_events_rounded,
                    label: '$achievementsCount 🏅'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Download line
          Row(
            children: [
              const Icon(Icons.download_rounded,
                  color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Free on Google Play • Math IQ',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: Colors.white24,
      );
}

// ─── Share button (stateful to show loading) ──────────────────────────────────
class _ShareButton extends StatefulWidget {
  final PlayerDataService svc;
  final bool canEarn;
  final GlobalKey cardKey;
  const _ShareButton(
      {required this.svc, required this.canEarn, required this.cardKey});

  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<_ShareButton> {
  bool _sharing = false;

  /// Renders the progress card preview to a PNG in the app's cache dir.
  Future<XFile?> _captureCard() async {
    try {
      final boundary = widget.cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      final file = File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}mathiq_progress.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      return XFile(file.path, mimeType: 'image/png');
    } catch (e) {
      debugPrint('[ShareCard] capture error: $e');
      return null;
    }
  }

  Future<void> _share() async {
    setState(() => _sharing = true);

    final svc = widget.svc;
    final text = '🧮 Math IQ Challenge!\n'
        "I'm Level ${svc.level} with ${svc.totalXP} XP "
        'and a ${svc.streakDays}-day streak!\n'
        'Can you beat me? 🏆\n\n'
        '📱 Download FREE:\n$_kPlayStoreLink';

    try {
      // Share the rendered progress card image; fall back to text-only.
      final imageFile = await _captureCard();
      if (imageFile != null) {
        await Share.shareXFiles(
          [imageFile],
          text: text,
          subject: 'Play Math IQ with me!',
        );
      } else {
        await Share.share(text, subject: 'Play Math IQ with me!');
      }
      await svc.recordShare();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('[ShareCard] share error: $e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _sharing ? null : _share,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _sharing
                ? [AppColors.surfaceContainerHigh, AppColors.surfaceContainerHigh]
                : const [Color(0xFF005DA7), Color(0xFF2976C7)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: _sharing
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: _sharing
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.canEarn
                        ? 'Share & Earn +${widget.svc.nextShareXp} XP'
                        : 'Share with Friends',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Mini helpers ─────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String text;
  final Color color;
  const _Step({required this.n, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '$n',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
