import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../data/seed.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';
import '../widgets/toggle.dart';
import '../services/calendar_service.dart';
import '../providers/app_state.dart';

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
  });
  final String label;
  final String value;
  final bool arrow;
  final bool danger;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!first) Divider(color: context.rrDv, height: 26),
        Row(
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
  String _lang = 'en-GB';
  bool _langOpen = false;
  bool _reminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 30);
  bool _syncAlerts = true;
  bool _weeklySummary = false;
  String _logout = 'idle'; // 'idle' | 'confirm'
  String _deactivate = 'idle'; // 'idle' | 'confirm'

  Language get _currentLang => languages.firstWhere((l) => l.code == _lang);

  String get _reminderLabel {
    final h = _reminderTime.hour.toString().padLeft(2, '0');
    final m = _reminderTime.minute.toString().padLeft(2, '0');
    return '$h:$m daily';
  }

  Future<void> _toggleReminder() async {
    final calSvc = ref.read(calendarServiceProvider);
    if (!_reminder) {
      // Turn on: pick a time then schedule
      final picked = await showTimePicker(
        context: context,
        initialTime: _reminderTime,
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.indigo,
              onPrimary: Colors.white,
              surface: Color(0xFF1A2232),
            ),
          ),
          child: child!,
        ),
      );
      if (picked == null) return; // user cancelled
      setState(() {
        _reminderTime = picked;
        _reminder = true;
      });
      await calSvc.scheduleReminder(picked);
    } else {
      // Turn off: remove
      setState(() => _reminder = false);
      await calSvc.removeReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.rrBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.rrT1)),
              const SizedBox(height: 24),

              // ── Appearance ─────────────────────────────────────────────
              const _SectionLabel('Appearance'),
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
                            Text('Theme',
                                style: TextStyle(
                                    fontSize: 14, color: context.rrT2)),
                            const SizedBox(height: 2),
                            Text(
                                widget.isDark
                                    ? 'Low-light interface'
                                    : 'High-contrast interface',
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
                          _themeBtn(context, 'dark', 'Dark'),
                          _themeBtn(context, 'light', 'Light'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Your account ────────────────────────────────────────────
              const _SectionLabel('Your account'),
              RrCard(
                child: Column(
                  children: [
                    _SettingRow(
                        label: 'Your ID', value: ref.watch(userNameProvider) ?? 'User', first: true),
                    const _SettingRow(
                        label: 'PIN & biometrics',
                        value: 'Configured',
                        arrow: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Language & region ───────────────────────────────────────
              const _SectionLabel('Language & region'),
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
                                  Text('Language',
                                      style: TextStyle(
                                          fontSize: 14, color: context.rrT2)),
                                  Text(
                                      '${_currentLang.label} · ${_currentLang.native}',
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
                        final selected = _lang == l.code;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _lang = l.code;
                            _langOpen = false;
                          }),
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
              const _SectionLabel('Notifications'),
              RrCard(
                child: Column(
                  children: [
                    _notifRow(
                        context,
                        IconBell(
                            size: 14,
                            color: _reminder ? AppColors.indigo : context.rrT6),
                        'Check-in reminder',
                        _reminderLabel,
                        _reminder,
                        _toggleReminder,
                        true),
                    _notifRow(
                        context,
                        IconCloudQueue(
                            size: 14,
                            color:
                                _syncAlerts ? AppColors.indigo : context.rrT6),
                        'Sync alerts',
                        'When offline data syncs',
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
                        'Weekly summary',
                        'Mondays at 08:00',
                        _weeklySummary,
                        () => setState(() => _weeklySummary = !_weeklySummary),
                        false),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Data & privacy ──────────────────────────────────────────
              const _SectionLabel('Data & privacy'),
              const RrCard(
                child: Column(
                  children: [
                    _SettingRow(
                        label: 'Data handling', arrow: true, first: true),
                    _SettingRow(label: 'Delete all my data', danger: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Session ─────────────────────────────────────────────────
              const _SectionLabel('Session'),
              RrCard(
                  child: _logout == 'idle'
                      ? _logoutIdle(context)
                      : _logoutConfirm(context)),
              const SizedBox(height: 20),

              // ── Device ──────────────────────────────────────────────────
              const _SectionLabel('Device'),
              RrCard(
                  child: _deactivate == 'idle'
                      ? _deactivateIdle(context)
                      : _deactivateConfirm(context)),
              const SizedBox(height: 20),

              // ── About ────────────────────────────────────────────────────
              const _SectionLabel('About'),
              const RrCard(
                child: Column(
                  children: [
                    _SettingRow(
                        label: 'App version', value: '1.0.0', first: true),
                    _SettingRow(label: 'Unit programme', value: 'Bravo Wing'),
                  ],
                ),
              ),
            ],
          ),
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
      bool on, Function() toggle, bool first) {
    return Column(
      children: [
        if (!first) Divider(color: context.rrDv, height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              icon,
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 14, color: context.rrT2)),
                  Text(sub,
                      style: TextStyle(fontSize: 12, color: context.rrT4)),
                ],
              ),
            ]),
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
          Text('Sign out', style: TextStyle(fontSize: 14, color: context.rrT2)),
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
                    const Text('Sign out of READINESS?',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF6B6B))),
                    const SizedBox(height: 4),
                    Text(
                        'The app will lock. Your data stays on this device — sign back in with your PIN to continue.',
                        style: TextStyle(
                            fontSize: 12, color: context.rrT5, height: 1.6)),
                  ],
                )),
              ],
            ),
          ),
          Row(children: [
            Expanded(
                child: _actionBtn(context, 'Cancel',
                    () => setState(() => _logout = 'idle'), false)),
            const SizedBox(width: 10),
            Expanded(
                flex: 2,
                child: _actionBtn(context, 'Sign out', widget.onLogout, true,
                    danger: true)),
          ]),
        ],
      );

  Widget _deactivateIdle(BuildContext context) => GestureDetector(
        onTap: () => setState(() => _deactivate = 'confirm'),
        child: Row(children: [
          const IconAlertTriangle(size: 14, color: Color(0xFFC07830)),
          const SizedBox(width: 10),
          Text('Deactivate this device',
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
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: EdgeInsets.only(top: 1),
                    child:
                        IconAlertTriangle(size: 14, color: Color(0xFFC07830))),
                SizedBox(width: 10),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deactivate this device?',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFC4A870))),
                    SizedBox(height: 4),
                    Text(
                        "This will unlink the device from your unit. Your check-in history will be removed locally. You'll need a new activation code to use the app again.",
                        style: TextStyle(
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
                child: _actionBtn(context, 'Cancel',
                    () => setState(() => _deactivate = 'idle'), false)),
            const SizedBox(width: 10),
            Expanded(
                flex: 2,
                child: _actionBtn(context, 'Deactivate', () {}, false,
                    amber: true)),
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
