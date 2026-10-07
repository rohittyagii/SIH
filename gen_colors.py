import re

colors = [
    "bg", "bgd", "bgn", "bgc", "cbt", "cb", "csh",
    "t1", "t2", "t2b", "t3", "t4", "t5", "t6", "t7",
    "ov", "pl", "inSurface", "dv", "dv2", "dv3",
    "ib", "plb", "b1", "b2", "b3", "b4", "b5", "b6", "b7"
]

def capitalize(s):
    return s[0].upper() + s[1:]

with open("lib/theme/colors.dart", "r") as f:
    content = f.read()

# We'll replace everything from "extension AppColorsX on BuildContext" to the end
parts = content.split("// ── AppColors extension on BuildContext ────────────────────────────────────")
header = parts[0]

output = header + "// ── AppColors Extension ───────────────────────────────────────────────────\n"
output += "class AppColorsExtension extends ThemeExtension<AppColorsExtension> {\n"
for c in colors:
    output += f"  final Color rr{capitalize(c)};\n"

output += "\n  const AppColorsExtension({\n"
for c in colors:
    output += f"    required this.rr{capitalize(c)},\n"
output += "  });\n\n"

output += "  @override\n"
output += "  AppColorsExtension copyWith({\n"
for c in colors:
    output += f"    Color? rr{capitalize(c)},\n"
output += "  }) {\n"
output += "    return AppColorsExtension(\n"
for c in colors:
    output += f"      rr{capitalize(c)}: rr{capitalize(c)} ?? this.rr{capitalize(c)},\n"
output += "    );\n  }\n\n"

output += "  @override\n"
output += "  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {\n"
output += "    if (other is! AppColorsExtension) return this;\n"
output += "    return AppColorsExtension(\n"
for c in colors:
    output += f"      rr{capitalize(c)}: Color.lerp(rr{capitalize(c)}, other.rr{capitalize(c)}, t)!,\n"
output += "    );\n  }\n}\n\n"

output += "// ── AppColors extension on BuildContext ────────────────────────────────────\n"
output += "extension AppColorsX on BuildContext {\n"
output += "  bool get isDark => Theme.of(this).brightness == Brightness.dark;\n"
output += "  AppColorsExtension get _ext => Theme.of(this).extension<AppColorsExtension>()!;\n\n"
for c in colors:
    output += f"  Color get rr{capitalize(c)} => _ext.rr{capitalize(c)};\n"
output += "}\n\n"

output += "// ── ThemeData factories ────────────────────────────────────────────────────\n"
output += "abstract final class AppTheme {\n"
output += "  static ThemeData dark()  => _build(Brightness.dark,  AppColorsDark.bg);\n"
output += "  static ThemeData light() => _build(Brightness.light, AppColorsLight.bg);\n\n"
output += "  static ThemeData _build(Brightness brightness, Color scaffoldBg) {\n"
output += "    final base = ThemeData(brightness: brightness);\n"
output += "    final isDark = brightness == Brightness.dark;\n"
output += "    return base.copyWith(\n"
output += "      scaffoldBackgroundColor: scaffoldBg,\n"
output += "      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(\n"
output += "        bodyColor:    isDark ? AppColorsDark.t1 : AppColorsLight.t1,\n"
output += "        displayColor: isDark ? AppColorsDark.t1 : AppColorsLight.t1,\n"
output += "      ),\n"
output += "      colorScheme: ColorScheme.fromSeed(\n"
output += "        brightness: brightness,\n"
output += "        seedColor: AppColors.indigo,\n"
output += "        surface: isDark ? AppColorsDark.bgc : AppColorsLight.bgc,\n"
output += "      ),\n"
output += "      extensions: [\n"
output += "        AppColorsExtension(\n"
for c in colors:
    output += f"          rr{capitalize(c)}: isDark ? AppColorsDark.{c} : AppColorsLight.{c},\n"
output += "        ),\n"
output += "      ],\n"
output += "    );\n"
output += "  }\n}\n"

with open("lib/theme/colors.dart", "w") as f:
    f.write(output)

print("Done generating colors.dart")
