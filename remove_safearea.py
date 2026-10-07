import os
import re

files_to_update = [
    "lib/screens/home_screen.dart",
    "lib/screens/trend_screen.dart",
    "lib/screens/settings_screen.dart",
    "lib/screens/support_screen.dart"
]

def remove_safearea(content):
    # Find SafeArea(child: Padding(padding: EdgeInsets.only(left: 20, right: 20, top: 20), child: SingleChildScrollView(
    # or similar and replace it.
    pass

# Let's just do targeted string replacements since there's only 1 or 2 per file.

# home_screen.dart
with open("lib/screens/home_screen.dart", "r") as f:
    home = f.read()
home = home.replace(
    "          SafeArea(\n            child: Padding(\n              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),\n              child: SingleChildScrollView(",
    "          Positioned.fill(\n            child: SingleChildScrollView(\n              padding: EdgeInsets.only(left: 20, right: 20, top: MediaQuery.of(context).padding.top + 20, bottom: 120),"
)
# We also need to remove the closing brackets for SafeArea and Padding
# So instead of regex, let's just replace the exact text
home = home.replace("            ),\n          ),\n        ],\n      ),\n    );", "            ),\n        ],\n      ),\n    );")
with open("lib/screens/home_screen.dart", "w") as f: f.write(home)


# trend_screen.dart
with open("lib/screens/trend_screen.dart", "r") as f:
    trend = f.read()
trend = trend.replace(
    "      body: SafeArea(\n        child: Padding(\n          padding: const EdgeInsets.only(left: 20, right: 20, top: 20),\n          child: CustomScrollView(",
    "      body: CustomScrollView(\n          padding: EdgeInsets.only(left: 20, right: 20, top: MediaQuery.of(context).padding.top + 20, bottom: 120),"
)
trend = trend.replace("          ),\n        ),\n      ),\n    );", "      ),\n    );")
with open("lib/screens/trend_screen.dart", "w") as f: f.write(trend)


# settings_screen.dart
with open("lib/screens/settings_screen.dart", "r") as f:
    settings = f.read()
settings = settings.replace(
    "      body: SafeArea(\n        child: Padding(\n          padding: const EdgeInsets.only(left: 20, right: 20, top: 20),\n          child: SingleChildScrollView(",
    "      body: SingleChildScrollView(\n          padding: EdgeInsets.only(left: 20, right: 20, top: MediaQuery.of(context).padding.top + 20, bottom: 120),"
)
settings = settings.replace("          ),\n        ),\n      ),\n    );", "      ),\n    );")
with open("lib/screens/settings_screen.dart", "w") as f: f.write(settings)


# support_screen.dart
with open("lib/screens/support_screen.dart", "r") as f:
    support = f.read()
support = support.replace(
    "      body: SafeArea(\n        child: Padding(\n          padding: const EdgeInsets.only(left: 20, right: 20, top: 20),\n          child: SingleChildScrollView(",
    "      body: SingleChildScrollView(\n          padding: EdgeInsets.only(left: 20, right: 20, top: MediaQuery.of(context).padding.top + 20, bottom: 120),"
)
support = support.replace("          ),\n        ),\n      ),\n    );", "      ),\n    );")
with open("lib/screens/support_screen.dart", "w") as f: f.write(support)

print("Updated screens")
