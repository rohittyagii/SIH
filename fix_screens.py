import re

# 1. home_screen.dart
with open("lib/screens/home_screen.dart", "r") as f:
    content = f.read()
# Replace SafeArea + Padding with Positioned.fill + Padding
content = content.replace(
    "          SafeArea(\n            child: Padding(\n              padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),",
    "          Positioned.fill(\n            child: Padding(\n              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 52, 20, 120),"
)
# We don't remove brackets at the bottom since we replaced SafeArea with Positioned.fill directly. They match 1:1 in bracket structure!
with open("lib/screens/home_screen.dart", "w") as f:
    f.write(content)

# 2. trend_screen.dart
with open("lib/screens/trend_screen.dart", "r") as f:
    content = f.read()
content = content.replace(
    "      body: SafeArea(\n        child: SingleChildScrollView(\n          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),",
    "      body: SingleChildScrollView(\n        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 24, 16, 120),"
)
content = content.replace(
    "        ),\n      ),\n    );",
    "      ),\n    );"
)
with open("lib/screens/trend_screen.dart", "w") as f:
    f.write(content)

# 3. support_screen.dart
with open("lib/screens/support_screen.dart", "r") as f:
    content = f.read()
content = content.replace(
    "      body: SafeArea(\n        child: SingleChildScrollView(\n          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),",
    "      body: SingleChildScrollView(\n        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 24, 16, 120),"
)
content = content.replace(
    "        ),\n      ),\n    );",
    "      ),\n    );"
)
with open("lib/screens/support_screen.dart", "w") as f:
    f.write(content)

# 4. settings_screen.dart
with open("lib/screens/settings_screen.dart", "r") as f:
    content = f.read()
content = content.replace(
    "      body: SafeArea(\n        child: SingleChildScrollView(\n          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),",
    "      body: SingleChildScrollView(\n        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 24, 16, 120),"
)
content = content.replace(
    "        ),\n      ),\n    );",
    "      ),\n    );"
)
with open("lib/screens/settings_screen.dart", "w") as f:
    f.write(content)

print("Fixed screens safely")
