import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/colors.dart';
import '../data/seed.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';
import '../widgets/toggle.dart';
import '../widgets/bottom_nav.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../providers/app_state.dart';
import '../data/translations.dart';
import 'data_handling_screen.dart';
import 'change_pin_screen.dart';

// ── Shared sub-widgets ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.rrT6,
                letterSpacing: 0.07)),
      );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    this.value = '',
    this.arrow = false,
    this.danger = false,
    this.first = false,
    this.onTap,
  });
  final String label;
  final String value;
  final bool arrow;
  final bool danger;
  final bool first;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!first) Divider(color: context.rrDv, height: 26),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      color: danger ? AppColors.score1 : context.rrT2)),
              if (value.isNotEmpty || arrow)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (value.isNotEmpty)
                      Text(value,
                          style: TextStyle(fontSize: 13, color: context.rrT4)),
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

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen(
      {super.key,
      required this.isDark,
      required this.onThemeToggle,
      required this.onLogout});
  final bool isDark;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _langOpen = false;
  bool _reminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 30);
  bool _syncAlerts = true;
  bool _weeklySummary = false;
  String _logout = 'idle'; // 'idle' | 'confirm'
  String _deactivate = 'idle'; // 'idle' | 'confirm'
  String _deleteData = 'idle'; // 'idle' | 'confirm'

  @override
  void initState() {
    super.initState();
    _loadSavedReminder();
  }

  Future<void> _loadSavedReminder() async {
    final notifSvc = ref.read(notificationServiceProvider);
    final saved = await notifSvc.getSavedReminder();
    if (saved != null && mounted) {
      setState(() {
        _reminder = saved.enabled;
        _reminderTime = saved.timeOfDay;
      });
    }
  }

  Language _getCurrentLang(String code) => languages
      .firstWhere((l) => l.code == code, orElse: () => languages.first);

  String _getReminderLabel() {
    final h = _reminderTime.hour.toString().padLeft(2, '0');
    final m = _reminderTime.minute.toString().padLeft(2, '0');
    return '$h:$m ${tr('daily', ref)}';
  }

  Future<TimeOfDay?> _pickTime() async {
    return showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
  }

  Future<void> _toggleReminder() async {
    final notifSvc = ref.read(notificationServiceProvider);
    if (!_reminder) {
      // Turn on: pick a time then schedule
      final picked = await _pickTime();
      if (picked == null) return; // user cancelled
      setState(() {
        _reminderTime = picked;
        _reminder = true;
      });
      await notifSvc.scheduleDailyReminder(picked);
    } else {
      // Turn off: cancel
      setState(() => _reminder = false);
      await notifSvc.cancelDailyReminder();
    }
  }

  /// Tap the time label to change the scheduled time without toggling off.
  Future<void> _changeReminderTime() async {
    final picked = await _pickTime();
    if (picked == null) return;
    setState(() => _reminderTime = picked);
    final notifSvc = ref.read(notificationServiceProvider);
    await notifSvc.scheduleDailyReminder(picked);
  }

  @override
  Widget build(BuildContext context) {
    final currentLangCode = ref.watch(languagePrefProvider);
    final currentLang = _getCurrentLang(currentLangCode);

    return Scaffold(
      backgroundColor: context.rrBg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 24, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Settings', ref),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.rrT1)),
              const SizedBox(height: 24),

              // ── Appearance ─────────────────────────────────────────────
              _SectionLabel(tr('Appearance', ref)),
              RrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('Theme', ref),
                                style: TextStyle(
                                    fontSize: 14, color: context.rrT2)),
                            const SizedBox(height: 2),
                            Text(
                                widget.isDark
                                    ? tr('Low-light interface', ref)
                                    : tr('High-contrast interface', ref),
                                style: TextStyle(
                                    fontSize: 12, color: context.rrT4)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: context.rrIn,
                        border: Border.all(color: context.rrDv2),
                      ),
                      child: Row(
                        children: [
                          _themeBtn(context, 'dark', tr('Dark', ref)),
                          _themeBtn(context, 'light', tr('Light', ref)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Your account ────────────────────────────────────────────
              _SectionLabel(tr('Your account', ref)),
              RrCard(
                child: Column(
                  children: [
                    _SettingRow(
                        label: tr('Your ID', ref),
                        value: ref.watch(userNameProvider) ?? 'User',
                        first: true),
                    _SettingRow(
                        label: tr('PIN & biometrics', ref),
                        value: tr('Configured', ref),
                        arrow: true,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const ChangePinScreen(),
                          ));
                        }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Language & region ───────────────────────────────────────
              _SectionLabel(tr('Language & region', ref)),
              RrCard(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _langOpen = !_langOpen),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconGlobe(size: 15, color: context.rrT4),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('Language', ref),
                                      style: TextStyle(
                                          fontSize: 14, color: context.rrT2)),
                                  Text(
                                      '${currentLang.label} · ${currentLang.native}',
                                      style: TextStyle(
                                          fontSize: 12, color: context.rrT4)),
                                ],
                              ),
                            ],
                          ),
                          AnimatedRotation(
                            turns: _langOpen ? 0.25 : 0,
                            duration: const Duration(milliseconds: 200),
                            child:
                                IconChevronRight(size: 13, color: context.rrT6),
                          ),
                        ],
                      ),
                    ),
                    if (_langOpen) ...[
                      Divider(color: context.rrDv2, height: 28),
                      ...languages.map((l) {
                        final selected = currentLangCode == l.code;
                        return GestureDetector(
                          onTap: () async {
                            ref.read(languagePrefProvider.notifier).state =
                                l.code;
                            setState(() => _langOpen = false);

                            const storage = FlutterSecureStorage();
                            await storage.write(
                                key: 'language_pref', value: l.code);

                            try {
                              await ref
                                  .read(authServiceProvider)
                                  .updatePreferences({'language_pref': l.code});
                            } catch (_) {}
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              color: selected
                                  ? AppColors.indigo.withValues(alpha: 0.10)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Text(l.label,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                          color: selected
                                              ? context.rrT2
                                              : context.rrT2b)),
                                  if (l.native != 'English') ...[
                                    const SizedBox(width: 8),
                                    Text(l.native,
                                        style: TextStyle(
                                            fontSize: 12, color: context.rrT4)),
                                  ],
                                ]),
                                if (selected)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.indigo,
                                      boxShadow: [
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
              _SectionLabel(tr('Notifications', ref)),
              RrCard(
                child: Column(
                  children: [
                    _notifRow(
                        context,
                        IconBell(
                            size: 14,
                            color: _reminder ? AppColors.indigo : context.rrT6),
                        tr('Daily reminder', ref),
                        _getReminderLabel(),
                        _reminder,
                        _toggleReminder,
                        true,
                        onLabelTap: _reminder ? _changeReminderTime : null),
                    _notifRow(
                        context,
                        IconCloudQueue(
                            size: 14,
                            color:
                                _syncAlerts ? AppColors.indigo : context.rrT6),
                        tr('Sync alerts', ref),
                        tr('When offline data syncs', ref),
                        _syncAlerts,
                        () => setState(() => _syncAlerts = !_syncAlerts),
                        false),
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
                        () => setState(() => _weeklySummary = !_weeklySummary),
                        false),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Data & privacy ──────────────────────────────────────────
              _SectionLabel(tr('Data & privacy', ref)),
              RrCard(
                child: _deleteData == 'idle'
                    ? Column(
                        children: [
                          _SettingRow(
                            label: tr('Data handling', ref),
                            arrow: true,
                            first: true,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const DataHandlingScreen(),
                              ));
                            },
                          ),
                          _SettingRow(
                            label: tr('Delete all my data', ref),
                            danger: true,
                            onTap: () =>
                                setState(() => _deleteData = 'confirm'),
                          ),
                        ],
                      )
                    : _deleteDataConfirm(context),
              ),
              const SizedBox(height: 20),

              // ── Session ─────────────────────────────────────────────────
              _SectionLabel(tr('Session', ref)),
              RrCard(
                  child: _logout == 'idle'
                      ? _logoutIdle(context)
                      : _logoutConfirm(context)),
              const SizedBox(height: 20),

              // ── Device ──────────────────────────────────────────────────
              _SectionLabel(tr('Device', ref)),
              RrCard(
                  child: _deactivate == 'idle'
                      ? _deactivateIdle(context)
                      : _deactivateConfirm(context)),
              const SizedBox(height: 20),

              // ── About ────────────────────────────────────────────────────
              _SectionLabel(tr('About', ref)),
              RrCard(
                child: Column(
                  children: [
                    _SettingRow(
                        label: tr('App version', ref), value: '1.0.0', first: true),
                    _SettingRow(label: tr('Unit programme', ref), value: tr('Eastern Command', ref)),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _themeBtn(BuildContext context, String t, String label) {
    final active = widget.isDark ? t == 'dark' : t == 'light';
    return Expanded(
      child: GestureDetector(
        onTap: active ? null : widget.onThemeToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: active ? context.rrB1 : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (t == 'dark')
                IconMoon(size: 14, color: active ? context.rrT2 : context.rrT6)
              else
                IconSun(size: 14, color: active ? context.rrT2 : context.rrT6),
              const SizedBox(width: 7),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                      color: active ? context.rrT2 : context.rrT4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notifRow(BuildContext context, Widget icon, String label, String sub,
      bool on, Function() toggle, bool first, {VoidCallback? onLabelTap}) {
    return Column(
      children: [
        if (!first) Divider(color: context.rrDv, height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onLabelTap,
              child: Row(children: [
                icon,
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(fontSize: 14, color: context.rrT2)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(sub,
                            style: TextStyle(fontSize: 12, color: context.rrT4)),
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
            Toggle(on: on, onToggle: toggle),
          ],
        ),
      ],
    );
  }

  Widget _logoutIdle(BuildContext context) => GestureDetector(
        onTap: () => setState(() => _logout = 'confirm'),
        child: Row(children: [
          const IconLogOut(size: 15, color: Color(0xFFEF6B6B)),
          const SizedBox(width: 10),
          Text(tr('Sign out', ref), style: TextStyle(fontSize: 14, color: context.rrT2)),
        ]),
      );

  Widget _logoutConfirm(BuildContext context) => Column(
        children: [
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
                    child: IconLogOut(size: 14, color: Color(0xFFEF6B6B))),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Sign out of READINESS?', ref),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF6B6B))),
                    const SizedBox(height: 4),
                    Text(
                        tr('The app will lock. Your data stays on this device — sign back in with your PIN to continue.', ref),
                        style: TextStyle(
                            fontSize: 12, color: context.rrT5, height: 1.6)),
                  ],
                )),
              ],
            ),
          ),
          Row(children: [
            Expanded(
                child: _actionBtn(context, tr('Cancel', ref),
                    () => setState(() => _logout = 'idle'), false)),
            const SizedBox(width: 10),
            Expanded(
                flex: 2,
                child: _actionBtn(context, tr('Sign out', ref), widget.onLogout, true,
                    danger: true)),
          ]),
        ],
      );

  Widget _deactivateIdle(BuildContext context) => GestureDetector(
        onTap: () => setState(() => _deactivate = 'confirm'),
        child: Row(children: [
          const IconAlertTriangle(size: 14, color: Color(0xFFC07830)),
          const SizedBox(width: 10),
          Text(tr('Deactivate this device', ref),
              style: TextStyle(fontSize: 14, color: context.rrT2)),
        ]),
      );

  Widget _deactivateConfirm(BuildContext context) => Column(
        children: [
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
            Expanded(
                child: _actionBtn(context, tr('Cancel', ref),
                    () => setState(() => _deactivate = 'idle'), false)),
            const SizedBox(width: 10),
            Expanded(
                flex: 2,
                child: _actionBtn(context, tr('Deactivate', ref), () {}, false,
                    amber: true)),
          ]),
        ],
      );

  Widget _deleteDataConfirm(BuildContext context) => Column(
        children: [
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
            Expanded(
                child: _actionBtn(context, tr('Cancel', ref),
                    () => setState(() => _deleteData = 'idle'), false)),
            const SizedBox(width: 10),
            Expanded(
                flex: 2,
                child: _actionBtn(context, tr('Delete Data', ref), () async {
                  try {
                    await ref.read(authServiceProvider).deleteMyData();
                  } catch (_) {}
                  ref.read(inCheckinProvider.notifier).state = false;
                  ref.read(submittedProvider.notifier).state = false;
                  ref.read(tabProvider.notifier).state = AppTab.home;
                  ref.read(screenProvider.notifier).state = AppScreen.pin;
                }, true, danger: true)),
          ]),
        ],
      );

  Widget _actionBtn(
      BuildContext context, String label, VoidCallback onTap, bool isPrimary,
      {bool danger = false, bool amber = false}) {
    Color bg, fg;
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bg,
          border: (danger || amber)
              ? Border.all(
                  color: danger
                      ? const Color(0xFFEF6B6B).withValues(alpha: 0.28)
                      : const Color(0xFFC07830).withValues(alpha: 0.30))
              : null,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      danger || amber ? FontWeight.w600 : FontWeight.w500,
                  color: fg)),
        ),
      ),
    );
  }
}
