import 'package:flutter/material.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/constants/coa_constants.dart';

class CoaProgressBar extends StatelessWidget {
  final String category;
  final int count;
  final int required;
  final double height;
  final bool showText;

  const CoaProgressBar({
    super.key,
    required this.category,
    required this.count,
    required this.required,
    this.height = 8.0,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final double progress =
        required > 0 ? (count / required).clamp(0.0, 1.0) : 0.0;

    // Get progress color based on percentage
    final Color progressColor = CoaConstants.getProgressColor(count, required);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showText)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: AppTextStyles.bodyText2.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$count/$required',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Stack(
          children: [
            // Background track
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color.fromARGB(
                  51,
                  Colors.grey.r.toInt(),
                  Colors.grey.g.toInt(),
                  Colors.grey.b.toInt(),
                ),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            // Colored progress bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: height,
              width: progress > 0.0 ? progress * double.infinity : 0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getProgressGradientColors(progress),
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(
                      76,
                      progressColor.r.toInt(),
                      progressColor.g.toInt(),
                      progressColor.b.toInt(),
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Progress text display
        if (showText)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              '${(progress * 100).toStringAsFixed(0)}% Complete',
              style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
            ),
          ),
      ],
    );
  }

  // Helper method to get gradient colors based on progress
  List<Color> _getProgressGradientColors(double progress) {
    // Create a gradient that transitions smoothly between the color ranges
    if (progress <= 0.25) {
      // Red gradient (darker to lighter red)
      return [AppColors.progressRed.withOpacity(0.8), AppColors.progressRed];
    } else if (progress <= 0.5) {
      // Red to Orange gradient
      return [AppColors.progressRed, AppColors.progressOrange];
    } else if (progress <= 0.9) {
      // Orange to Yellow gradient
      return [AppColors.progressOrange, AppColors.progressYellow];
    } else {
      // Yellow to Green gradient
      return [AppColors.progressYellow, AppColors.progressGreen];
    }
  }
}
