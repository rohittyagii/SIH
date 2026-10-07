import re

with open("lib/theme/colors.dart", "r") as f:
    content = f.read()

colors = [
    "bg", "bgd", "bgn", "bgc", "cbt", "cb", "csh",
    "t1", "t2", "t2b", "t3", "t4", "t5", "t6", "t7",
    "ov", "pl", "inSurface", "dv", "dv2", "dv3",
    "ib", "plb", "b1", "b2", "b3", "b4", "b5", "b6", "b7"
]

def capitalize(s):
    return s[0].upper() + s[1:]

fallback_str = "  AppColorsExtension get _ext {\n    final ext = Theme.of(this).extension<AppColorsExtension>();\n    if (ext != null) return ext;\n    final d = isDark;\n    return AppColorsExtension(\n"
for c in colors:
    fallback_str += f"      rr{capitalize(c)}: d ? AppColorsDark.{c} : AppColorsLight.{c},\n"
fallback_str += "    );\n  }\n"

content = content.replace("  AppColorsExtension get _ext => Theme.of(this).extension<AppColorsExtension>()!;\n", fallback_str)

with open("lib/theme/colors.dart", "w") as f:
    f.write(content)

print("Fixed")
