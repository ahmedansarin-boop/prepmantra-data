import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Base palette ──────────────────────────────────────────────────────────
  static const Color primary         = Color(0xFF4F8EF7); // Vibrant blue
  static const Color accent          = Color(0xFF7C5CFC); // Purple accent
  static const Color background      = Color(0xFF0A0A1A); // Deep navy
  static const Color surface         = Color(0xFF12122A); // Dark surface — cards
  static const Color surfaceVariant  = Color(0xFF1E1E3A); // Elevated cards
  static const Color onBackground    = Color(0xFFE8E8F5); // Primary text
  static const Color onSurface       = Color(0xFF9090B8); // Secondary text
  static const Color divider         = Color(0xFF1E1E3A); // Dividers
  static const Color error           = Color(0xFFCF6679); // Error red
  static const Color success         = Color(0xFF3DD68C); // Download complete
  static const Color favorite        = Color(0xFFFF5370); // Heart icon
  static const Color shimmer         = Color(0xFF1A1A35); // Skeleton base

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F8EF7), Color(0xFF7C5CFC)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161630), Color(0xFF1A1A3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient artworkGradient = LinearGradient(
    colors: [Color(0xFF1E2A5A), Color(0xFF2A1A50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0A0A1A), Color(0xFF12122E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFF16163A), Color(0xFF22224A), Color(0xFF16163A)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-2, 0),
    end: Alignment(2, 0),
  );
}
