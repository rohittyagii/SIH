import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Outfit text style helpers ──────────────────────────────────────────────
// Usage: AppText.outfit(size: 14, weight: FontWeight.w500, color: ctx.rrT2)
abstract final class AppText {
  static TextStyle outfit({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // Commonly used composites
  static TextStyle label(Color color) =>
      outfit(size: 10, weight: FontWeight.w600, color: color, letterSpacing: 0.10);

  static TextStyle caption(Color color) =>
      outfit(size: 11, color: color);

  static TextStyle body(Color color) =>
      outfit(size: 14, color: color);

  static TextStyle bodyMed(Color color) =>
      outfit(size: 14, weight: FontWeight.w500, color: color);

  static TextStyle title(Color color) =>
      outfit(size: 20, weight: FontWeight.w600, color: color);

  static TextStyle display(Color color) =>
      outfit(size: 27, weight: FontWeight.w600, color: color, height: 1.25);

  static TextStyle mono({double size = 30, Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0.22,
      );
}
