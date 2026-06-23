import 'package:flutter/material.dart';
import '../config/colors.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final bool isOverBudget;
  final List<Color>? gradient;
  final double height;

  const ProgressBar({
    super.key,
    required this.progress,
    this.isOverBudget = false,
    this.gradient,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOverBudget
        ? FinarusColors.destructive
        : FinarusColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: gradient != null
          ? Container(
              height: height,
              decoration: BoxDecoration(
                color: FinarusColors.secondary,
                borderRadius: BorderRadius.circular(height / 2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (progress / 100).clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: gradient!,
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            )
          : LinearProgressIndicator(
              value: (progress / 100).clamp(0, 1),
              backgroundColor: FinarusColors.secondary,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: height,
            ),
    );
  }
}
