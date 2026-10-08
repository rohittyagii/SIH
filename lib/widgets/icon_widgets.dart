// All custom icon widgets, backed by Flutter's Material icon set.
// dimIcon() helper maps DimKey → the correct icon widget.

// Import the core Flutter Material library. This gives us access to UI components 
// like StatelessWidget, Icon, Color, BuildContext, and the Icons collection.
import 'package:flutter/material.dart';

// Import our local seed data definitions. This provides the 'DimKey' enumeration 
// which is used in the dimIcon helper function at the bottom of the file.
import '../data/seed.dart';

// ── Icon widgets ───────────────────────────────────────────────────────────

// Define a custom stateless widget named 'IconShield'.
// A StatelessWidget is a widget that does not require mutable state.
class IconShield extends StatelessWidget {
  // Constructor for IconShield. It uses 'const' for performance optimization.
  // It sets a default icon size of 15 and accepts an optional custom color.
  const IconShield({super.key, this.size = 15, this.color});
  
  // The 'final' keyword means the size value cannot change after the widget is created.
  final double size;
  
  // The 'Color?' type means this variable can hold a color, or it can be null.
  final Color? color;
  
  // The 'build' method is called by Flutter to draw the widget on the screen.
  // 'BuildContext' contains information about the widget's location in the app's widget tree.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'shield_outlined' Material icon.
      // If 'color' is provided, use it; otherwise '??' falls back to the theme's default icon color.
      Icon(Icons.shield_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconMoon'.
class IconMoon extends StatelessWidget {
  // Constructor for IconMoon. Sets a default size of 15.
  const IconMoon({super.key, this.size = 15, this.color});
  
  // Variable to store the size of the moon icon.
  final double size;
  
  // Variable to store the optional color of the moon icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'nightlight_round' Material icon.
      // Applies the size, and uses the provided color or the context's theme icon color.
      Icon(Icons.nightlight_round, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconActivity'.
class IconActivity extends StatelessWidget {
  // Constructor for IconActivity. Sets a default size of 15.
  const IconActivity({super.key, this.size = 15, this.color});
  
  // Variable to store the size of the activity icon.
  final double size;
  
  // Variable to store the optional color of the activity icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'monitor_heart_outlined' Material icon.
      Icon(Icons.monitor_heart_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconTarget'.
class IconTarget extends StatelessWidget {
  // Constructor for IconTarget. Sets a default size of 15.
  const IconTarget({super.key, this.size = 15, this.color});
  
  // Variable to store the size of the target icon.
  final double size;
  
  // Variable to store the optional color of the target icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'track_changes_outlined' Material icon.
      Icon(Icons.track_changes_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconFlame'.
class IconFlame extends StatelessWidget {
  // Constructor for IconFlame. Sets a default size of 12, smaller than others.
  const IconFlame({super.key, this.size = 12, this.color});
  
  // Variable to store the size of the flame icon.
  final double size;
  
  // Variable to store the optional color of the flame icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'local_fire_department_outlined' Material icon.
      Icon(Icons.local_fire_department_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconCheck'.
class IconCheck extends StatelessWidget {
  // Constructor for IconCheck. Sets a default size of 30, larger than others.
  const IconCheck({super.key, this.size = 30, this.color});
  
  // Variable to store the size of the check icon.
  final double size;
  
  // Variable to store the optional color of the check icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'check' Material icon.
      Icon(Icons.check, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconCalendar'.
class IconCalendar extends StatelessWidget {
  // Constructor for IconCalendar. Sets a default size of 15.
  const IconCalendar({super.key, this.size = 15, this.color});
  
  // Variable to store the size of the calendar icon.
  final double size;
  
  // Variable to store the optional color of the calendar icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'calendar_today_outlined' Material icon.
      Icon(Icons.calendar_today_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconLock'.
class IconLock extends StatelessWidget {
  // Constructor for IconLock. Sets a default size of 16.
  const IconLock({super.key, this.size = 16, this.color});
  
  // Variable to store the size of the lock icon.
  final double size;
  
  // Variable to store the optional color of the lock icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'lock_outline' Material icon.
      Icon(Icons.lock_outline, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconEyeOff'.
class IconEyeOff extends StatelessWidget {
  // Constructor for IconEyeOff. Sets a default size of 16.
  const IconEyeOff({super.key, this.size = 16, this.color});
  
  // Variable to store the size of the eye-off icon.
  final double size;
  
  // Variable to store the optional color of the eye-off icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'visibility_off_outlined' Material icon.
      Icon(Icons.visibility_off_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconCircleCheck'.
class IconCircleCheck extends StatelessWidget {
  // Constructor for IconCircleCheck. Sets a default size of 16.
  const IconCircleCheck({super.key, this.size = 16, this.color});
  
  // Variable to store the size of the circle-check icon.
  final double size;
  
  // Variable to store the optional color of the circle-check icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'check_circle_outline' Material icon.
      Icon(Icons.check_circle_outline, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconDelete'.
class IconDelete extends StatelessWidget {
  // Constructor for IconDelete. Sets a default size of 21.
  const IconDelete({super.key, this.size = 21, this.color});
  
  // Variable to store the size of the delete icon.
  final double size;
  
  // Variable to store the optional color of the delete icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'backspace_outlined' Material icon.
      Icon(Icons.backspace_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconFingerprint'.
class IconFingerprint extends StatelessWidget {
  // Constructor for IconFingerprint. Sets a default size of 28.
  const IconFingerprint({super.key, this.size = 28, this.color});
  
  // Variable to store the size of the fingerprint icon.
  final double size;
  
  // Variable to store the optional color of the fingerprint icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'fingerprint' Material icon.
      Icon(Icons.fingerprint, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconHome'.
class IconHome extends StatelessWidget {
  // Constructor for IconHome. Sets a default size of 20.
  const IconHome({super.key, this.size = 20, this.color});
  
  // Variable to store the size of the home icon.
  final double size;
  
  // Variable to store the optional color of the home icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'home_outlined' Material icon.
      Icon(Icons.home_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconTrend'.
class IconTrend extends StatelessWidget {
  // Constructor for IconTrend. Sets a default size of 20.
  const IconTrend({super.key, this.size = 20, this.color});
  
  // Variable to store the size of the trend icon.
  final double size;
  
  // Variable to store the optional color of the trend icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'trending_up' Material icon.
      Icon(Icons.trending_up, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconMessageCircle'.
class IconMessageCircle extends StatelessWidget {
  // Constructor for IconMessageCircle. Sets a default size of 20.
  const IconMessageCircle({super.key, this.size = 20, this.color});
  
  // Variable to store the size of the message circle icon.
  final double size;
  
  // Variable to store the optional color of the message circle icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'chat_bubble_outline' Material icon.
      Icon(Icons.chat_bubble_outline, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconSliders'.
class IconSliders extends StatelessWidget {
  // Constructor for IconSliders. Sets a default size of 20.
  const IconSliders({super.key, this.size = 20, this.color});
  
  // Variable to store the size of the sliders icon.
  final double size;
  
  // Variable to store the optional color of the sliders icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'tune' Material icon.
      Icon(Icons.tune, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconChevronRight'.
class IconChevronRight extends StatelessWidget {
  // Constructor for IconChevronRight. Sets a default size of 14.
  const IconChevronRight({super.key, this.size = 14, this.color});
  
  // Variable to store the size of the chevron right icon.
  final double size;
  
  // Variable to store the optional color of the chevron right icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'chevron_right' Material icon.
      Icon(Icons.chevron_right, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconSun'.
class IconSun extends StatelessWidget {
  // Constructor for IconSun. Sets a default size of 15.
  const IconSun({super.key, this.size = 15, this.color});
  
  // Variable to store the size of the sun icon.
  final double size;
  
  // Variable to store the optional color of the sun icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'wb_sunny_outlined' Material icon.
      Icon(Icons.wb_sunny_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconGlobe'.
class IconGlobe extends StatelessWidget {
  // Constructor for IconGlobe. Sets a default size of 15.
  const IconGlobe({super.key, this.size = 15, this.color});
  
  // Variable to store the size of the globe icon.
  final double size;
  
  // Variable to store the optional color of the globe icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'language' Material icon (which looks like a globe).
      Icon(Icons.language, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconBell'.
class IconBell extends StatelessWidget {
  // Constructor for IconBell. Sets a default size of 15.
  const IconBell({super.key, this.size = 15, this.color});
  
  // Variable to store the size of the bell icon.
  final double size;
  
  // Variable to store the optional color of the bell icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'notifications_outlined' Material icon.
      Icon(Icons.notifications_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconAlertTriangle'.
class IconAlertTriangle extends StatelessWidget {
  // Constructor for IconAlertTriangle. Sets a default size of 14.
  const IconAlertTriangle({super.key, this.size = 14, this.color});
  
  // Variable to store the size of the alert triangle icon.
  final double size;
  
  // Variable to store the optional color of the alert triangle icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'warning_amber_outlined' Material icon.
      Icon(Icons.warning_amber_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconLogOut'.
class IconLogOut extends StatelessWidget {
  // Constructor for IconLogOut. Sets a default size of 15.
  const IconLogOut({super.key, this.size = 15, this.color});
  
  // Variable to store the size of the logout icon.
  final double size;
  
  // Variable to store the optional color of the logout icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'logout' Material icon.
      Icon(Icons.logout, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconCloudQueue'.
class IconCloudQueue extends StatelessWidget {
  // Constructor for IconCloudQueue. Sets a default size of 30.
  const IconCloudQueue({super.key, this.size = 30, this.color});
  
  // Variable to store the size of the cloud queue icon.
  final double size;
  
  // Variable to store the optional color of the cloud queue icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'cloud_upload_outlined' Material icon.
      Icon(Icons.cloud_upload_outlined, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// Define a custom stateless widget named 'IconNoWifi'.
class IconNoWifi extends StatelessWidget {
  // Constructor for IconNoWifi. Sets a default size of 12.
  const IconNoWifi({super.key, this.size = 12, this.color});
  
  // Variable to store the size of the no-wifi icon.
  final double size;
  
  // Variable to store the optional color of the no-wifi icon.
  final Color? color;
  
  // Override the build method to define the widget's UI.
  @override
  Widget build(BuildContext context) =>
      // Return an 'Icon' widget using the 'wifi_off' Material icon.
      Icon(Icons.wifi_off, size: size, color: color ?? Theme.of(context).iconTheme.color);
}

// ── Dim icon helper ────────────────────────────────────────────────────────

// A helper function named 'dimIcon' that returns a Widget based on a 'DimKey'.
// 'DimKey' represents a specific dimension or category (like sleep, focus, physical activity).
// The function takes a 'DimKey' as a required argument, and allows optional 'size' (defaulting to 15) and 'color'.
Widget dimIcon(DimKey key, {double size = 15, Color? color}) {
  // Use a 'switch' statement to evaluate the value of the provided 'key'.
  switch (key) {
    // If the key is 'DimKey.overall', return an IconShield widget with the specified size and color.
    case DimKey.overall:  return IconShield(size: size, color: color);
    
    // If the key is 'DimKey.sleep', return an IconMoon widget with the specified size and color.
    case DimKey.sleep:    return IconMoon(size: size, color: color);
    
    // If the key is 'DimKey.physical', return an IconActivity widget with the specified size and color.
    case DimKey.physical: return IconActivity(size: size, color: color);
    
    // If the key is 'DimKey.focus', return an IconTarget widget with the specified size and color.
    case DimKey.focus:    return IconTarget(size: size, color: color);
  }
}
