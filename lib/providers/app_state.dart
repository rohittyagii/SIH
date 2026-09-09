import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/seed.dart';
import '../widgets/bottom_nav.dart';

// ── App screens (top-level navigation) ────────────────────────────────────
enum AppScreen { pin, activation, consent, app }

// ── Theme provider ─────────────────────────────────────────────────────────
final themeProvider = StateProvider<bool>((ref) => true); // true = dark

// ── Active screen provider ─────────────────────────────────────────────────
final screenProvider = StateProvider<AppScreen>((ref) => AppScreen.pin);

// ── Active bottom-tab provider ─────────────────────────────────────────────
final tabProvider = StateProvider<AppTab>((ref) => AppTab.home);

// ── Check-in state ─────────────────────────────────────────────────────────
final inCheckinProvider  = StateProvider<bool>((ref) => false);
final submittedProvider  = StateProvider<bool>((ref) => false);
final todayDoneProvider  = StateProvider<bool>((ref) => false);
final noteProvider       = StateProvider<String>((ref) => '');
final userNameProvider   = StateProvider<String?>((ref) => null);
final languagePrefProvider = StateProvider<String>((ref) => 'en-GB');

final scoresProvider = StateProvider<Map<DimKey, int>>((ref) => {
  DimKey.overall:  0,
  DimKey.sleep:    0,
  DimKey.physical: 0,
  DimKey.focus:    0,
});

// ── History provider ────────────────────────────────────────────────────────
final historyProvider = StateProvider<List<Entry>>((ref) => List.from(seedHistory));

// ── Streak provider — consecutive daily check-ins counting back from today ──
final streakProvider = Provider<int>((ref) {
  final history = ref.watch(historyProvider);
  if (history.isEmpty) return 0;

  int streak = 0;
  var cursor = DateTime.now();
  cursor = DateTime(cursor.year, cursor.month, cursor.day);

  for (final entry in history) {
    final entryDate = _parseEntryDate(entry.date);
    if (entryDate == null) break;
    final diff = cursor.difference(entryDate).inDays;
    if (diff == 0 || diff == streak) {
      streak++;
      cursor = entryDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return streak;
});

/// Tries to parse entry date strings in multiple formats.
DateTime? _parseEntryDate(String raw) {
  // ISO format: "2026-09-04"
  try {
    final parts = raw.split('-');
    if (parts.length == 3) {
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }
  } catch (_) {}
  // Friendly format: "Wed, Sep 3"
  const months = {
    'Jan': 1, 'Feb': 2,  'Mar': 3,  'Apr': 4,
    'May': 5, 'Jun': 6,  'Jul': 7,  'Aug': 8,
    'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };
  try {
    final stripped = raw.replaceAll(',', '').trim();
    final parts    = stripped.split(' ');
    final dateParts = parts.length == 3 ? parts.sublist(1) : parts;
    final month = months[dateParts[0]];
    final day   = int.parse(dateParts[1]);
    if (month == null) return null;
    return DateTime(DateTime.now().year, month, day);
  } catch (_) {
    return null;
  }
}

// ── Actions ─────────────────────────────────────────────────────────────────

Map<DimKey, int> emptyScores() => {
  DimKey.overall: 0, DimKey.sleep: 0, DimKey.physical: 0, DimKey.focus: 0,
};

/// Build an Entry stamped with today's real date.
Entry buildEntry(Map<DimKey, int> scores, String note) {
  final now    = DateTime.now();
  const days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final label = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  return Entry(
    date:     label,
    overall:  scores[DimKey.overall]!,
    sleep:    scores[DimKey.sleep]!,
    physical: scores[DimKey.physical]!,
    focus:    scores[DimKey.focus]!,
    note:     note,
  );
}
