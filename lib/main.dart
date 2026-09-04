import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/colors.dart';
import 'providers/app_state.dart';
import 'widgets/bottom_nav.dart';
import 'screens/pin_screen.dart';
import 'screens/activation_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/home_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/submitted_screen.dart';
import 'screens/trend_screen.dart';
import 'screens/support_screen.dart';
import 'screens/settings_screen.dart';
import 'data/seed.dart';

void main() {
  runApp(const ProviderScope(child: SainikSaathiApp()));
}

// ── Root app ────────────────────────────────────────────────────────────────
class SainikSaathiApp extends ConsumerWidget {
  const SainikSaathiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    return MaterialApp(
      title: 'SainikSaathi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const _AppShell(),
    );
  }
}

// ── App shell — handles top-level screen routing ────────────────────────────
class _AppShell extends ConsumerWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(screenProvider);

    switch (screen) {
      case AppScreen.pin:
        return PinScreen(
          onUnlocked: ()  => ref.read(screenProvider.notifier).state = AppScreen.app,
          onSetupNew: ()  => ref.read(screenProvider.notifier).state = AppScreen.activation,
        );

      case AppScreen.activation:
        return ActivationScreen(
          onActivated: () => ref.read(screenProvider.notifier).state = AppScreen.consent,
        );

      case AppScreen.consent:
        return ConsentScreen(
          onAgree: () => ref.read(screenProvider.notifier).state = AppScreen.app,
        );

      case AppScreen.app:
        return const _MainApp();
    }
  }
}

// ── Main app — bottom-tab shell + check-in overlays ─────────────────────────
class _MainApp extends ConsumerWidget {
  const _MainApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab        = ref.watch(tabProvider);
    final inCheckin  = ref.watch(inCheckinProvider);
    final submitted  = ref.watch(submittedProvider);
    final todayDone  = ref.watch(todayDoneProvider);
    final scores     = ref.watch(scoresProvider);
    final note       = ref.watch(noteProvider);
    final history    = ref.watch(historyProvider);
    final isDark     = ref.watch(themeProvider);

    // ── Check-in active ────────────────────────────────────────────────────
    if (inCheckin && !submitted) {
      return CheckinScreen(
        scores: scores,
        note:   note,
        onScoreChanged: (k, n) {
          final next = Map<DimKey, int>.from(scores)..[k] = n;
          ref.read(scoresProvider.notifier).state = next;
        },
        onNoteChanged: (s) => ref.read(noteProvider.notifier).state = s,
        onSubmit: () {
          ref.read(historyProvider.notifier).state = [buildEntry(scores, note), ...history];
          ref.read(inCheckinProvider.notifier).state  = false;
          ref.read(submittedProvider.notifier).state  = true;
          ref.read(todayDoneProvider.notifier).state  = true;
        },
        onBack: () => ref.read(inCheckinProvider.notifier).state = false,
      );
    }

    // ── Submitted ──────────────────────────────────────────────────────────
    if (submitted) {
      return SubmittedScreen(
        scores: scores,
        note:   note,
        onDone: () {
          ref.read(submittedProvider.notifier).state = false;
          ref.read(tabProvider.notifier).state = AppTab.home;
        },
      );
    }

    // ── Normal tab layout ──────────────────────────────────────────────────
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _tabBody(context, ref, tab, history, todayDone, isDark)),
          BottomNav(
            active: tab,
            onTab:  (t) => ref.read(tabProvider.notifier).state = t,
          ),
        ],
      ),
    );
  }

  Widget _tabBody(
    BuildContext context, WidgetRef ref, AppTab tab,
    List<Entry> history, bool todayDone, bool isDark,
  ) {
    switch (tab) {
      case AppTab.home:
        return HomeScreen(
          todayDone: todayDone,
          onTab: (t) => ref.read(tabProvider.notifier).state = t,
          onStartCheckin: () {
            if (todayDone) {
              ref.read(submittedProvider.notifier).state = true;
            } else {
              ref.read(scoresProvider.notifier).state = emptyScores();
              ref.read(noteProvider.notifier).state   = '';
              ref.read(inCheckinProvider.notifier).state = true;
            }
          },
        );

      case AppTab.trend:
        return TrendScreen(history: history);

      case AppTab.support:
        return const SupportScreen();

      case AppTab.settings:
        return SettingsScreen(
          isDark: isDark,
          onThemeToggle: () =>
              ref.read(themeProvider.notifier).state = !ref.read(themeProvider),
          onLogout: () {
            ref.read(inCheckinProvider.notifier).state  = false;
            ref.read(submittedProvider.notifier).state  = false;
            ref.read(tabProvider.notifier).state        = AppTab.home;
            ref.read(screenProvider.notifier).state     = AppScreen.pin;
          },
        );
    }
  }
}
