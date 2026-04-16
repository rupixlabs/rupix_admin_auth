import 'package:flutter/material.dart';

class AppColors {
  // Brand: Deep Purple / Neon Lime
  static const Color primary = Color(0xFFB388FF); // Vibrant Purple
  static const Color secondary = Color(0xFFC0FF00); // Electric Lime
  static const Color background = Color(0xFF130321); // Deepest Purple
  static const Color surface = Color(0xFF1E0E35); // Surface Purple

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA094B1); // Muted Purple-Grey

  static const Color income = Color(0xFFC0FF00);
  static const Color expense = Color(0xFFFF5252);

  static const Color appBarBackground = Color(0xFF130321);
  static const Color bottomNavBackground = Color(0xFF1E0E35);

  static const Color fabBackground = Color(0xFFB388FF);
  static const Color fabForeground = Colors.black;

  static const Color cardBackground = Color(0xFF1E0E35);
}

// Glassmorphic styling constants
class Glassmorphism {
  static const double borderRadius = 24.0;
  static const double blur = 20.0;
  static const double opacity = 0.4;
  static const Color borderColor = Color(
    0xFFFFFFFF,
  ); // Will be used with low opacity
}

class AuthConstants {
  static const String turnstileSiteKey = '0x4AAAAAACU4DwxWBhh8rTdj';
}
