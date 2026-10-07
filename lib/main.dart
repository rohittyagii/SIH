import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'services/checkin_service.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // We need a ProviderContainer to init SyncService before runApp if we want to do it here,
  // or we can init SyncService's Hive stuff inside a Riverpod hook or async main.
  final container = ProviderContainer();
  final syncService = container.read(syncServiceProvider);
  await syncService.init();

  // Initialise in-app notifications (daily reminders).
  final notifService = container.read(notificationServiceProvider);
  await notifService.init();

  // When user taps the reminder notification → open check-in.
  NotificationService.onNotificationTap = (_) {
    final screen = container.read(screenProvider);
    if (screen == AppScreen.app) {
      final todayDone = container.read(todayDoneProvider);
      if (todayDone) {
        container.read(submittedProvider.notifier).state = true;
      } else {
        container.read(scoresProvider.notifier).state = emptyScores();
        container.read(noteProvider.notifier).state = '';
        container.read(inCheckinProvider.notifier).state = true;
      }
    }
  };

  runApp(UncontrolledProviderScope(
    container: container,
    child: const SainikSaathiApp(),
  ));
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
      themeAnimationDuration: const Duration(milliseconds: 600),
      themeAnimationCurve: Curves.easeInOutCubic,
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.of(context)
                    .textScaler
                    .clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2),
              ),
              child: child!,
            ),
          ),
        );
      },
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

    Widget content;
    switch (screen) {
      case AppScreen.pin:
        content = PinScreen(
          key: const ValueKey('pin'),
          onUnlocked: () =>
              ref.read(screenProvider.notifier).state = AppScreen.app,
          onSetupNew: () =>
              ref.read(screenProvider.notifier).state = AppScreen.activation,
        );
        break;

      case AppScreen.activation:
        content = ActivationScreen(
          key: const ValueKey('activation'),
          onActivated: () =>
              ref.read(screenProvider.notifier).state = AppScreen.consent,
        );
        break;

      case AppScreen.consent:
        content = ConsentScreen(
          key: const ValueKey('consent'),
          onAgree: () =>
              ref.read(screenProvider.notifier).state = AppScreen.app,
        );
        break;

      case AppScreen.app:
        content = const _MainApp(key: ValueKey('app'));
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: content,
    );
  }
}

// ── Main app — bottom-tab shell + check-in overlays ─────────────────────────
class _MainApp extends ConsumerStatefulWidget {
  const _MainApp({super.key});

  @override
  ConsumerState<_MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<_MainApp> {
  @override
  void initState() {
    super.initState();
    // Refresh history and status on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    const storage = FlutterSecureStorage();
    final uName = await storage.read(key: 'user_name');
    if (uName != null) {
      ref.read(userNameProvider.notifier).state = uName;
    }
    final lang = await storage.read(key: 'language_pref');
    if (lang != null) {
      ref.read(languagePrefProvider.notifier).state = lang;
    }

    try {
      final syncSvc = ref.read(syncServiceProvider);
      await syncSvc.syncIfOnline();

      final chkSvc = ref.read(checkinServiceProvider);
      final todayStatus = await chkSvc.checkTodayStatus();
      if (todayStatus['has_checked_in'] == true) {
        ref.read(todayDoneProvider.notifier).state = true;
      }

      final historyRaw = await chkSvc.getHistory();
      final history = historyRaw
          .map((e) => Entry(
                date: e['checkin_date'],
                overall: e['overall_score'],
                sleep: e['sleep_score'],
                physical: e['physical_score'],
                focus: e['focus_score'],
                note: e['note'] ?? '',
              ))
          .toList();
      ref.read(historyProvider.notifier).state = history;

      // Enforce once-per-day locally: if any loaded entry matches today, mark done.
      if (!ref.read(todayDoneProvider)) {
        final todayStr = _todayIso();
        final matchesToday = history.any((e) => _entryMatchesDate(e.date, todayStr));
        if (matchesToday) {
          ref.read(todayDoneProvider.notifier).state = true;
        }
      }
    } catch (e) {
      // Ignored for now, keep seed history if offline
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(tabProvider);
    final inCheckin = ref.watch(inCheckinProvider);
    final submitted = ref.watch(submittedProvider);
    final todayDone = ref.watch(todayDoneProvider);
    final scores = ref.watch(scoresProvider);
    final note = ref.watch(noteProvider);
    final history = ref.watch(historyProvider);
    final isDark = ref.watch(themeProvider);
    final streak = ref.watch(streakProvider);

    // ── Build Main Content ─────────────────────────────────────────────────
    Widget mainContent;

    if (inCheckin && !submitted) {
      mainContent = CheckinScreen(
        key: const ValueKey('checkin'),
        scores: scores,
        note: note,
        onScoreChanged: (k, n) {
          final next = Map<DimKey, int>.from(scores)..[k] = n;
          ref.read(scoresProvider.notifier).state = next;
        },
        onNoteChanged: (s) => ref.read(noteProvider.notifier).state = s,
        onSubmit: () async {
          try {
            final chkSvc = ref.read(checkinServiceProvider);
            await chkSvc.submitCheckin(
              overall: scores[DimKey.overall]!,
              sleep: scores[DimKey.sleep]!,
              physical: scores[DimKey.physical]!,
              focus: scores[DimKey.focus]!,
              note: note,
            );
          } catch (e) {
            final syncSvc = ref.read(syncServiceProvider);
            await syncSvc.saveOfflineCheckin({
              'overall_score': scores[DimKey.overall]!,
              'sleep_score': scores[DimKey.sleep]!,
              'physical_score': scores[DimKey.physical]!,
              'focus_score': scores[DimKey.focus]!,
              'note': note,
            });
          }

          ref.read(historyProvider.notifier).state = [
            buildEntry(scores, note),
            ...history
          ];
          ref.read(inCheckinProvider.notifier).state = false;
          ref.read(submittedProvider.notifier).state = true;
          ref.read(todayDoneProvider.notifier).state = true;
        },
        onBack: () => ref.read(inCheckinProvider.notifier).state = false,
      );
    } else if (submitted) {
      mainContent = SubmittedScreen(
        key: const ValueKey('submitted'),
        scores: scores,
        note: note,
        onDone: () {
          ref.read(submittedProvider.notifier).state = false;
          ref.read(tabProvider.notifier).state = AppTab.home;
        },
      );
    } else {
      mainContent = Scaffold(
        key: const ValueKey('tabs'),
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: context.rrBg,
        body: Stack(
          children: [
            // 1. The Tabs Content (now directly in Stack to go edge-to-edge)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(tab),
                child: _tabBody(context, ref, tab, history, todayDone, isDark, streak),
              ),
            ),
            
            // 2. Top Blurry Gradient Mask (for status bar legibility)
            Positioned(
              top: 0, left: 0, right: 0,
              height: MediaQuery.of(context).padding.top + 32,
              child: IgnorePointer(
                child: ClipRect(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.transparent],
                      stops: [0.3, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: Container(color: context.rrBg.withOpacity(0.6)),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Bottom Blurry Gradient Mask (so content smoothly vanishes under nav island)
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 120, 
              child: IgnorePointer(
                child: ClipRect(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.transparent],
                      stops: [0.1, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: Container(color: context.rrBg.withOpacity(0.6)),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Floating Navigation Island
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNav(
                active: tab,
                onTab: (t) => ref.read(tabProvider.notifier).state = t,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: mainContent,
    );
  }

  Widget _tabBody(
    BuildContext context,
    WidgetRef ref,
    AppTab tab,
    List<Entry> history,
    bool todayDone,
    bool isDark,
    int streak,
  ) {
    switch (tab) {
      case AppTab.home:
        return HomeScreen(
          todayDone: todayDone,
          streak: streak,
          onTab: (t) => ref.read(tabProvider.notifier).state = t,
          onStartCheckin: () {
            if (todayDone) {
              ref.read(submittedProvider.notifier).state = true;
            } else {
              ref.read(scoresProvider.notifier).state = emptyScores();
              ref.read(noteProvider.notifier).state = '';
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
          onLogout: () async {
            try {
              await ref.read(authServiceProvider).logout();
            } catch (_) {}
            ref.read(inCheckinProvider.notifier).state = false;
            ref.read(submittedProvider.notifier).state = false;
            ref.read(tabProvider.notifier).state = AppTab.home;
            ref.read(screenProvider.notifier).state = AppScreen.pin;
          },
        );
    }
  }
}

// ── Helpers for once-per-day local enforcement ───────────────────────────────

/// Returns today's date as an ISO string, e.g. "2026-09-11".
String _todayIso() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

/// Returns true if [entryDate] (ISO "2026-09-11" OR friendly "Thu, Sep 11")
/// refers to the same calendar day as [todayIso].
bool _entryMatchesDate(String entryDate, String todayIso) {
  // ISO format
  if (entryDate == todayIso) return true;
  // Friendly format: "Thu, Sep 11"
  const months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };
  try {
    final stripped = entryDate.replaceAll(',', '').trim();
    final parts = stripped.split(' ');
    final dateParts = parts.length == 3 ? parts.sublist(1) : parts;
    final month = months[dateParts[0]];
    final day = int.parse(dateParts[1]);
    if (month == null) return false;
    final now = DateTime.now();
    return now.month == month && now.day == day;
  } catch (_) {
    return false;
  }
}
