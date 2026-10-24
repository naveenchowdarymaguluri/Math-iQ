import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MathProgressBar extends StatelessWidget {
  final double value;
  final Color fillColor;
  final Color bgColor;
  final double height;

  const MathProgressBar({
    super.key,
    required this.value,
    this.fillColor = AppColors.mintGreen,
    this.bgColor = AppColors.surfaceContainerHighest,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, -3),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
