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

// ── AppColors Extension ───────────────────────────────────────────────────
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color rrBg;
  final Color rrBgd;
  final Color rrBgn;
  final Color rrBgc;
  final Color rrCbt;
  final Color rrCb;
  final Color rrCsh;
  final Color rrT1;
  final Color rrT2;
  final Color rrT2b;
  final Color rrT3;
  final Color rrT4;
  final Color rrT5;
  final Color rrT6;
  final Color rrT7;
  final Color rrOv;
  final Color rrPl;
  final Color rrInSurface;
  final Color rrDv;
  final Color rrDv2;
  final Color rrDv3;
  final Color rrIb;
  final Color rrPlb;
  final Color rrB1;
  final Color rrB2;
  final Color rrB3;
  final Color rrB4;
  final Color rrB5;
  final Color rrB6;
  final Color rrB7;

  const AppColorsExtension({
    required this.rrBg,
    required this.rrBgd,
    required this.rrBgn,
    required this.rrBgc,
    required this.rrCbt,
    required this.rrCb,
    required this.rrCsh,
    required this.rrT1,
    required this.rrT2,
    required this.rrT2b,
    required this.rrT3,
    required this.rrT4,
    required this.rrT5,
    required this.rrT6,
    required this.rrT7,
    required this.rrOv,
    required this.rrPl,
    required this.rrInSurface,
    required this.rrDv,
    required this.rrDv2,
    required this.rrDv3,
    required this.rrIb,
    required this.rrPlb,
    required this.rrB1,
    required this.rrB2,
    required this.rrB3,
    required this.rrB4,
    required this.rrB5,
    required this.rrB6,
    required this.rrB7,
  });

  @override
  AppColorsExtension copyWith({
    Color? rrBg,
    Color? rrBgd,
    Color? rrBgn,
    Color? rrBgc,
    Color? rrCbt,
    Color? rrCb,
    Color? rrCsh,
    Color? rrT1,
    Color? rrT2,
    Color? rrT2b,
    Color? rrT3,
    Color? rrT4,
    Color? rrT5,
    Color? rrT6,
    Color? rrT7,
    Color? rrOv,
    Color? rrPl,
    Color? rrInSurface,
    Color? rrDv,
    Color? rrDv2,
    Color? rrDv3,
    Color? rrIb,
    Color? rrPlb,
    Color? rrB1,
    Color? rrB2,
    Color? rrB3,
    Color? rrB4,
    Color? rrB5,
    Color? rrB6,
    Color? rrB7,
  }) {
    return AppColorsExtension(
      rrBg: rrBg ?? this.rrBg,
      rrBgd: rrBgd ?? this.rrBgd,
      rrBgn: rrBgn ?? this.rrBgn,
      rrBgc: rrBgc ?? this.rrBgc,
      rrCbt: rrCbt ?? this.rrCbt,
      rrCb: rrCb ?? this.rrCb,
      rrCsh: rrCsh ?? this.rrCsh,
      rrT1: rrT1 ?? this.rrT1,
      rrT2: rrT2 ?? this.rrT2,
      rrT2b: rrT2b ?? this.rrT2b,
      rrT3: rrT3 ?? this.rrT3,
      rrT4: rrT4 ?? this.rrT4,
      rrT5: rrT5 ?? this.rrT5,
      rrT6: rrT6 ?? this.rrT6,
      rrT7: rrT7 ?? this.rrT7,
      rrOv: rrOv ?? this.rrOv,
      rrPl: rrPl ?? this.rrPl,
      rrInSurface: rrInSurface ?? this.rrInSurface,
      rrDv: rrDv ?? this.rrDv,
      rrDv2: rrDv2 ?? this.rrDv2,
      rrDv3: rrDv3 ?? this.rrDv3,
      rrIb: rrIb ?? this.rrIb,
      rrPlb: rrPlb ?? this.rrPlb,
      rrB1: rrB1 ?? this.rrB1,
      rrB2: rrB2 ?? this.rrB2,
      rrB3: rrB3 ?? this.rrB3,
      rrB4: rrB4 ?? this.rrB4,
      rrB5: rrB5 ?? this.rrB5,
      rrB6: rrB6 ?? this.rrB6,
      rrB7: rrB7 ?? this.rrB7,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      rrBg: Color.lerp(rrBg, other.rrBg, t)!,
      rrBgd: Color.lerp(rrBgd, other.rrBgd, t)!,
      rrBgn: Color.lerp(rrBgn, other.rrBgn, t)!,
      rrBgc: Color.lerp(rrBgc, other.rrBgc, t)!,
      rrCbt: Color.lerp(rrCbt, other.rrCbt, t)!,
      rrCb: Color.lerp(rrCb, other.rrCb, t)!,
      rrCsh: Color.lerp(rrCsh, other.rrCsh, t)!,
      rrT1: Color.lerp(rrT1, other.rrT1, t)!,
      rrT2: Color.lerp(rrT2, other.rrT2, t)!,
      rrT2b: Color.lerp(rrT2b, other.rrT2b, t)!,
      rrT3: Color.lerp(rrT3, other.rrT3, t)!,
      rrT4: Color.lerp(rrT4, other.rrT4, t)!,
      rrT5: Color.lerp(rrT5, other.rrT5, t)!,
      rrT6: Color.lerp(rrT6, other.rrT6, t)!,
      rrT7: Color.lerp(rrT7, other.rrT7, t)!,
      rrOv: Color.lerp(rrOv, other.rrOv, t)!,
      rrPl: Color.lerp(rrPl, other.rrPl, t)!,
      rrInSurface: Color.lerp(rrInSurface, other.rrInSurface, t)!,
      rrDv: Color.lerp(rrDv, other.rrDv, t)!,
      rrDv2: Color.lerp(rrDv2, other.rrDv2, t)!,
      rrDv3: Color.lerp(rrDv3, other.rrDv3, t)!,
      rrIb: Color.lerp(rrIb, other.rrIb, t)!,
      rrPlb: Color.lerp(rrPlb, other.rrPlb, t)!,
      rrB1: Color.lerp(rrB1, other.rrB1, t)!,
      rrB2: Color.lerp(rrB2, other.rrB2, t)!,
      rrB3: Color.lerp(rrB3, other.rrB3, t)!,
      rrB4: Color.lerp(rrB4, other.rrB4, t)!,
      rrB5: Color.lerp(rrB5, other.rrB5, t)!,
      rrB6: Color.lerp(rrB6, other.rrB6, t)!,
      rrB7: Color.lerp(rrB7, other.rrB7, t)!,
    );
  }
}

// ── AppColors extension on BuildContext ────────────────────────────────────
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  AppColorsExtension get _ext {
    final ext = Theme.of(this).extension<AppColorsExtension>();
    if (ext != null) return ext;
    final d = isDark;
    return AppColorsExtension(
      rrBg: d ? AppColorsDark.bg : AppColorsLight.bg,
      rrBgd: d ? AppColorsDark.bgd : AppColorsLight.bgd,
      rrBgn: d ? AppColorsDark.bgn : AppColorsLight.bgn,
      rrBgc: d ? AppColorsDark.bgc : AppColorsLight.bgc,
      rrCbt: d ? AppColorsDark.cbt : AppColorsLight.cbt,
      rrCb: d ? AppColorsDark.cb : AppColorsLight.cb,
      rrCsh: d ? AppColorsDark.csh : AppColorsLight.csh,
      rrT1: d ? AppColorsDark.t1 : AppColorsLight.t1,
      rrT2: d ? AppColorsDark.t2 : AppColorsLight.t2,
      rrT2b: d ? AppColorsDark.t2b : AppColorsLight.t2b,
      rrT3: d ? AppColorsDark.t3 : AppColorsLight.t3,
      rrT4: d ? AppColorsDark.t4 : AppColorsLight.t4,
      rrT5: d ? AppColorsDark.t5 : AppColorsLight.t5,
      rrT6: d ? AppColorsDark.t6 : AppColorsLight.t6,
      rrT7: d ? AppColorsDark.t7 : AppColorsLight.t7,
      rrOv: d ? AppColorsDark.ov : AppColorsLight.ov,
      rrPl: d ? AppColorsDark.pl : AppColorsLight.pl,
      rrInSurface: d ? AppColorsDark.inSurface : AppColorsLight.inSurface,
      rrDv: d ? AppColorsDark.dv : AppColorsLight.dv,
      rrDv2: d ? AppColorsDark.dv2 : AppColorsLight.dv2,
      rrDv3: d ? AppColorsDark.dv3 : AppColorsLight.dv3,
      rrIb: d ? AppColorsDark.ib : AppColorsLight.ib,
      rrPlb: d ? AppColorsDark.plb : AppColorsLight.plb,
      rrB1: d ? AppColorsDark.b1 : AppColorsLight.b1,
      rrB2: d ? AppColorsDark.b2 : AppColorsLight.b2,
      rrB3: d ? AppColorsDark.b3 : AppColorsLight.b3,
      rrB4: d ? AppColorsDark.b4 : AppColorsLight.b4,
      rrB5: d ? AppColorsDark.b5 : AppColorsLight.b5,
      rrB6: d ? AppColorsDark.b6 : AppColorsLight.b6,
      rrB7: d ? AppColorsDark.b7 : AppColorsLight.b7,
    );
  }

  Color get rrBg => _ext.rrBg;
  Color get rrBgd => _ext.rrBgd;
  Color get rrBgn => _ext.rrBgn;
  Color get rrBgc => _ext.rrBgc;
  Color get rrCbt => _ext.rrCbt;
  Color get rrCb => _ext.rrCb;
  Color get rrCsh => _ext.rrCsh;
  Color get rrT1 => _ext.rrT1;
  Color get rrT2 => _ext.rrT2;
  Color get rrT2b => _ext.rrT2b;
  Color get rrT3 => _ext.rrT3;
  Color get rrT4 => _ext.rrT4;
  Color get rrT5 => _ext.rrT5;
  Color get rrT6 => _ext.rrT6;
  Color get rrT7 => _ext.rrT7;
  Color get rrOv => _ext.rrOv;
  Color get rrPl => _ext.rrPl;
  Color get rrIn => _ext.rrInSurface;
  Color get rrDv => _ext.rrDv;
  Color get rrDv2 => _ext.rrDv2;
  Color get rrDv3 => _ext.rrDv3;
  Color get rrIb => _ext.rrIb;
  Color get rrPlb => _ext.rrPlb;
  Color get rrB1 => _ext.rrB1;
  Color get rrB2 => _ext.rrB2;
  Color get rrB3 => _ext.rrB3;
  Color get rrB4 => _ext.rrB4;
  Color get rrB5 => _ext.rrB5;
  Color get rrB6 => _ext.rrB6;
  Color get rrB7 => _ext.rrB7;
}

// ── ThemeData factories ────────────────────────────────────────────────────
abstract final class AppTheme {
  static ThemeData dark()  => _build(Brightness.dark,  AppColorsDark.bg);
  static ThemeData light() => _build(Brightness.light, AppColorsLight.bg);

  static ThemeData _build(Brightness brightness, Color scaffoldBg) {
    final base = ThemeData(brightness: brightness);
    final isDark = brightness == Brightness.dark;
    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor:    isDark ? AppColorsDark.t1 : AppColorsLight.t1,
        displayColor: isDark ? AppColorsDark.t1 : AppColorsLight.t1,
      ),
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: AppColors.indigo,
        surface: isDark ? AppColorsDark.bgc : AppColorsLight.bgc,
      ),
      extensions: [
        AppColorsExtension(
          rrBg: isDark ? AppColorsDark.bg : AppColorsLight.bg,
          rrBgd: isDark ? AppColorsDark.bgd : AppColorsLight.bgd,
          rrBgn: isDark ? AppColorsDark.bgn : AppColorsLight.bgn,
          rrBgc: isDark ? AppColorsDark.bgc : AppColorsLight.bgc,
          rrCbt: isDark ? AppColorsDark.cbt : AppColorsLight.cbt,
          rrCb: isDark ? AppColorsDark.cb : AppColorsLight.cb,
          rrCsh: isDark ? AppColorsDark.csh : AppColorsLight.csh,
          rrT1: isDark ? AppColorsDark.t1 : AppColorsLight.t1,
          rrT2: isDark ? AppColorsDark.t2 : AppColorsLight.t2,
          rrT2b: isDark ? AppColorsDark.t2b : AppColorsLight.t2b,
          rrT3: isDark ? AppColorsDark.t3 : AppColorsLight.t3,
          rrT4: isDark ? AppColorsDark.t4 : AppColorsLight.t4,
          rrT5: isDark ? AppColorsDark.t5 : AppColorsLight.t5,
          rrT6: isDark ? AppColorsDark.t6 : AppColorsLight.t6,
          rrT7: isDark ? AppColorsDark.t7 : AppColorsLight.t7,
          rrOv: isDark ? AppColorsDark.ov : AppColorsLight.ov,
          rrPl: isDark ? AppColorsDark.pl : AppColorsLight.pl,
          rrInSurface: isDark ? AppColorsDark.inSurface : AppColorsLight.inSurface,
          rrDv: isDark ? AppColorsDark.dv : AppColorsLight.dv,
          rrDv2: isDark ? AppColorsDark.dv2 : AppColorsLight.dv2,
          rrDv3: isDark ? AppColorsDark.dv3 : AppColorsLight.dv3,
          rrIb: isDark ? AppColorsDark.ib : AppColorsLight.ib,
          rrPlb: isDark ? AppColorsDark.plb : AppColorsLight.plb,
          rrB1: isDark ? AppColorsDark.b1 : AppColorsLight.b1,
          rrB2: isDark ? AppColorsDark.b2 : AppColorsLight.b2,
          rrB3: isDark ? AppColorsDark.b3 : AppColorsLight.b3,
          rrB4: isDark ? AppColorsDark.b4 : AppColorsLight.b4,
          rrB5: isDark ? AppColorsDark.b5 : AppColorsLight.b5,
          rrB6: isDark ? AppColorsDark.b6 : AppColorsLight.b6,
          rrB7: isDark ? AppColorsDark.b7 : AppColorsLight.b7,
        ),
      ],
    );
  }
}
