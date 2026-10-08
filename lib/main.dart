// We import the 'ui' library from dart to use things like ImageFilter for blurring effects.
import 'dart:ui' as ui;
// We import the core Flutter material design library, which gives us widgets like Scaffold, MaterialApp, etc.
import 'package:flutter/material.dart';
// We import Riverpod, which is a state management library used to manage the app's state.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// We import flutter_secure_storage to securely store small pieces of data, like user tokens or preferences.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// We import our custom colors and theme settings from the theme folder.
import 'theme/colors.dart';
// We import our application state providers, which hold the current state of our app using Riverpod.
import 'providers/app_state.dart';
// We import the custom bottom navigation bar widget used in the app.
import 'widgets/bottom_nav.dart';
// We import the PIN screen, where users enter their security PIN to access the app.
import 'screens/pin_screen.dart';
// We import the activation screen, used when setting up the app for the first time.
import 'screens/activation_screen.dart';
// We import the consent screen, where users agree to the terms or privacy policy.
import 'screens/consent_screen.dart';
// We import the home screen, which is the main dashboard of the app.
import 'screens/home_screen.dart';
// We import the check-in screen, where users can log their daily status.
import 'screens/checkin_screen.dart';
// We import the submitted screen, shown after a user successfully submits their check-in.
import 'screens/submitted_screen.dart';
// We import the trend screen, which shows the user's historical check-in data.
import 'screens/trend_screen.dart';
// We import the support screen, containing help and support resources.
import 'screens/support_screen.dart';
// We import the settings screen, where users can configure app preferences like themes.
import 'screens/settings_screen.dart';
// We import the seed data file, which likely contains some initial or mock data for the app.
import 'data/seed.dart';
// We import the check-in service, which handles the logic for fetching and submitting check-in data.
import 'services/checkin_service.dart';
// We import the sync service, responsible for syncing offline data with the server when back online.
import 'services/sync_service.dart';
// We import the authentication service, which handles user login, logout, and session management.
import 'services/auth_service.dart';
// We import the notification service, which handles in-app and push notifications.
import 'services/notification_service.dart';

// The main function is the starting point of any Flutter application.
// We mark it as 'async' because we need to wait for some background tasks to finish before starting the app.
void main() async {
  // We ensure that the Flutter engine is properly initialized before running any code that relies on it.
  WidgetsFlutterBinding.ensureInitialized();

  // We need a ProviderContainer to init SyncService before runApp if we want to do it here,
  // or we can init SyncService's Hive stuff inside a Riverpod hook or async main.
  // We create a ProviderContainer, which holds the state of all Riverpod providers.
  final container = ProviderContainer();
  // We read the syncServiceProvider from the container to get an instance of the SyncService.
  final syncService = container.read(syncServiceProvider);
  // We initialize the SyncService asynchronously. This might setup local databases like Hive.
  await syncService.init();

  // Initialise in-app notifications (daily reminders).
  // We read the notificationServiceProvider to get an instance of NotificationService.
  final notifService = container.read(notificationServiceProvider);
  // We initialize the NotificationService asynchronously to set up things like notification channels.
  await notifService.init();

  // When user taps the reminder notification → open check-in.
  // We define what happens when the user taps on a notification using a callback function.
  NotificationService.onNotificationTap = (_) {
    // We read the current screen from the state.
    final screen = container.read(screenProvider);
    // We check if the app is currently showing the main 'app' screen (not login, etc.).
    if (screen == AppScreen.app) {
      // We check if the user has already done their check-in today.
      final todayDone = container.read(todayDoneProvider);
      // If they have already done it...
      if (todayDone) {
        // ...we set the submittedProvider state to true, which will show the 'already submitted' screen.
        container.read(submittedProvider.notifier).state = true;
      } else {
        // If they haven't done it yet, we reset their scores to empty.
        container.read(scoresProvider.notifier).state = emptyScores();
        // We clear any existing note.
        container.read(noteProvider.notifier).state = '';
        // We set the inCheckinProvider state to true, which opens the check-in screen.
        container.read(inCheckinProvider.notifier).state = true;
      }
    }
  };

  // Finally, we start the Flutter app by calling runApp.
  // UncontrolledProviderScope wraps the app, allowing us to use the ProviderContainer we created above.
  runApp(UncontrolledProviderScope(
    // We pass our initialized container to the scope.
    container: container,
    // The child is our main application widget, SainikSaathiApp.
    child: const SainikSaathiApp(),
  ));
}

// ── Root app ────────────────────────────────────────────────────────────────
// This is the root widget of the application, defined as a ConsumerWidget so it can read Riverpod providers.
class SainikSaathiApp extends ConsumerWidget {
  // A constant constructor with a super key, typical for Flutter widgets.
  const SainikSaathiApp({super.key});

  // The build method describes how to display this widget in terms of other lower-level widgets.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the themeProvider to see if dark mode is enabled. If it changes, the app rebuilds.
    final isDark = ref.watch(themeProvider);
    // We return a MaterialApp, which sets up the basic material design visual layout.
    return MaterialApp(
      // The title of the application, used in the OS task switcher.
      title: 'SainikSaathi',
      // We set this to false to hide the "DEBUG" banner in the top-right corner.
      debugShowCheckedModeBanner: false,
      // We define the light theme using our custom AppTheme class.
      theme: AppTheme.light(),
      // We define the dark theme using our custom AppTheme class.
      darkTheme: AppTheme.dark(),
      // We set the themeMode based on the isDark variable we read from the provider earlier.
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      // We set the duration for the animation when switching between light and dark themes (600ms).
      themeAnimationDuration: const Duration(milliseconds: 600),
      // We set a smooth easing curve for the theme switching animation.
      themeAnimationCurve: Curves.easeInOutCubic,
      // The builder allows us to modify the widget tree above the navigator.
      builder: (context, child) {
        // We wrap the child in a MediaQuery to override some device-specific settings.
        return MediaQuery(
          // We copy the existing MediaQuery data but clamp the text scale factor.
          // This prevents the text from getting too small (min 0.8) or too large (max 1.2), maintaining layout integrity.
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context)
                .textScaler
                .clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2),
          ),
          // The child is the rest of the application widget tree.
          child: child!,
        );
      },
      // The home property sets the initial route/widget of the app, which is the _AppShell.
      home: const _AppShell(),
    );
  }
}

// ── App shell — handles top-level screen routing ────────────────────────────
// _AppShell is a ConsumerWidget that acts as the main router, switching between top-level screens like PIN, Activation, and the Main App.
class _AppShell extends ConsumerWidget {
  // Constant constructor.
  const _AppShell();

  // The build method for the AppShell.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the screenProvider to know which top-level screen to show right now.
    final screen = ref.watch(screenProvider);

    // We define a variable to hold the widget we want to display.
    Widget content;
    // We use a switch statement to decide which screen to show based on the screen state.
    switch (screen) {
      // If the state is AppScreen.pin...
      case AppScreen.pin:
        // ...we set content to the PinScreen.
        content = PinScreen(
          // We give it a key so Flutter knows this is a unique widget for animation purposes.
          key: const ValueKey('pin'),
          // When the app is successfully unlocked, we change the screen state to AppScreen.app.
          onUnlocked: () =>
              ref.read(screenProvider.notifier).state = AppScreen.app,
          // When setting up a new PIN, we change the screen state to AppScreen.activation.
          onSetupNew: () =>
              ref.read(screenProvider.notifier).state = AppScreen.activation,
        );
        break;

      // If the state is AppScreen.activation...
      case AppScreen.activation:
        // ...we set content to the ActivationScreen.
        content = ActivationScreen(
          // Unique key for the activation screen.
          key: const ValueKey('activation'),
          // When activation is successful, we move to the consent screen.
          onActivated: () =>
              ref.read(screenProvider.notifier).state = AppScreen.consent,
        );
        break;

      // If the state is AppScreen.consent...
      case AppScreen.consent:
        // ...we set content to the ConsentScreen.
        content = ConsentScreen(
          // Unique key for the consent screen.
          key: const ValueKey('consent'),
          // When the user agrees to the terms, we move to the main app screen.
          onAgree: () =>
              ref.read(screenProvider.notifier).state = AppScreen.app,
        );
        break;

      // If the state is AppScreen.app...
      case AppScreen.app:
        // ...we set content to the _MainApp widget, which contains the bottom tabs and core features.
        content = const _MainApp(key: ValueKey('app'));
        break;
    }

    // We wrap the content in an AnimatedSwitcher to smoothly transition between the top-level screens.
    return AnimatedSwitcher(
      // The duration of the screen transition animation (400ms).
      duration: const Duration(milliseconds: 400),
      // The easing curve for the new screen sliding/fading in.
      switchInCurve: Curves.easeOutCubic,
      // The easing curve for the old screen sliding/fading out.
      switchOutCurve: Curves.easeInCubic,
      // We customize the transition to be a simple fade effect.
      transitionBuilder: (child, animation) {
        // We use a FadeTransition widget, passing the animation controller.
        return FadeTransition(
          // The opacity is driven by the animation value.
          opacity: animation,
          // The child is the actual screen widget (PIN, App, etc.).
          child: child,
        );
      },
      // The child of the AnimatedSwitcher is the current screen content we determined above.
      child: content,
    );
  }
}

// ── Main app — bottom-tab shell + check-in overlays ─────────────────────────
// _MainApp is a ConsumerStatefulWidget, meaning it has internal state and can read Riverpod providers.
class _MainApp extends ConsumerStatefulWidget {
  // Constant constructor.
  const _MainApp({super.key});

  // Creates the mutable state object for this widget.
  @override
  ConsumerState<_MainApp> createState() => _MainAppState();
}

// This is the state class for _MainApp.
class _MainAppState extends ConsumerState<_MainApp> {
  // initState is called exactly once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Refresh history and status on app start
    // We use addPostFrameCallback to execute code right after the first frame has been rendered.
    // This is useful for calling things that shouldn't interrupt the initial build process.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // We call our custom method to load initial data from storage and network.
      _loadInitialData();
    });
  }

  // An asynchronous method to load user data, preferences, and check-in history.
  Future<void> _loadInitialData() async {
    // We create an instance of FlutterSecureStorage to read securely stored local data.
    const storage = FlutterSecureStorage();
    // We try to read the 'user_name' from secure storage.
    final uName = await storage.read(key: 'user_name');
    // If a user name exists...
    if (uName != null) {
      // ...we update the userNameProvider with it.
      ref.read(userNameProvider.notifier).state = uName;
    }
    // We try to read the 'language_pref' from secure storage.
    final lang = await storage.read(key: 'language_pref');
    // If a language preference exists...
    if (lang != null) {
      // ...we update the languagePrefProvider with it.
      ref.read(languagePrefProvider.notifier).state = lang;
    }

    // We wrap the network and sync calls in a try-catch block to handle potential errors (like no internet).
    try {
      // We get the SyncService instance.
      final syncSvc = ref.read(syncServiceProvider);
      // We try to sync offline data to the server if the device is currently online.
      await syncSvc.syncIfOnline();

      // We get the CheckinService instance.
      final chkSvc = ref.read(checkinServiceProvider);
      // We check if the user has already submitted a check-in today from the server.
      final todayStatus = await chkSvc.checkTodayStatus();
      // If the server says they have checked in...
      if (todayStatus['has_checked_in'] == true) {
        // ...we update the todayDoneProvider to true, locking the check-in for today.
        ref.read(todayDoneProvider.notifier).state = true;
      }

      // We fetch the raw check-in history from the server (or local cache).
      final historyRaw = await chkSvc.getHistory();
      // We map the raw JSON history into a list of strongly-typed Entry objects.
      final history = historyRaw
          .map((e) => Entry(
                // We map the date string.
                date: e['checkin_date'],
                // We map the overall score.
                overall: e['overall_score'],
                // We map the sleep score.
                sleep: e['sleep_score'],
                // We map the physical score.
                physical: e['physical_score'],
                // We map the focus score.
                focus: e['focus_score'],
                // We map the note, defaulting to an empty string if it's null.
                note: e['note'] ?? '',
              ))
          .toList();
      // We update the historyProvider state with this newly parsed list.
      ref.read(historyProvider.notifier).state = history;

      // Enforce once-per-day locally: if any loaded entry matches today, mark done.
      // We check if the todayDoneProvider is still false (meaning the server didn't explicitly say we checked in).
      if (!ref.read(todayDoneProvider)) {
        // We get today's date formatted as an ISO string.
        final todayStr = _todayIso();
        // We check if any entry in the history matches today's date.
        final matchesToday =
            history.any((e) => _entryMatchesDate(e.date, todayStr));
        // If an entry for today exists in the history...
        if (matchesToday) {
          // ...we manually set todayDoneProvider to true to prevent multiple check-ins.
          ref.read(todayDoneProvider.notifier).state = true;
        }
      }
    } catch (e) {
      // Ignored for now, keep seed history if offline.
      // If any errors occur (like no network), we just catch them and let the app continue with default/cached data.
    }
  }

  // The build method for the _MainApp widget, describing its UI.
  @override
  Widget build(BuildContext context) {
    // We watch the tabProvider to know which bottom tab is currently active.
    final tab = ref.watch(tabProvider);
    // We watch inCheckinProvider to see if the user is currently filling out a check-in.
    final inCheckin = ref.watch(inCheckinProvider);
    // We watch submittedProvider to see if the user just successfully submitted a check-in.
    final submitted = ref.watch(submittedProvider);
    // We watch todayDoneProvider to know if the check-in is locked for the day.
    final todayDone = ref.watch(todayDoneProvider);
    // We watch the current selected scores for the check-in.
    final scores = ref.watch(scoresProvider);
    // We watch the current note written in the check-in.
    final note = ref.watch(noteProvider);
    // We watch the user's check-in history.
    final history = ref.watch(historyProvider);
    // We watch if dark theme is active.
    final isDark = ref.watch(themeProvider);
    // We watch the user's current check-in streak.
    final streak = ref.watch(streakProvider);

    // ── Build Main Content ─────────────────────────────────────────────────
    // We declare a variable to hold the main content of this screen.
    Widget mainContent;

    // We use conditional logic to decide what to show on top of everything.
    // If the user is currently doing a check-in AND hasn't submitted yet...
    if (inCheckin && !submitted) {
      // ...we show the CheckinScreen.
      mainContent = CheckinScreen(
        // A unique key for the AnimatedSwitcher.
        key: const ValueKey('checkin'),
        // We pass the current scores.
        scores: scores,
        // We pass the current note.
        note: note,
        // Callback when a score slider/button is changed.
        onScoreChanged: (k, n) {
          // We create a copy of the current scores map and update the specific dimension 'k' with new value 'n'.
          final next = Map<DimKey, int>.from(scores)..[k] = n;
          // We update the scoresProvider state with this new map.
          ref.read(scoresProvider.notifier).state = next;
        },
        // Callback when the note text changes.
        onNoteChanged: (s) => ref.read(noteProvider.notifier).state = s,
        // Callback when the user taps submit.
        onSubmit: () async {
          // We try to submit to the backend.
          try {
            // We get the checkin service.
            final chkSvc = ref.read(checkinServiceProvider);
            // We await the submission, passing all the scores and the note.
            await chkSvc.submitCheckin(
              overall: scores[DimKey.overall]!,
              sleep: scores[DimKey.sleep]!,
              physical: scores[DimKey.physical]!,
              focus: scores[DimKey.focus]!,
              note: note,
            );
          } catch (e) {
            // If submission fails (e.g., offline), we save it locally to sync later.
            // We get the sync service.
            final syncSvc = ref.read(syncServiceProvider);
            // We tell it to save an offline checkin.
            await syncSvc.saveOfflineCheckin({
              'overall_score': scores[DimKey.overall]!,
              'sleep_score': scores[DimKey.sleep]!,
              'physical_score': scores[DimKey.physical]!,
              'focus_score': scores[DimKey.focus]!,
              'note': note,
            });
          }

          // We update the local history list instantly by prepending the newly built entry so the UI reflects it.
          ref.read(historyProvider.notifier).state = [
            buildEntry(scores, note), // Helper function to create an Entry object.
            ...history // Spread operator to include all previous history.
          ];
          // We set inCheckin to false because we are done with the form.
          ref.read(inCheckinProvider.notifier).state = false;
          // We set submitted to true to trigger the success screen.
          ref.read(submittedProvider.notifier).state = true;
          // We set todayDone to true to prevent them from doing it again.
          ref.read(todayDoneProvider.notifier).state = true;
        },
        // Callback when the user taps the back button to cancel the check-in.
        onBack: () => ref.read(inCheckinProvider.notifier).state = false,
      );
    // Otherwise, if the check-in has just been submitted...
    } else if (submitted) {
      // ...we show the SubmittedScreen (success confirmation).
      mainContent = SubmittedScreen(
        // Unique key for the AnimatedSwitcher.
        key: const ValueKey('submitted'),
        // We pass the scores to show them on the confirmation screen.
        scores: scores,
        // We pass the note to show it as well.
        note: note,
        // Callback when the user taps "Done" or closes the success screen.
        onDone: () {
          // We set submitted back to false.
          ref.read(submittedProvider.notifier).state = false;
          // We navigate back to the Home tab.
          ref.read(tabProvider.notifier).state = AppTab.home;
        },
      );
    // Otherwise, we show the normal app interface with tabs.
    } else {
      // We use a Scaffold widget as the base layout for the tabs.
      mainContent = Scaffold(
        // Unique key.
        key: const ValueKey('tabs'),
        // We extend the body to flow underneath the bottom navigation bar.
        extendBody: true,
        // We extend the body to flow underneath the app bar (if we had one).
        extendBodyBehindAppBar: true,
        // We set the background color using our custom theme extension (rrBg).
        backgroundColor: context.rrBg,
        // The body is a Stack, allowing us to overlay widgets on top of each other.
        body: Stack(
          children: [
            // 1. The Tabs Content (now directly in Stack to go edge-to-edge)
            // We use an AnimatedSwitcher to smoothly transition between tabs.
            AnimatedSwitcher(
              // Duration of tab switch (300ms).
              duration: const Duration(milliseconds: 300),
              // Easing curve for tab switching in.
              switchInCurve: Curves.easeOutCubic,
              // Easing curve for tab switching out.
              switchOutCurve: Curves.easeInCubic,
              // Custom transition builder for tabs.
              transitionBuilder: (child, animation) {
                // We fade the new tab in.
                return FadeTransition(
                  opacity: animation,
                  // And simultaneously slide it in from the right slightly.
                  child: SlideTransition(
                    // The Tween defines the start and end positions of the slide.
                    position: Tween<Offset>(
                      // Start slightly to the right (x: 0.05).
                      begin: const Offset(0.05, 0),
                      // End exactly at the origin (x: 0, y: 0).
                      end: Offset.zero,
                    ).animate(animation),
                    // The child is the tab content.
                    child: child,
                  ),
                );
              },
              // KeyedSubtree helps Flutter uniquely identify this tab content so it animates correctly.
              child: KeyedSubtree(
                // We use the current tab enum as the key.
                key: ValueKey(tab),
                // We call a helper method to return the actual widget for the selected tab.
                child: _tabBody(
                    context, ref, tab, history, todayDone, isDark, streak),
              ),
            ),

            // 2. Top Blurry Gradient Mask (for status bar legibility)
            // Positioned places this widget absolutely at the top of the Stack.
            Positioned(
              // Anchored to the top.
              top: 0,
              // Anchored to the left.
              left: 0,
              // Anchored to the right.
              right: 0,
              // Height matches the device's top notch/status bar padding + 32 pixels.
              height: MediaQuery.of(context).padding.top + 32,
              // IgnorePointer ensures this overlay doesn't block touches to the content beneath it.
              child: IgnorePointer(
                // ClipRect ensures the blur effect doesn't spill out of these bounds.
                child: ClipRect(
                  // ShaderMask applies a gradient mask to the child.
                  child: ShaderMask(
                    // We define a linear gradient that fades from black (opaque) to transparent.
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.transparent],
                      stops: [0.3, 1.0],
                    ).createShader(bounds),
                    // dstIn blend mode means the child will only be visible where the gradient is solid (black).
                    blendMode: BlendMode.dstIn,
                    // BackdropFilter applies a blur effect to everything drawn *behind* it.
                    child: BackdropFilter(
                      // We blur heavily on both X and Y axes.
                      filter: ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      // The container provides a semi-transparent background color to tint the blur.
                      child:
                          Container(color: context.rrBg.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Bottom Blurry Gradient Mask (so content smoothly vanishes under nav island)
            // Positioned places this widget absolutely at the bottom of the Stack.
            Positioned(
              // Anchored to the bottom.
              bottom: 0,
              // Anchored to the left.
              left: 0,
              // Anchored to the right.
              right: 0,
              // Fixed height of 120 pixels, covering the bottom navigation bar area.
              height: 120,
              // Again, we ignore touches so we don't block scrolling on the lists beneath.
              child: IgnorePointer(
                // Clip the blur to these bounds.
                child: ClipRect(
                  // Apply a gradient mask fading upwards.
                  child: ShaderMask(
                    // Fades from black at the very bottom to transparent going up.
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.transparent],
                      stops: [0.1, 1.0],
                    ).createShader(bounds),
                    // dstIn keeps the blur visible where the gradient is black.
                    blendMode: BlendMode.dstIn,
                    // Blur the content underneath.
                    child: BackdropFilter(
                      // Heavy blur.
                      filter: ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      // Tint the blur with the theme's background color.
                      child:
                          Container(color: context.rrBg.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Floating Navigation Island
            // We place the custom bottom navigation bar on top of the blur effect.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              // We pass the current active tab and the callback to change tabs.
              child: BottomNav(
                active: tab,
                // When a tab is tapped, we update the tabProvider state.
                onTab: (t) => ref.read(tabProvider.notifier).state = t,
              ),
            ),
          ],
        ),
      );
    }

    // We return the mainContent (Checkin, Submitted, or Tabs) wrapped in an AnimatedSwitcher.
    // This provides a sliding-up transition when opening the check-in screens over the tabs.
    return AnimatedSwitcher(
      // Animation duration (400ms).
      duration: const Duration(milliseconds: 400),
      // Easing curve for screen in.
      switchInCurve: Curves.easeOutCubic,
      // Easing curve for screen out.
      switchOutCurve: Curves.easeInCubic,
      // Custom transition builder.
      transitionBuilder: (child, animation) {
        // Fade transition.
        return FadeTransition(
          opacity: animation,
          // Slide transition coming from slightly below (y: 0.05).
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            // The child is the mainContent we determined.
            child: child,
          ),
        );
      },
      child: mainContent,
    );
  }

  // A helper method that returns the specific widget for a given tab.
  Widget _tabBody(
    BuildContext context,
    WidgetRef ref,
    AppTab tab,
    List<Entry> history,
    bool todayDone,
    bool isDark,
    int streak,
  ) {
    // We switch on the provided tab enum.
    switch (tab) {
      // If the Home tab is selected...
      case AppTab.home:
        // ...return the HomeScreen widget.
        return HomeScreen(
          // We pass whether check-in is done today.
          todayDone: todayDone,
          // We pass the current streak count.
          streak: streak,
          // Callback to switch tabs from within the HomeScreen (e.g., clicking 'view history').
          onTab: (t) => ref.read(tabProvider.notifier).state = t,
          // Callback when the user taps "Start Check-in" button.
          onStartCheckin: () {
            // If they already did it today...
            if (todayDone) {
              // ...we just show them the submitted screen again.
              ref.read(submittedProvider.notifier).state = true;
            } else {
              // If they haven't done it, we clear scores and note.
              ref.read(scoresProvider.notifier).state = emptyScores();
              ref.read(noteProvider.notifier).state = '';
              // And we open the check-in overlay.
              ref.read(inCheckinProvider.notifier).state = true;
            }
          },
        );

      // If the Trend (History) tab is selected...
      case AppTab.trend:
        // ...return the TrendScreen, passing the user's history data.
        return TrendScreen(history: history);

      // If the Support tab is selected...
      case AppTab.support:
        // ...return the SupportScreen.
        return const SupportScreen();

      // If the Settings tab is selected...
      case AppTab.settings:
        // ...return the SettingsScreen.
        return SettingsScreen(
          // We pass whether dark mode is currently active.
          isDark: isDark,
          // Callback to toggle dark/light mode.
          onThemeToggle: () =>
              ref.read(themeProvider.notifier).state = !ref.read(themeProvider),
          // Callback for when the user taps "Logout".
          onLogout: () async {
            try {
              // We call the logout method on the auth service.
              await ref.read(authServiceProvider).logout();
            } catch (_) {
              // Ignore errors (e.g., network failure during logout).
            }
            // We reset various states to ensure a clean slate for the next user.
            ref.read(inCheckinProvider.notifier).state = false;
            ref.read(submittedProvider.notifier).state = false;
            // Reset tab to home.
            ref.read(tabProvider.notifier).state = AppTab.home;
            // Change top-level screen state back to the PIN entry.
            ref.read(screenProvider.notifier).state = AppScreen.pin;
          },
        );
    }
  }
}

// ── Helpers for once-per-day local enforcement ───────────────────────────────

/// Returns today's date as an ISO string, e.g. "2026-09-11".
// This function generates a strictly formatted string representing the current local date.
String _todayIso() {
  // Get the current date and time.
  final n = DateTime.now();
  // Format as YYYY-MM-DD. padLeft ensures month and day are always two digits (e.g., 09 instead of 9).
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

/// Returns true if [entryDate] (ISO "2026-09-11" OR friendly "Thu, Sep 11")
/// refers to the same calendar day as [todayIso].
// This function helps determine if a given date string matches today's date, 
// handling both strict ISO formats and friendly readable formats.
bool _entryMatchesDate(String entryDate, String todayIso) {
  // ISO format check: If the strings match exactly, return true immediately.
  if (entryDate == todayIso) return true;
  // Friendly format fallback: "Thu, Sep 11"
  // We create a map to convert three-letter month abbreviations to integer month numbers.
  const months = {
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };
  // We wrap the parsing logic in a try-catch to avoid app crashes on malformed date strings.
  try {
    // Remove commas from the date string (e.g., "Thu, Sep 11" -> "Thu Sep 11").
    final stripped = entryDate.replaceAll(',', '').trim();
    // Split the string into parts separated by spaces.
    final parts = stripped.split(' ');
    // If there are 3 parts (Day, Month, Date), we take the last two. Otherwise, we take them all.
    final dateParts = parts.length == 3 ? parts.sublist(1) : parts;
    // We get the integer month using our map (e.g., 'Sep' -> 9).
    final month = months[dateParts[0]];
    // We parse the day part into an integer (e.g., '11' -> 11).
    final day = int.parse(dateParts[1]);
    // If the month abbreviation wasn't found in our map, return false.
    if (month == null) return false;
    // Get the current date and time.
    final now = DateTime.now();
    // Compare the extracted month and day with the current date's month and day. Return true if they match.
    return now.month == month && now.day == day;
  } catch (_) {
    // If any parsing error occurs, we assume the dates don't match and return false.
    return false;
  }
}
