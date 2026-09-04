// All custom icon widgets, backed by Flutter's Material icon set.
// dimIcon() helper maps DimKey → the correct icon widget.
import 'package:flutter/material.dart';
import '../data/seed.dart';

// ── Icon widgets ───────────────────────────────────────────────────────────

class IconShield extends StatelessWidget {
  const IconShield({super.key, this.size = 15, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.shield_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconMoon extends StatelessWidget {
  const IconMoon({super.key, this.size = 15, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.nightlight_round, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconActivity extends StatelessWidget {
  const IconActivity({super.key, this.size = 15, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.monitor_heart_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconTarget extends StatelessWidget {
  const IconTarget({super.key, this.size = 15, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.track_changes_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconFlame extends StatelessWidget {
  const IconFlame({super.key, this.size = 12, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.local_fire_department_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconCheck extends StatelessWidget {
  const IconCheck({super.key, this.size = 30, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.check, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconCalendar extends StatelessWidget {
  const IconCalendar({super.key, this.size = 15, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.calendar_today_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconLock extends StatelessWidget {
  const IconLock({super.key, this.size = 16, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.lock_outline, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconEyeOff extends StatelessWidget {
  const IconEyeOff({super.key, this.size = 16, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.visibility_off_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconCircleCheck extends StatelessWidget {
  const IconCircleCheck({super.key, this.size = 16, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.check_circle_outline, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconDelete extends StatelessWidget {
  const IconDelete({super.key, this.size = 21, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.backspace_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconFingerprint extends StatelessWidget {
  const IconFingerprint({super.key, this.size = 28, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.fingerprint, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconHome extends StatelessWidget {
  const IconHome({super.key, this.size = 20, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.home_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconTrend extends StatelessWidget {
  const IconTrend({super.key, this.size = 20, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.trending_up, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconMessageCircle extends StatelessWidget {
  const IconMessageCircle({super.key, this.size = 20, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chat_bubble_outline, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconSliders extends StatelessWidget {
  const IconSliders({super.key, this.size = 20, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.tune, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconChevronRight extends StatelessWidget {
  const IconChevronRight({super.key, this.size = 14, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconSun extends StatelessWidget {
  const IconSun({super.key, this.size = 15, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.wb_sunny_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconGlobe extends StatelessWidget {
  const IconGlobe({super.key, this.size = 15, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.language, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconBell extends StatelessWidget {
  const IconBell({super.key, this.size = 15, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.notifications_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconAlertTriangle extends StatelessWidget {
  const IconAlertTriangle({super.key, this.size = 14, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.warning_amber_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconLogOut extends StatelessWidget {
  const IconLogOut({super.key, this.size = 15, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.logout, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconCloudQueue extends StatelessWidget {
  const IconCloudQueue({super.key, this.size = 30, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.cloud_upload_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

class IconNoWifi extends StatelessWidget {
  const IconNoWifi({super.key, this.size = 12, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.wifi_off, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// ── Dim icon helper ────────────────────────────────────────────────────────
Widget dimIcon(DimKey key, {double size = 15, Color? color}) {
  switch (key) {
    case DimKey.overall:  return IconShield(size: size, color: color);
    case DimKey.sleep:    return IconMoon(size: size, color: color);
    case DimKey.physical: return IconActivity(size: size, color: color);
    case DimKey.focus:    return IconTarget(size: size, color: color);
  }
}
