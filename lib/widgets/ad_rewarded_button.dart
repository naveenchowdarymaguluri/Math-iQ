import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ad_service.dart';

/// A button that shows a real AdMob rewarded video ad.
///
/// When the user watches enough of the video to earn the reward,
/// [onRewarded] is called. If no ad is loaded yet, a snackbar is shown and
/// a new ad is requested in the background.
///
/// Example:
/// ```dart
/// AdRewardedButton(
///   label: 'Watch Ad → Free Retry',
///   rewardLabel: 'Free Retry',
///   color: const Color(0xFF1565C0),
///   onRewarded: _handleFreeRetry,
/// )
/// ```
class AdRewardedButton extends StatefulWidget {
  final String label;
  final String rewardLabel;
  final Color color;
  final Color? shadowColor;
  final VoidCallback onRewarded;
  final AdPlacement placement;

  const AdRewardedButton({
    super.key,
    required this.label,
    required this.rewardLabel,
    required this.color,
    this.shadowColor,
    required this.onRewarded,
    this.placement = AdPlacement.levelFailedRewarded,
  });

  @override
  State<AdRewardedButton> createState() => _AdRewardedButtonState();
}

class _AdRewardedButtonState extends State<AdRewardedButton> {
  bool _pressed = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Make sure an ad is warming up before the user taps.
    AdService.instance.preloadRewarded();
  }

  Future<void> _tap() async {
    if (_loading) return;

    if (!AdService.instance.isRewardedReady) {
      AdService.instance.preloadRewarded();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ad is still loading — try again in a moment.',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    await AdService.instance.showRewarded(
      onReward: widget.onRewarded,
      placement: widget.placement,
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final shadow = widget.shadowColor ??
        HSLColor.fromColor(widget.color).withLightness(
          (HSLColor.fromColor(widget.color).lightness - 0.2).clamp(0.0, 1.0),
        ).toColor();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _tap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(0, 4, 0)
            : Matrix4.identity(),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: shadow,
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: _loading
            ? const SizedBox(
                height: 22,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎬', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
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
