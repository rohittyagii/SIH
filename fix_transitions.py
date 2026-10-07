import re

with open("lib/main.dart", "r") as f:
    content = f.read()

# Replace _AppShell build
app_shell_search = """  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(screenProvider);

    switch (screen) {
      case AppScreen.pin:
        return PinScreen(
          onUnlocked: () =>
              ref.read(screenProvider.notifier).state = AppScreen.app,
          onSetupNew: () =>
              ref.read(screenProvider.notifier).state = AppScreen.activation,
        );

      case AppScreen.activation:
        return ActivationScreen(
          onActivated: () =>
              ref.read(screenProvider.notifier).state = AppScreen.consent,
        );

      case AppScreen.consent:
        return ConsentScreen(
          onAgree: () =>
              ref.read(screenProvider.notifier).state = AppScreen.app,
        );

      case AppScreen.app:
        return const _MainApp();
    }
  }"""

app_shell_replace = """  @override
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
  }"""

content = content.replace(app_shell_search, app_shell_replace)

# Replace _MainApp build
main_app_search = """    // ── Check-in active ────────────────────────────────────────────────────
    if (inCheckin && !submitted) {
      return CheckinScreen(
        scores: scores,
        note: note,
        onScoreChanged: (k, n) {
          final next = Map<DimKey, int>.from(scores)..[k] = n;
          ref.read(scoresProvider.notifier).state = next;
        },
        onNoteChanged: (s) => ref.read(noteProvider.notifier).state = s,
        onSubmit: () async {
          // Send to API
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
            // Save offline if failed
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
    }

    // ── Submitted ──────────────────────────────────────────────────────────
    if (submitted) {
      return SubmittedScreen(
        scores: scores,
        note: note,
        onDone: () {
          ref.read(submittedProvider.notifier).state = false;
          ref.read(tabProvider.notifier).state = AppTab.home;
        },
      );
    }

    // ── Normal tab layout ──────────────────────────────────────────────────
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          Column(
            children: [
              Expanded(
                child: _tabBody(
                  context, ref, tab, history, todayDone, isDark, streak),
              ),
            ],
          ),
          // Floating Navigation Island
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
    );"""

main_app_replace = """    // ── Build Main Content ─────────────────────────────────────────────────
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
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
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
                ),
              ],
            ),
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
    );"""

content = content.replace(main_app_search, main_app_replace)

with open("lib/main.dart", "w") as f:
    f.write(content)

print("Added transitions!")
