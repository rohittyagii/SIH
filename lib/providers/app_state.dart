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

final scoresProvider = StateProvider<Map<DimKey, int>>((ref) => {
  DimKey.overall:  0,
  DimKey.sleep:    0,
  DimKey.physical: 0,
  DimKey.focus:    0,
});

// ── History provider ────────────────────────────────────────────────────────
final historyProvider = StateProvider<List<Entry>>((ref) => List.from(seedHistory));

// ── Actions (pure functions, no duplication) ────────────────────────────────

/// Reset scores to zero
Map<DimKey, int> emptyScores() => {
  DimKey.overall: 0, DimKey.sleep: 0, DimKey.physical: 0, DimKey.focus: 0,
};

/// Build a new Entry from current scores + note
Entry buildEntry(Map<DimKey, int> scores, String note) => Entry(
  date:     'Thu, Sep 4',
  overall:  scores[DimKey.overall]!,
  sleep:    scores[DimKey.sleep]!,
  physical: scores[DimKey.physical]!,
  focus:    scores[DimKey.focus]!,
  note:     note,
);
