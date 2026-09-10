import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Dark palette (rosewood dark — maps to :root CSS vars) ─────────────────
abstract final class AppColorsDark {
  static const bg   = Color(0xFF140A0E); // slightly deeper rosewood black for higher contrast
  static const bgd  = Color(0xFF0F070A); // even deeper
  static const bgn  = Color(0xFF1C0D14); // elevated surfaces
  static const bgc  = Color(0xFF24111B); // card background

  // Card chrome
  static const cbt  = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
  static const cb   = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
  static const csh  = Color(0x8A000000); // rgba(0,0,0,0.54) - deeper shadow

  // Text t1 → t7 (shifted lighter for much higher contrast)
  static const t1   = Color(0xFFFFF5F7);
  static const t2   = Color(0xFFEEE0E5);
  static const t2b  = Color(0xFFD1ABB8);
  static const t3   = Color(0xFFB88B9D);
  static const t4   = Color(0xFF9F7183);
  static const t5   = Color(0xFF895C6E);
  static const t6   = Color(0xFF734958);
  static const t7   = Color(0xFF5F3947);

  // Surfaces
  static const ov   = Color(0x0AFFFFFF); 
  static const pl   = Color(0x0EFFFFFF); 
  static const inSurface = Color(0x12FFFFFF); 

  // Borders / dividers - increased opacity for more definition
  static const dv   = Color(0x1AFFFFFF);
  static const dv2  = Color(0x1EFFFFFF);
  static const dv3  = Color(0x24FFFFFF);
  static const ib   = Color(0x29FFFFFF);
  static const plb  = Color(0x2EFFFFFF);
  static const b1   = Color(0x33FFFFFF);
  static const b2   = Color(0x38FFFFFF);
  static const b3   = Color(0x3DFFFFFF);
  static const b4   = Color(0x42FFFFFF);
  static const b5   = Color(0x47FFFFFF);
  static const b6   = Color(0x4DFFFFFF);
  static const b7   = Color(0x54FFFFFF);
}

// ── Light palette (rosewood light) ─────────────────────────────────────────
abstract final class AppColorsLight {
  static const bg   = Color(0xFFFFFFFF); // pure white for max contrast
  static const bgd  = Color(0xFFF7ECF0); // slightly lighter rose depth
  static const bgn  = Color(0xFFFFFFFF); // pure white cards
  static const bgc  = Color(0xFFFFFFFF); // card fills

  static const cbt  = Color(0x26000000);
  static const cb   = Color(0x1A000000);
  static const csh  = Color(0x1F000000);

  // Text t1 → t7 (shifted darker for much higher contrast)
  static const t1   = Color(0xFF12080C);
  static const t2   = Color(0xFF24131A);
  static const t2b  = Color(0xFF422B36);
  static const t3   = Color(0xFF543845);
  static const t4   = Color(0xFF684857);
  static const t5   = Color(0xFF7C5868);
  static const t6   = Color(0xFF8C6677);
  static const t7   = Color(0xFF9E7587);

  static const ov   = Color(0x0C000000);
  static const pl   = Color(0x0F000000);
  static const inSurface = Color(0x0F000000);

  // Borders / dividers - increased opacity for more definition
  static const dv   = Color(0x1A000000);
  static const dv2  = Color(0x1E000000);
  static const dv3  = Color(0x24000000);
  static const ib   = Color(0x29000000);
  static const plb  = Color(0x2E000000);
  static const b1   = Color(0x33000000);
  static const b2   = Color(0x38000000);
  static const b3   = Color(0x3D000000);
  static const b4   = Color(0x42000000);
  static const b5   = Color(0x47000000);
  static const b6   = Color(0x4D000000);
  static const b7   = Color(0x54000000);
}

// ── Brand / semantic colors (same in both themes) ───────────────────────────
abstract final class AppColors {
  // Score colors (1–5) — kept distinct for accessibility
  static const score1  = Color(0xFFD55E00);
  static const score2  = Color(0xFFC07830);
  static const score3  = Color(0xFF56B4E9);
  static const score4  = Color(0xFF3EC4A0);
  static const score5  = Color(0xFF34D399);

  static final scoreColors = [score1, score2, score3, score4, score5];
  static final scoreGlows  = [
    const Color(0x33D55E00),
    const Color(0x33C07830),
    const Color(0x3356B4E9),
    const Color(0x333EC4A0),
    const Color(0x3334D399),
  ];

  // Accent — rosewood palette
  static const indigo  = Color(0xFFBE8296); // muted rose (#be8296) — primary accent
  static const rose    = Color(0xFF9D3E5C); // deep crimson-rose (#9d3e5c) — strong CTA
  static const amber   = Color(0xFFC4A870); // warm amber — kept for contrast
  static const red     = Color(0xFFEF6B6B); // error red — kept
  static const orange  = Color(0xFFC07830); // warning orange — kept

  // Dimension line colors (for the chart)
  static const dimOverall  = Color(0xFFBE8296); // muted rose
  static const dimSleep    = Color(0xFF56B4E9); // sky blue — distinct
  static const dimPhysical = Color(0xFF34D399); // teal-green — distinct
  static const dimFocus    = Color(0xFFC4A870); // warm amber — distinct
}

// ── AppColors extension on BuildContext ────────────────────────────────────
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get rrBg   => isDark ? AppColorsDark.bg   : AppColorsLight.bg;
  Color get rrBgd  => isDark ? AppColorsDark.bgd  : AppColorsLight.bgd;
  Color get rrBgn  => isDark ? AppColorsDark.bgn  : AppColorsLight.bgn;
  Color get rrBgc  => isDark ? AppColorsDark.bgc  : AppColorsLight.bgc;
  Color get rrCbt  => isDark ? AppColorsDark.cbt  : AppColorsLight.cbt;
  Color get rrCb   => isDark ? AppColorsDark.cb   : AppColorsLight.cb;
  Color get rrCsh  => isDark ? AppColorsDark.csh  : AppColorsLight.csh;
  Color get rrT1   => isDark ? AppColorsDark.t1   : AppColorsLight.t1;
  Color get rrT2   => isDark ? AppColorsDark.t2   : AppColorsLight.t2;
  Color get rrT2b  => isDark ? AppColorsDark.t2b  : AppColorsLight.t2b;
  Color get rrT3   => isDark ? AppColorsDark.t3   : AppColorsLight.t3;
  Color get rrT4   => isDark ? AppColorsDark.t4   : AppColorsLight.t4;
  Color get rrT5   => isDark ? AppColorsDark.t5   : AppColorsLight.t5;
  Color get rrT6   => isDark ? AppColorsDark.t6   : AppColorsLight.t6;
  Color get rrT7   => isDark ? AppColorsDark.t7   : AppColorsLight.t7;
  Color get rrOv   => isDark ? AppColorsDark.ov   : AppColorsLight.ov;
  Color get rrPl   => isDark ? AppColorsDark.pl   : AppColorsLight.pl;
  Color get rrIn   => isDark ? AppColorsDark.inSurface : AppColorsLight.inSurface;
  Color get rrDv   => isDark ? AppColorsDark.dv   : AppColorsLight.dv;
  Color get rrDv2  => isDark ? AppColorsDark.dv2  : AppColorsLight.dv2;
  Color get rrDv3  => isDark ? AppColorsDark.dv3  : AppColorsLight.dv3;
  Color get rrIb   => isDark ? AppColorsDark.ib   : AppColorsLight.ib;
  Color get rrPlb  => isDark ? AppColorsDark.plb  : AppColorsLight.plb;
  Color get rrB1   => isDark ? AppColorsDark.b1   : AppColorsLight.b1;
  Color get rrB2   => isDark ? AppColorsDark.b2   : AppColorsLight.b2;
  Color get rrB3   => isDark ? AppColorsDark.b3   : AppColorsLight.b3;
  Color get rrB4   => isDark ? AppColorsDark.b4   : AppColorsLight.b4;
  Color get rrB5   => isDark ? AppColorsDark.b5   : AppColorsLight.b5;
  Color get rrB6   => isDark ? AppColorsDark.b6   : AppColorsLight.b6;
  Color get rrB7   => isDark ? AppColorsDark.b7   : AppColorsLight.b7;
}

// ── ThemeData factories ────────────────────────────────────────────────────
abstract final class AppTheme {
  static ThemeData dark()  => _build(Brightness.dark,  AppColorsDark.bg);
  static ThemeData light() => _build(Brightness.light, AppColorsLight.bg);

  static ThemeData _build(Brightness brightness, Color scaffoldBg) {
    final base = ThemeData(brightness: brightness);
    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor:    brightness == Brightness.dark ? AppColorsDark.t1 : AppColorsLight.t1,
        displayColor: brightness == Brightness.dark ? AppColorsDark.t1 : AppColorsLight.t1,
      ),
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: AppColors.indigo, // #be8296 rose — generates rosewood ColorScheme
        surface: brightness == Brightness.dark ? AppColorsDark.bgc : AppColorsLight.bgc,
      ),
    );
  }
}
