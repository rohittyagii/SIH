import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Dark palette (maps to :root CSS vars) ─────────────────────────────────
abstract final class AppColorsDark {
  static const bg   = Color(0xFF0A0F14);
  static const bgd  = Color(0xFF060A0E);
  static const bgn  = Color(0xFF0C1520);
  static const bgc  = Color(0xFF131B24);

  // Card chrome
  static const cbt  = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const cb   = Color(0x0BFFFFFF); // rgba(255,255,255,0.045)
  static const csh  = Color(0x6B000000); // rgba(0,0,0,0.42)

  // Text t1 → t7
  static const t1   = Color(0xFFE8EEFA);
  static const t2   = Color(0xFFC8D8E8);
  static const t2b  = Color(0xFF7A92A8);
  static const t3   = Color(0xFF5C7A90);
  static const t4   = Color(0xFF4A6070);
  static const t5   = Color(0xFF3D5568);
  static const t6   = Color(0xFF384C5E);
  static const t7   = Color(0xFF253545);

  // Surfaces
  static const ov   = Color(0x06FFFFFF); // rgba(255,255,255,0.025)
  static const pl   = Color(0x09FFFFFF); // rgba(255,255,255,0.035)
  static const inSurface = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)

  // Borders / dividers
  static const dv   = Color(0x0DFFFFFF);
  static const dv2  = Color(0x0FFFFFFF);
  static const dv3  = Color(0x12FFFFFF);
  static const ib   = Color(0x14FFFFFF);
  static const plb  = Color(0x16FFFFFF);
  static const b1   = Color(0x17FFFFFF);
  static const b2   = Color(0x1AFFFFFF);
  static const b3   = Color(0x1CFFFFFF);
  static const b4   = Color(0x1FFFFFFF);
  static const b5   = Color(0x21FFFFFF);
  static const b6   = Color(0x24FFFFFF);
  static const b7   = Color(0x29FFFFFF);
}

// ── Light palette (maps to [data-theme="light"] overrides) ─────────────────
abstract final class AppColorsLight {
  static const bg   = Color(0xFFEEF2F8);
  static const bgd  = Color(0xFFE4EAF5);
  static const bgn  = Color(0xFFFFFFFF);
  static const bgc  = Color(0xFFFFFFFF);

  static const cbt  = Color(0x17000000);
  static const cb   = Color(0x0D000000);
  static const csh  = Color(0x12000000);

  static const t1   = Color(0xFF0E1825);
  static const t2   = Color(0xFF1E2C3E);
  static const t2b  = Color(0xFF3A5060);
  static const t3   = Color(0xFF4A6070);
  static const t4   = Color(0xFF5E7282);
  static const t5   = Color(0xFF6E8292);
  static const t6   = Color(0xFF8898A8);
  static const t7   = Color(0xFF9EAEBB);

  static const ov   = Color(0x08000000);
  static const pl   = Color(0x0A000000);
  static const inSurface = Color(0x0A000000);

  static const dv   = Color(0x0F000000);
  static const dv2  = Color(0x12000000);
  static const dv3  = Color(0x12000000);
  static const ib   = Color(0x17000000);
  static const plb  = Color(0x17000000);
  static const b1   = Color(0x14000000);
  static const b2   = Color(0x17000000);
  static const b3   = Color(0x17000000);
  static const b4   = Color(0x1A000000);
  static const b5   = Color(0x1A000000);
  static const b6   = Color(0x1A000000);
  static const b7   = Color(0x1F000000);
}

// ── Brand / semantic colors (same in both themes) ───────────────────────────
abstract final class AppColors {
  // Score colors (1–5)
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

  // Accent
  static const indigo  = Color(0xFF818CF8);
  static const amber   = Color(0xFFC4A870);
  static const red     = Color(0xFFEF6B6B);
  static const orange  = Color(0xFFC07830);

  // Dimension line colors (for the chart)
  static const dimOverall  = Color(0xFF818CF8);
  static const dimSleep    = Color(0xFF56B4E9);
  static const dimPhysical = Color(0xFF34D399);
  static const dimFocus    = Color(0xFFC4A870);
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
  static ThemeData dark() => _build(Brightness.dark, AppColorsDark.bg);
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
        seedColor: AppColors.indigo,
        surface: brightness == Brightness.dark ? AppColorsDark.bgc : AppColorsLight.bgc,
      ),
    );
  }
}
