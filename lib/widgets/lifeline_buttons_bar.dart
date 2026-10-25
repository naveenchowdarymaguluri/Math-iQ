import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/player_data_service.dart';
import '../theme/app_colors.dart';

class LifelineButtonsBar extends StatelessWidget {
  final VoidCallback onUse5050;
  final VoidCallback onUseTimeFreeze;
  final bool is5050Used;
  final bool isTimeFreezeUsed;
  final bool showTimeFreeze;
  final bool isAnswered;

  const LifelineButtonsBar({
    super.key,
    required this.onUse5050,
    required this.onUseTimeFreeze,
    required this.is5050Used,
    required this.isTimeFreezeUsed,
    this.showTimeFreeze = true,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerDataService.instance,
      builder: (context, _) {
        final svc = PlayerDataService.instance;
        final has5050Inventory = svc.lifeline5050Count > 0;
        final hasTimeFreezeInventory = svc.lifelineTimeFreezeCount > 0;

        return Row(
          children: [
            // 50/50 Lifeline Button
            Expanded(
              child: _LifelineChip(
                emoji: '✂️',
                title: '50/50',
                costLabel: has5050Inventory
                    ? '${svc.lifeline5050Count} left'
                    : '60 XP',
                isUsed: is5050Used,
                isDisabled: isAnswered || is5050Used,
                color: AppColors.primary,
                onTap: onUse5050,
              ),
            ),
            if (showTimeFreeze) ...[
              const SizedBox(width: 10),
              // +10s Freeze Button
              Expanded(
                child: _LifelineChip(
                  emoji: '⏱️',
                  title: '+10s Time',
                  costLabel: hasTimeFreezeInventory
                      ? '${svc.lifelineTimeFreezeCount} left'
                      : '75 XP',
                  isUsed: isTimeFreezeUsed,
                  isDisabled: isAnswered,
                  color: const Color(0xFF6C5CE7),
                  onTap: onUseTimeFreeze,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LifelineChip extends StatelessWidget {
  final String emoji;
  final String title;
  final String costLabel;
  final bool isUsed;
  final bool isDisabled;
  final Color color;
  final VoidCallback onTap;

  const _LifelineChip({
    required this.emoji,
    required this.title,
    required this.costLabel,
    required this.isUsed,
    required this.isDisabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDisabled
        ? AppColors.surfaceContainerHigh
        : AppColors.surfaceContainerLowest;
    final borderColor =
        isDisabled ? AppColors.surfaceContainerHighest : color;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: !isDisabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDisabled
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isUsed
                    ? AppColors.surfaceContainerHighest
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isUsed ? 'USED' : costLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isUsed ? AppColors.outline : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
