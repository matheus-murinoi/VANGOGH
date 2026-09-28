import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFF0B0B10);
  static const Color surface = Color(0xFF15151D);
  static const Color surfaceHigh = Color(0xFF1E1E29);
  static const Color surfaceTop = Color(0xFF262633);
  static const Color border = Color(0xFF2C2C3A);

  static const Color primary = Color(0xFF7C5CFF);
  static const Color primaryDim = Color(0xFF4A3BA8);
  static const Color accent = Color(0xFFFF4D8D);
  static const Color teal = Color(0xFF00D3C7);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF9A9AAE);
  static const Color textMuted = Color(0xFF63637A);

  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5A5A);

  static const LinearGradient brand = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cool = LinearGradient(
    colors: [teal, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get softShadow => const [
    BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
}
