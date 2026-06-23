import 'package:flutter/material.dart';

class FinarusColors {
  // ── Background ──────────────────────────────────────────
  static const background      = Color(0xFFE4EBF5);  // Light blue-grey (more visible)
  static const backgroundTop   = Color(0xFFD2DEEE);  // Slightly darker top
  static const foreground      = Color(0xFF0F172A);  // Slate 900

  // ── Glass Card ──────────────────────────────────────────
  static const card            = Color(0xB3FFFFFF);  // 70% white (glass)
  static const cardSolid       = Color(0xFFFFFFFF);  // 100% white fallback
  static const cardBorder      = Color(0x40FFFFFF);  // 25% white border
  static const cardShadow      = Color(0x1A2563EB);  // Soft blue shadow

  // ── Primary ─────────────────────────────────────────────
  static const primary         = Color(0xFF3B82F6);  // Blue 500
  static const primaryLight    = Color(0xFF60A5FA);  // Blue 400
  static const primaryDark     = Color(0xFF2563EB);  // Blue 600
  static const primaryFg       = Color(0xFFF8FAFC);  // White text on primary

  // ── Secondary ───────────────────────────────────────────
  static const secondary       = Color(0xFFF1F5F9);  // Slate 100
  static const muted           = Color(0xFFF1F5F9);  // Slate 100
  static const mutedFg         = Color(0xFF64748B);  // Slate 500

  // ── Semantic ────────────────────────────────────────────
  static const income          = Color(0xFF10B981);  // Emerald 500
  static const incomeLight     = Color(0xFFD1FAE5);  // Emerald 100
  static const expense         = Color(0xFFEF4444);  // Red 500
  static const expenseLight    = Color(0xFFFEE2E2);  // Red 100
  static const destructive     = Color(0xFFEF4444);  // Red 500
  static const border          = Color(0xFFE2E8F0);  // Slate 200

  // ── Surface ─────────────────────────────────────────────
  static const surfaceContainer = Color(0xFFF8FAFC); // Slate 50

  // ── Gradient pairs ──────────────────────────────────────
  static const gradientBlue    = [Color(0xFF3B82F6), Color(0xFF2563EB)];
  static const gradientPurple  = [Color(0xFF8B5CF6), Color(0xFF7C3AED)];
  static const gradientCard    = [Color(0xFF3B82F6), Color(0xFF6366F1)];
  static const gradientTeal    = [Color(0xFF14B8A6), Color(0xFF0D9488)];
  static const gradientOrange  = [Color(0xFFF97316), Color(0xFFEA580C)];
  static const gradientPink    = [Color(0xFFEC4899), Color(0xFFDB2777)];
  static const gradientGreen   = [Color(0xFF10B981), Color(0xFF059669)];
  static const gradientDark    = [Color(0xFF1E293B), Color(0xFF0F172A)];

  // ── Chart colors ────────────────────────────────────────
  static const chartBlue       = Color(0xFF3B82F6);
  static const chartGreen      = Color(0xFF10B981);
  static const chartRed        = Color(0xFFEF4444);
  static const chartOrange     = Color(0xFFF97316);
  static const chartPurple     = Color(0xFF8B5CF6);
  static const chartYellow     = Color(0xFFEAB308);

  // ── Helpers ─────────────────────────────────────────────
  static LinearGradient linear(List<Color> colors, {Alignment begin = Alignment.topLeft, Alignment end = Alignment.bottomRight}) {
    return LinearGradient(begin: begin, end: end, colors: colors);
  }

  static LinearGradient bgGradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [backgroundTop, background],
    );
  }
}
