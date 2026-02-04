import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Shades of Blue)
  static const Color primary = Color(0xFF0052CC); // Deep Corporate Blue
  static const Color primaryDark = Color(0xFF0747A6); // Darker Blue
  static const Color primaryLight = Color(0xFF4C9AFF); // Lighter sky blue

  // Secondary Palette (Cyan/Soft Blue instead of Emerald/Amber)
  static const Color secondary = Color(0xFF00B8D9); // Vivid Cyan
  static const Color accent = Color(0xFF2684FF); // Bright Information Blue

  // Light Theme Colors
  static const Color background = Color(0xFFF4F5F7); // Very light bluey-gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color card = Color(0xFFE9EEF2); // Subtle blue-tinted slate
  static const Color border = Color(0xFFDFE1E6); // Light border
  
  // Gradients (Refined Blue Gradients)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueSoftGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Colors.white,
      Color(0xFFE9F2FF), // Very soft blue tint
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Colors
  static const Color textPrimary = Color(0xFF172B4D); // Deep Blue-Black
  static const Color textSecondary = Color(0xFF42526E); // Slate Blue
  static const Color textMuted = Color(0xFF7A869A); // Muted Blue-Gray

  // Semantic Colors (Keeping functional colors but tinted if applicable)
  static const Color error = Color(0xFFDE350B);
  static const Color success = Color(0xFF00875A); // Keeping green for success but more professional
  static const Color warning = Color(0xFFFFAB00);
  static const Color info = Color(0xFF0052CC);
}
