// Import the core Flutter material design library, which provides UI widgets like Scaffold, Column, Text, etc.
import 'package:flutter/material.dart';
// Import Riverpod for state management, which allows us to read and watch app state efficiently.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import secure storage for saving sensitive data like language preferences locally.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import our custom colors and theme extension methods.
import '../theme/colors.dart';
// Import seed data or languages available in the app.
import '../data/seed.dart';
// Import custom icon widgets used throughout the UI.
import '../widgets/icon_widgets.dart';
// Import the RrCard widget, which is a reusable custom card container.
import '../widgets/rr_card.dart';
// Import a custom Toggle switch widget.
import '../widgets/toggle.dart';
// Import bottom navigation components (like AppTab if needed).
import '../widgets/bottom_nav.dart';
// Import the notification service to schedule or cancel daily reminders.
import '../services/notification_service.dart';
// Import the authentication service to handle operations like deleting user data.
import '../services/auth_service.dart';
// Import global application state providers (like username, language preference, etc.).
import '../providers/app_state.dart';
// Import translation helpers to support multiple languages.
import '../data/translations.dart';
// Import the screen that shows data handling policies.
import 'data_handling_screen.dart';
// Import the screen for changing the user's PIN.
import 'change_pin_screen.dart';

// ── Shared sub-widgets ─────────────────────────────────────────────────────

// A private stateless widget used to display section headings in the settings list.
class _SectionLabel extends StatelessWidget {
  // Constructor taking the text to display.
  const _SectionLabel(this.text);
  
  // The actual text string for the section heading.
  final String text;
  
  // The build method returns the widget tree for this label.
  @override
  Widget build(BuildContext context) => Padding(
        // Add padding only at the bottom to separate the label from the card below it.
        padding: const EdgeInsets.only(bottom: 8),
        // Display the text converted to uppercase.
        child: Text(text.toUpperCase(),
            // Apply a custom text style.
            style: TextStyle(
                // Set the font size to 11 pixels.
                fontSize: 11,
                // Make the text slightly bolder than normal.
                fontWeight: FontWeight.w500,
                // Use a theme extension color defined on the context.
                color: context.rrT6,
                // Add a small amount of spacing between letters.
                letterSpacing: 0.07)),
      );
}

// A private stateless widget representing a single row item inside a settings card.
class _SettingRow extends StatelessWidget {
  // Constructor with named parameters to customize the row's appearance and behavior.
  const _SettingRow({
    required this.label, // The main text of the row.
    this.value = '', // An optional value text to show on the right.
    this.arrow = false, // Whether to show a right-facing arrow icon.
    this.danger = false, // Whether this row represents a destructive action (like deleting data).
    this.first = false, // If true, hides the top divider line.
    this.onTap, // An optional callback function when the row is tapped.
  });
  
  final String label; // The label text.
  final String value; // The value text.
  final bool arrow; // Boolean for arrow visibility.
  final bool danger; // Boolean for danger styling.
  final bool first; // Boolean indicating if it's the first row in a list.
  final VoidCallback? onTap; // Function to execute on tap.

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // If this is not the first row, draw a horizontal divider line above it.
        if (!first) Divider(color: context.rrDv, height: 26),
        
        // A widget that detects taps on its child.
        GestureDetector(
          // Pass the tap callback provided to this widget.
          onTap: onTap,
          // Make the entire row tappable, even the empty spaces between widgets.
          behavior: HitTestBehavior.opaque,
          child: Row(
            // Space out the label (left) and the value/arrow (right).
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Display the label on the left side.
              Text(label,
                  style: TextStyle(
                      // Font size of 14 pixels.
                      fontSize: 14,
                      // If it's a danger row, use a specific red color (score1), otherwise use a theme color.
                      color: danger ? AppColors.score1 : context.rrT2)),
              
              // Only render the right-side row if there's a value or an arrow to show.
              if (value.isNotEmpty || arrow)
                Row(
                  // Pack the children tightly together.
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // If a value string is provided, display it.
                    if (value.isNotEmpty)
                      Text(value,
                          // Use a smaller font and a muted theme color for the value text.
                          style: TextStyle(fontSize: 13, color: context.rrT4)),
                    
                    // If the arrow boolean is true, display a custom chevron right icon.
                    if (arrow) IconChevronRight(size: 13, color: context.rrT6),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── SettingsScreen ─────────────────────────────────────────────────────────

// The main Settings screen widget. It's a ConsumerStatefulWidget, meaning it has mutable state
// and can interact with Riverpod providers.
class SettingsScreen extends ConsumerStatefulWidget {
  // Constructor requiring information about the theme and callbacks for theme toggle and logout.
  const SettingsScreen(
      {super.key,
      required this.isDark, // True if the app is currently in dark mode.
      required this.onThemeToggle, // Callback function to switch the theme.
      required this.onLogout}); // Callback function to handle logging out.
      
  final bool isDark; // Holds the current theme state.
  final VoidCallback onThemeToggle; // Holds the theme toggle function.
  final VoidCallback onLogout; // Holds the logout function.

  // Creates the mutable state object for this widget.
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

// The mutable state class for SettingsScreen.
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Tracks whether the language selection dropdown is open.
  bool _langOpen = false;
  // Tracks whether the daily reminder is enabled.
  bool _reminder = false;
  // Holds the scheduled time for the daily reminder (defaults to 7:30 AM).
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 30);
  // Tracks whether offline sync alerts are enabled.
  bool _syncAlerts = true;
  // Tracks whether the weekly summary notification is enabled.
  bool _weeklySummary = false;
  
  // State variables for managing confirmation dialogs in line. 
  // 'idle' means normal view, 'confirm' means show the confirmation prompt.
  String _logout = 'idle'; // Logout confirmation state.
  String _deactivate = 'idle'; // Device deactivation confirmation state.
  String _deleteData = 'idle'; // Data deletion confirmation state.

  // This method is called once when the widget is inserted into the widget tree.
  @override
  void initState() {
    super.initState();
    // Load the saved reminder settings from local storage as soon as the screen loads.
    _loadSavedReminder();
  }

  // An asynchronous method to load the previously saved reminder schedule.
  Future<void> _loadSavedReminder() async {
    // Read the notification service from Riverpod without listening for continuous updates.
    final notifSvc = ref.read(notificationServiceProvider);
    // Fetch the saved reminder details (if any).
    final saved = await notifSvc.getSavedReminder();
    
    // If we found saved data and the widget is still on the screen (mounted)...
    if (saved != null && mounted) {
      // Update the state to reflect the loaded reminder settings.
      setState(() {
        _reminder = saved.enabled; // Set the toggle to on or off.
        _reminderTime = saved.timeOfDay; // Update the scheduled time.
      });
    }
  }

  // A helper method to find a Language object given its language code.
  // It searches the 'languages' list and returns the first match, or defaults to the first language.
  Language _getCurrentLang(String code) => languages
      .firstWhere((l) => l.code == code, orElse: () => languages.first);

  // A helper method to format the current reminder time into a readable string (e.g., "07:30 Daily").
  String _getReminderLabel() {
    // Convert the hour to a string and pad with a leading zero if it's a single digit.
    final h = _reminderTime.hour.toString().padLeft(2, '0');
    // Convert the minute to a string and pad with a leading zero.
    final m = _reminderTime.minute.toString().padLeft(2, '0');
    // Combine them with translated text using the 'tr' function.
    return '$h:$m ${tr('daily', ref)}';
  }

  // An asynchronous method to show a time picker dialog to the user.
  Future<TimeOfDay?> _pickTime() async {
    return showTimePicker(
      context: context, // The current widget context.
      initialTime: _reminderTime, // The time to pre-select in the dialog.
    );
  }

  // An asynchronous method to turn the daily reminder on or off.
  Future<void> _toggleReminder() async {
    // Get the notification service.
    final notifSvc = ref.read(notificationServiceProvider);
    
    // If the reminder is currently OFF, we want to turn it ON.
    if (!_reminder) {
      // Ask the user to pick a time.
      final picked = await _pickTime();
      // If the user dismissed the dialog without picking a time, do nothing.
      if (picked == null) return; 
      
      // Update the state with the new time and set reminder to true.
      setState(() {
        _reminderTime = picked;
        _reminder = true;
      });
      // Schedule the reminder using the notification service.
      await notifSvc.scheduleDailyReminder(picked);
    } else {
      // If the reminder is currently ON, we want to turn it OFF.
      // Update the state to reflect the change visually immediately.
      setState(() => _reminder = false);
      // Cancel the scheduled reminder in the background.
      await notifSvc.cancelDailyReminder();
    }
  }

  /// Tap the time label to change the scheduled time without toggling off.
  Future<void> _changeReminderTime() async {
    // Ask the user to pick a new time.
    final picked = await _pickTime();
    // If they cancel, do nothing.
    if (picked == null) return;
    // Update the state with the new time.
    setState(() => _reminderTime = picked);
    // Re-schedule the reminder for the new time.
    final notifSvc = ref.read(notificationServiceProvider);
    await notifSvc.scheduleDailyReminder(picked);
  }

  // The build method describes the UI of the widget.
  @override
  Widget build(BuildContext context) {
    // Watch the language preference provider so the UI rebuilds if the language changes.
    final currentLangCode = ref.watch(languagePrefProvider);
    // Get the actual Language object based on the code.
    final currentLang = _getCurrentLang(currentLangCode);

    // Return a Scaffold, which provides a standard screen layout structure.
    return Scaffold(
      // Set the background color using our custom theme context extension.
      backgroundColor: context.rrBg,
      // Wrap the content in a SingleChildScrollView so it can be scrolled if the screen is small.
      body: SingleChildScrollView(
        // Add padding around the edges. Account for the system status bar (top padding) and add extra space at the bottom.
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 24, 16, 120),
          // Use a Column to arrange children vertically.
          child: Column(
            // Align all children to the start (left) edge.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Render the screen title "Settings", translated into the current language.
              Text(tr('Settings', ref),
                  style: TextStyle(
                      fontSize: 20, // Large font size for the header.
                      fontWeight: FontWeight.w600, // Semi-bold text.
                      color: context.rrT1)), // Primary text color.
              // Add a vertical space of 24 pixels.
              const SizedBox(height: 24),

              // ── Appearance ─────────────────────────────────────────────
              // Display the section label for "Appearance".
              _SectionLabel(tr('Appearance', ref)),
              // Wrap the appearance settings in our custom RrCard widget.
              RrCard(
                child: Column(
                  // Align content to the left inside the card.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      // Space the label and any right-aligned widgets.
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          // Align text to the left.
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main label for the "Theme" setting.
                            Text(tr('Theme', ref),
                                style: TextStyle(
                                    fontSize: 14, color: context.rrT2)),
                            // Small vertical gap.
                            const SizedBox(height: 2),
                            // Subtitle explaining the current theme state.
                            Text(
                                // If dark mode is on, show 'Low-light interface', else show 'High-contrast interface'.
                                widget.isDark
                                    ? tr('Low-light interface', ref)
                                    : tr('High-contrast interface', ref),
                                style: TextStyle(
                                    fontSize: 12, color: context.rrT4)),
                          ],
                        ),
                      ],
                    ),
                    // Vertical spacing before the theme toggle buttons.
                    const SizedBox(height: 12),
                    // A container holding the light/dark mode buttons.
                    Container(
                      // Add padding inside the container.
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        // Give it rounded corners.
                        borderRadius: BorderRadius.circular(10),
                        // Set the background color.
                        color: context.rrIn,
                        // Add a border.
                        border: Border.all(color: context.rrDv2),
                      ),
                      // Place the buttons in a horizontal row.
                      child: Row(
                        children: [
                          // Create the "Dark" button using the helper method _themeBtn.
                          _themeBtn(context, 'dark', tr('Dark', ref)),
                          // Create the "Light" button using the helper method _themeBtn.
                          _themeBtn(context, 'light', tr('Light', ref)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Add vertical spacing between sections.
              const SizedBox(height: 20),

              // ── Your account ────────────────────────────────────────────
              // Display the section label for "Your account".
              _SectionLabel(tr('Your account', ref)),
              RrCard(
                child: Column(
                  children: [
                    // A row displaying the user's ID.
                    _SettingRow(
                        label: tr('Your ID', ref),
                        // Watch the userNameProvider; if it's null, default to 'User'.
                        value: ref.watch(userNameProvider) ?? 'User',
                        // Marks this as the first row so no top divider is drawn.
                        first: true),
                    // A row for configuring PIN & biometrics.
                    _SettingRow(
                        label: tr('PIN & biometrics', ref),
                        value: tr('Configured', ref),
                        // Show a right arrow indicating it leads to another screen.
                        arrow: true,
                        // When tapped, navigate to the ChangePinScreen.
                        onTap: () {
                          // Push a new route onto the navigation stack.
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const ChangePinScreen(),
                          ));
                        }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Language & region ───────────────────────────────────────
              // Display the section label for "Language & region".
              _SectionLabel(tr('Language & region', ref)),
              RrCard(
                child: Column(
                  children: [
                    // A tappable area to expand or collapse the language list.
                    GestureDetector(
                      // Toggle the _langOpen state variable on tap.
                      onTap: () => setState(() => _langOpen = !_langOpen),
                      child: Row(
                        // Distribute the icon/text on the left and the chevron on the right.
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Display a globe icon.
                              IconGlobe(size: 15, color: context.rrT4),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // The label "Language".
                                  Text(tr('Language', ref),
                                      style: TextStyle(
                                          fontSize: 14, color: context.rrT2)),
                                  // Display the currently selected language in English and its native name.
                                  Text(
                                      '${currentLang.label} · ${currentLang.native}',
                                      style: TextStyle(
                                          fontSize: 12, color: context.rrT4)),
                                ],
                              ),
                            ],
                          ),
                          // Animate the rotation of the chevron arrow based on whether the list is open.
                          AnimatedRotation(
                            // Turn 90 degrees (0.25 turns) if open, 0 if closed.
                            turns: _langOpen ? 0.25 : 0,
                            // Set the duration of the animation.
                            duration: const Duration(milliseconds: 200),
                            child:
                                IconChevronRight(size: 13, color: context.rrT6),
                          ),
                        ],
                      ),
                    ),
                    // If the language section is open, display the list of available languages.
                    if (_langOpen) ...[
                      // Draw a divider line before listing the languages.
                      Divider(color: context.rrDv2, height: 28),
                      // Loop through the list of languages and create a widget for each one.
                      ...languages.map((l) {
                        // Check if the current loop iteration's language is the active one.
                        final selected = currentLangCode == l.code;
                        return GestureDetector(
                          // When a language is tapped...
                          onTap: () async {
                            // 1. Update the app state provider to the newly selected language.
                            ref.read(languagePrefProvider.notifier).state =
                                l.code;
                            // 2. Close the language dropdown.
                            setState(() => _langOpen = false);

                            // 3. Save the new preference to secure storage so it persists across app restarts.
                            const storage = FlutterSecureStorage();
                            await storage.write(
                                key: 'language_pref', value: l.code);

                            try {
                              // 4. Try to sync the preference to the backend server using the auth service.
                              await ref
                                  .read(authServiceProvider)
                                  .updatePreferences({'language_pref': l.code});
                            } catch (_) {
                              // Ignore errors if the network request fails.
                            }
                          },
                          // Animate color changes when selection changes.
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            // Add a small margin at the bottom of each item.
                            margin: const EdgeInsets.only(bottom: 2),
                            // Add padding inside the item.
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                            decoration: BoxDecoration(
                              // Rounded corners.
                              borderRadius: BorderRadius.circular(9),
                              // Highlight background with a tinted indigo if selected, otherwise transparent.
                              color: selected
                                  ? AppColors.indigo.withValues(alpha: 0.10)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  // Show the English name of the language.
                                  Text(l.label,
                                      style: TextStyle(
                                          fontSize: 13,
                                          // Make text bolder if selected.
                                          fontWeight: selected
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                          // Use a primary color if selected, secondary otherwise.
                                          color: selected
                                              ? context.rrT2
                                              : context.rrT2b)),
                                  // If the native name is different from 'English', show it alongside.
                                  if (l.native != 'English') ...[
                                      const SizedBox(width: 8),
                                    Text(l.native,
                                        style: TextStyle(
                                            fontSize: 12, color: context.rrT4)),
                                  ],
                                ]),
                                // If this language is selected, show a small blue dot on the right.
                                if (selected)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle, // Make it circular.
                                      color: AppColors.indigo, // Color it indigo.
                                      boxShadow: [
                                        // Add a soft glow effect.
                                        BoxShadow(
                                            color: AppColors.indigo
                                                .withValues(alpha: 0.6),
                                            blurRadius: 6)
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Notifications ───────────────────────────────────────────
              // Display the section label for "Notifications".
              _SectionLabel(tr('Notifications', ref)),
              RrCard(
                child: Column(
                  children: [
                    // A custom row for the "Daily reminder" toggle.
                    _notifRow(
                        context,
                        // Icon turns indigo if enabled, grey if disabled.
                        IconBell(
                            size: 14,
                            color: _reminder ? AppColors.indigo : context.rrT6),
                        tr('Daily reminder', ref), // Label text.
                        _getReminderLabel(), // Subtitle text showing the time.
                        _reminder, // Boolean for whether it is toggled on.
                        _toggleReminder, // Function to call when the toggle switch is flipped.
                        true, // Is this the first item? (Hides top divider).
                        // If the reminder is ON, allow tapping the text to change the time.
                        onLabelTap: _reminder ? _changeReminderTime : null),
                    // A custom row for the "Sync alerts" toggle.
                    _notifRow(
                        context,
                        IconCloudQueue(
                            size: 14,
                            color:
                                _syncAlerts ? AppColors.indigo : context.rrT6),
                        tr('Sync alerts', ref),
                        tr('When offline data syncs', ref),
                        _syncAlerts,
                        // Flip the local state boolean when toggled.
                        () => setState(() => _syncAlerts = !_syncAlerts),
                        false),
                    // A custom row for the "Weekly summary" toggle.
                    _notifRow(
                        context,
                        IconCalendar(
                            size: 14,
                            color: _weeklySummary
                                ? AppColors.indigo
                                : context.rrT6),
                        tr('Weekly summary', ref),
                        tr('Mondays at 08:00', ref),
                        _weeklySummary,
                        // Flip the local state boolean when toggled.
                        () => setState(() => _weeklySummary = !_weeklySummary),
                        false),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Data & privacy ──────────────────────────────────────────
              // Display the section label for "Data & privacy".
              _SectionLabel(tr('Data & privacy', ref)),
              RrCard(
                // Determine what to show based on the _deleteData state variable.
                child: _deleteData == 'idle'
                    // If 'idle', show the regular setting rows.
                    ? Column(
                        children: [
                          _SettingRow(
                            label: tr('Data handling', ref),
                            arrow: true, // Show navigation arrow.
                            first: true, // Hide top divider.
                            onTap: () {
                              // Navigate to the Data Handling policy screen when tapped.
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const DataHandlingScreen(),
                              ));
                            },
                          ),
                          _SettingRow(
                            label: tr('Delete all my data', ref),
                            danger: true, // Style this row as dangerous (red).
                            // Switch to confirmation mode when tapped.
                            onTap: () =>
                                setState(() => _deleteData = 'confirm'),
                          ),
                        ],
                      )
                    // If 'confirm', show a specialized confirmation UI instead of the list.
                    : _deleteDataConfirm(context),
              ),
              const SizedBox(height: 20),

              // ── Session ─────────────────────────────────────────────────
              // Display the section label for "Session".
              _SectionLabel(tr('Session', ref)),
              RrCard(
                  // Show normal logout button if 'idle', else show confirmation UI.
                  child: _logout == 'idle'
                      ? _logoutIdle(context)
                      : _logoutConfirm(context)),
              const SizedBox(height: 20),

              // ── Device ──────────────────────────────────────────────────
              // Display the section label for "Device".
              _SectionLabel(tr('Device', ref)),
              RrCard(
                  // Show normal deactivate button if 'idle', else show confirmation UI.
                  child: _deactivate == 'idle'
                      ? _deactivateIdle(context)
                      : _deactivateConfirm(context)),
              const SizedBox(height: 20),

              // ── About ────────────────────────────────────────────────────
              // Display the section label for "About".
              _SectionLabel(tr('About', ref)),
              RrCard(
                child: Column(
                  children: [
                    // Display app version (hardcoded here).
                    _SettingRow(
                        label: tr('App version', ref), value: '1.0.0', first: true),
                    // Display organizational unit (hardcoded to 'Eastern Command' for this context).
                    _SettingRow(label: tr('Unit programme', ref), value: tr('Eastern Command', ref)),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  // ── Helper UI Builders ───────────────────────────────────────────────────

  // Builds one of the light/dark mode buttons in the appearance section.
  Widget _themeBtn(BuildContext context, String t, String label) {
    // Check if THIS button represents the currently active theme.
    final active = widget.isDark ? t == 'dark' : t == 'light';
    
    // Wrap in Expanded so both buttons share the width equally.
    return Expanded(
      child: GestureDetector(
        // If it's already active, disable the tap (null). Otherwise, trigger the theme toggle callback.
        onTap: active ? null : widget.onThemeToggle,
        // Animate color transitions.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          // Vertical padding inside the button.
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            // Rounded corners.
            borderRadius: BorderRadius.circular(7),
            // Background color changes based on whether it is active.
            color: active ? context.rrB1 : Colors.transparent,
          ),
          child: Row(
            // Center the content horizontally.
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display a moon icon for 'dark', sun icon for 'light'. Highlight if active.
              if (t == 'dark')
                IconMoon(size: 14, color: active ? context.rrT2 : context.rrT6)
              else
                IconSun(size: 14, color: active ? context.rrT2 : context.rrT6),
              const SizedBox(width: 7),
              // The text label for the button.
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      // Thicker font weight if active.
                      fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                      // Brighter text color if active.
                      color: active ? context.rrT2 : context.rrT4)),
            ],
          ),
        ),
      ),
    );
  }

  // Builds a row for the Notifications section, which includes an icon, titles, and a custom Toggle switch.
  Widget _notifRow(BuildContext context, Widget icon, String label, String sub,
      bool on, Function() toggle, bool first, {VoidCallback? onLabelTap}) {
    return Column(
      children: [
        // Add a divider if it's not the first item.
        if (!first) Divider(color: context.rrDv, height: 26),
        Row(
          // Space elements to left and right edges.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // The left side (icon and text), wrapped in GestureDetector if it has a specific tap action (like editing time).
            GestureDetector(
              onTap: onLabelTap,
              child: Row(children: [
                icon, // The passed-in icon widget.
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main title text.
                    Text(label,
                        style: TextStyle(fontSize: 14, color: context.rrT2)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Subtitle text.
                        Text(sub,
                            style: TextStyle(fontSize: 12, color: context.rrT4)),
                        // If it is editable (onLabelTap is provided), show a small pencil 'edit' icon.
                        if (onLabelTap != null) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.edit, size: 11, color: context.rrT6),
                        ],
                      ],
                    ),
                  ],
                ),
              ]),
            ),
            // The right side: our custom animated toggle switch.
            Toggle(on: on, onToggle: toggle),
          ],
        ),
      ],
    );
  }

  // Builds the default (non-confirmation) view for the "Sign out" button.
  Widget _logoutIdle(BuildContext context) => GestureDetector(
        // Set state to 'confirm' to change the UI to the confirmation view.
        onTap: () => setState(() => _logout = 'confirm'),
        child: Row(children: [
          // A red logout icon.
          const IconLogOut(size: 15, color: Color(0xFFEF6B6B)),
          const SizedBox(width: 10),
          // Normal text label.
          Text(tr('Sign out', ref), style: TextStyle(fontSize: 14, color: context.rrT2)),
        ]),
      );

  // Builds the confirmation view for "Sign out" that appears after the idle button is tapped.
  Widget _logoutConfirm(BuildContext context) => Column(
        children: [
          // A warning box explaining what signing out does.
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              // Soft red background.
              color: const Color(0xFFEF6B6B).withValues(alpha: 0.07),
              // Red border.
              border: Border.all(
                  color: const Color(0xFFEF6B6B).withValues(alpha: 0.20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: IconLogOut(size: 14, color: Color(0xFFEF6B6B))),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning title.
                    Text(tr('Sign out of READINESS?', ref),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF6B6B))),
                    const SizedBox(height: 4),
                    // Warning description.
                    Text(
                        tr('The app will lock. Your data stays on this device — sign back in with your PIN to continue.', ref),
                        style: TextStyle(
                            fontSize: 12, color: context.rrT5, height: 1.6)),
                  ],
                )),
              ],
            ),
          ),
          // Action buttons side-by-side.
          Row(children: [
            // Cancel button: returns to 'idle' state.
            Expanded(
                child: _actionBtn(context, tr('Cancel', ref),
                    () => setState(() => _logout = 'idle'), false)),
            const SizedBox(width: 10),
            // Confirm button: triggers the onLogout callback passed from parent widget.
            // Takes up twice the width (flex: 2) as the cancel button.
            Expanded(
                flex: 2,
                child: _actionBtn(context, tr('Sign out', ref), widget.onLogout, true,
                    danger: true)), // Styled in red (danger: true).
          ]),
        ],
      );

  // Builds the default view for the "Deactivate this device" button.
  Widget _deactivateIdle(BuildContext context) => GestureDetector(
        // Switch state to 'confirm'.
        onTap: () => setState(() => _deactivate = 'confirm'),
        child: Row(children: [
          // Warning triangle icon colored amber/orange.
          const IconAlertTriangle(size: 14, color: Color(0xFFC07830)),
          const SizedBox(width: 10),
          Text(tr('Deactivate this device', ref),
              style: TextStyle(fontSize: 14, color: context.rrT2)),
        ]),
      );

  // Builds the confirmation view for "Deactivate this device".
  Widget _deactivateConfirm(BuildContext context) => Column(
        children: [
          // Amber colored warning box.
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFC07830).withValues(alpha: 0.08),
              border: Border.all(
                  color: const Color(0xFFC07830).withValues(alpha: 0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child:
                        IconAlertTriangle(size: 14, color: Color(0xFFC07830))),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Deactivate this device?', ref),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFC4A870))),
                    const SizedBox(height: 4),
                    Text(
                        tr("This will unlink the device from your unit. Your check-in history will be removed locally. You'll need a new activation code to use the app again.", ref),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A8A6A),
                            height: 1.6)),
                  ],
                )),
              ],
            ),
          ),
          Row(children: [
            // Cancel button.
            Expanded(
                child: _actionBtn(context, tr('Cancel', ref),
                    () => setState(() => _deactivate = 'idle'), false)),
            const SizedBox(width: 10),
            // Confirm button (currently has an empty callback `(){}`).
            Expanded(
                flex: 2,
                child: _actionBtn(context, tr('Deactivate', ref), () {}, false,
                    amber: true)), // Styled as amber.
          ]),
        ],
      );

  // Builds the confirmation view for "Delete all my data".
  Widget _deleteDataConfirm(BuildContext context) => Column(
        children: [
          // Red warning box explaining data deletion is permanent.
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFEF6B6B).withValues(alpha: 0.07),
              border: Border.all(
                  color: const Color(0xFFEF6B6B).withValues(alpha: 0.20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child:
                        IconAlertTriangle(size: 14, color: Color(0xFFEF6B6B))),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Delete all my data?', ref),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF6B6B))),
                    const SizedBox(height: 4),
                    Text(
                        tr('This action is irreversible. All your check-in history, metrics, and assessments will be permanently erased from our servers.', ref),
                        style: TextStyle(
                            fontSize: 12, color: context.rrT5, height: 1.6)),
                  ],
                )),
              ],
            ),
          ),
          Row(children: [
            // Cancel button.
            Expanded(
                child: _actionBtn(context, tr('Cancel', ref),
                    () => setState(() => _deleteData = 'idle'), false)),
            const SizedBox(width: 10),
            // Execute Deletion Button.
            Expanded(
                flex: 2,
                child: _actionBtn(context, tr('Delete Data', ref), () async {
                  // Attempt to tell the server to delete user data.
                  try {
                    await ref.read(authServiceProvider).deleteMyData();
                  } catch (_) {
                    // Ignore errors silently for now.
                  }
                  // Reset all global app state providers to their default/unauthenticated states.
                  ref.read(inCheckinProvider.notifier).state = false;
                  ref.read(submittedProvider.notifier).state = false;
                  ref.read(tabProvider.notifier).state = AppTab.home;
                  // Kick the user back to the PIN entry screen.
                  ref.read(screenProvider.notifier).state = AppScreen.pin;
                }, true, danger: true)), // Styled as red/danger.
          ]),
        ],
      );

  // A generic button builder used by the confirmation views above.
  Widget _actionBtn(
      BuildContext context, String label, VoidCallback onTap, bool isPrimary,
      {bool danger = false, bool amber = false}) {
    Color bg, fg;
    
    // Determine colors based on flags (danger = red, amber = orange, default = grey/theme).
    if (danger) {
      bg = const Color(0xFFEF6B6B).withValues(alpha: 0.14);
      fg = const Color(0xFFEF6B6B);
    } else if (amber) {
      bg = const Color(0xFFC07830).withValues(alpha: 0.18);
      fg = const Color(0xFFC4A870);
    } else {
      bg = context.rrDv;
      fg = context.rrT2b;
    }

    // A tappable container resembling a button.
    return GestureDetector(
      onTap: onTap, // Call the provided function when pressed.
      child: Container(
        // Padding gives the button its height.
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), // Rounded corners.
          color: bg, // Apply determined background color.
          // Add a subtle border only for danger or amber buttons.
          border: (danger || amber)
              ? Border.all(
                  color: danger
                      ? const Color(0xFFEF6B6B).withValues(alpha: 0.28)
                      : const Color(0xFFC07830).withValues(alpha: 0.30))
              : null,
        ),
        child: Center(
          // Horizontally center the button text.
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  // Thicker font for danger/amber buttons.
                  fontWeight:
                      danger || amber ? FontWeight.w600 : FontWeight.w500,
                  color: fg)), // Apply determined text color.
        ),
      ),
    );
  }
}
