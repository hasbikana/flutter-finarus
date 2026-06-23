import 'package:flutter/material.dart';
import '../utils/format.dart';
import '../config/colors.dart';
import 'glass_card.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final List<Color>? gradient;
  final bool large;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.gradient,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    if (gradient != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient!,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient!.first.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(large ? 24 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(large ? 12 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: large ? 24 : 20),
              ),
              SizedBox(height: large ? 16 : 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: large ? 14 : 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatRupiah(amount),
                style: TextStyle(
                  fontSize: large ? 24 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      borderRadius: 20,
      padding: EdgeInsets.all(large ? 24 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(large ? 12 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: large ? 24 : 20),
          ),
          SizedBox(height: large ? 16 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: large ? 14 : 12,
              color: FinarusColors.mutedFg,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(amount),
            style: TextStyle(
              fontSize: large ? 24 : 18,
              fontWeight: FontWeight.bold,
              color: FinarusColors.foreground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
