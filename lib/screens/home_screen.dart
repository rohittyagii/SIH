// Import the math library to perform mathematical operations like sine, cosine, and calculating Pi.
// We use 'as math' so we can refer to it with 'math.something' instead of just 'something'.
import 'dart:math' as math;
// Import the core Flutter material library, which provides UI components like widgets, colors, and layout tools.
import 'package:flutter/material.dart';
// Import Riverpod, a state management library for Flutter that helps us read and update app data.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import our custom colors defined in the 'theme' folder.
import '../theme/colors.dart';
// Import custom icon widgets that we use in our app.
import '../widgets/icon_widgets.dart';
// Import the bottom navigation widget to handle tabs at the bottom of the screen.
import '../widgets/bottom_nav.dart';
// Import an animated background widget that shows floating "orbs".
import '../widgets/animated_orbs.dart';
// Import the app state provider, which gives us access to global data like the user's name.
import '../providers/app_state.dart';
// Import the translations file, which allows us to support multiple languages using the 'tr()' function.
import '../data/translations.dart';

// ── HomeScreen ───────────────────────────────────────────────────────────────

// Define the HomeScreen class as a ConsumerWidget. A ConsumerWidget is a Riverpod widget
// that can "listen" to providers for state changes and rebuild when the data updates.
class HomeScreen extends ConsumerWidget {
  // The constructor for HomeScreen. It takes several required parameters to handle actions and display data.
  // 'super.key' passes the key to the parent widget.
  const HomeScreen({
    super.key,
    required this.onStartCheckin, // Callback function when the user wants to start a check-in.
    required this.onTab,          // Callback function when the user switches tabs.
    required this.todayDone,      // Boolean indicating if the user has already checked in today.
    required this.streak,         // Integer representing the user's current day streak.
  });

  // A function that gets called when the "Start Check-in" button is pressed.
  final VoidCallback onStartCheckin;
  // A function that gets called with an AppTab value to change the current tab.
  final ValueChanged<AppTab> onTab;
  // True if the daily check-in is done, otherwise false.
  final bool todayDone;
  // The number of consecutive days the user has checked in.
  final int streak;

  // A "getter" method that dynamically returns a greeting string based on the current time of day.
  String get _greeting {
    // Get the current hour from the system time (0 to 23).
    final h = DateTime.now().hour;
    // If the hour is before 12 PM (noon), return 'Good morning'.
    if (h < 12) return 'Good morning';
    // If the hour is before 5 PM (17:00), return 'Good afternoon'.
    if (h < 17) return 'Good afternoon';
    // Otherwise (5 PM or later), return 'Good evening'.
    return 'Good evening';
  }

  // A "getter" method that formats the current date into a readable string (e.g., "Monday, 1 Jan 2024").
  String get _todayLabel {
    // Get the current date and time.
    final now = DateTime.now();
    // A list of the days of the week to map the weekday number to a name.
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    // A list of the months of the year to map the month number to a short name.
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    // Construct and return the formatted date string.
    // now.weekday is 1 for Monday, 7 for Sunday. We subtract 1 to get the correct list index (0-based).
    // now.month is 1 for January, 12 for December. We subtract 1 to get the correct list index.
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // The build method creates the UI for this widget. It is called every time the widget needs to be drawn.
  // We get 'context' (info about widget's location) and 'ref' (to read Riverpod providers).
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the user's name from 'userNameProvider'. If it is null, default to 'User'.
    // ref.watch means this widget will rebuild if the user's name changes.
    final userName = ref.watch(userNameProvider) ?? 'User';

    // Scaffold provides the basic structural layout for a material design app (background, app bars, etc.).
    return Scaffold(
      // Set the background color using a custom extension on 'context' (likely defined in colors.dart).
      backgroundColor: context.rrBg,
      // Stack allows us to place widgets on top of each other.
      body: Stack(
        children: [
          // The bottom-most layer in the stack is an animated background with moving orbs.
          const AnimatedOrbsBackground(),
          // Positioned.fill makes its child fill the entire available space of the Stack.
          Positioned.fill(
            // Padding adds space around its child widget.
            child: Padding(
              // Add padding: left 20, top (safe area + 52), right 20, bottom 120.
              // MediaQuery.of(context).padding.top ensures we don't overlap with the status bar (like time/battery).
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 52, 20, 120),
              // Column arranges its children vertically from top to bottom.
              child: Column(
                // Align children to the start (left side) of the column.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // This Padding widget holds the greeting section (greeting, name, date, streak).
                  Padding(
                    // Add 8 pixels of padding to the top of this section.
                    padding: const EdgeInsets.only(top: 8),
                    // Inner Column for the greeting text elements.
                    child: Column(
                      // Align these text elements to the start (left).
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display the translated greeting (e.g., "Good morning,").
                        // tr() is a custom function to handle translations using 'ref' for locale state.
                        Text('${tr(_greeting, ref)},',
                            // Style the text: font size 14, and color based on current theme (rrT4).
                            style:
                                TextStyle(fontSize: 14, color: context.rrT4)),
                        // Add a small vertical space of 2 pixels.
                        const SizedBox(height: 2),
                        // Display the user's name.
                        Text(userName,
                            // Style the user's name: size 32, semi-bold weight, primary text color, slightly tighter letter spacing.
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: context.rrT1,
                                letterSpacing: -0.01 * 32)),
                        // Add a vertical space of 8 pixels.
                        const SizedBox(height: 8),
                        // A Row arranges its children horizontally side-by-side.
                        Row(
                          children: [
                            // Flexible allows the text to shrink or truncate if there is not enough horizontal space.
                            Flexible(
                              // Display the formatted today's date.
                              child: Text(_todayLabel,
                                  // Style: size 13, secondary text color (rrT5).
                                  style: TextStyle(
                                      fontSize: 13, color: context.rrT5),
                                  // If the text is too long, end it with an ellipsis (...).
                                  overflow: TextOverflow.ellipsis),
                            ),
                            // If the user has a streak greater than 0, show the streak UI.
                            // The '...' is the spread operator, adding multiple widgets to the list.
                            if (streak > 0) ...[
                              // Add 10 pixels of horizontal space.
                              const SizedBox(width: 10),
                              // Draw a small circular dot separator.
                              Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.rrT7)),
                              // Add another 10 pixels of horizontal space.
                              const SizedBox(width: 10),
                              // Container to create a pill-shaped background for the streak.
                              Container(
                                // Add inner padding (10 left/right, 4 top/bottom).
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                // Style the container with a rounded border and a light indigo background color.
                                decoration: BoxDecoration(
                                  // Make it fully rounded like a pill.
                                  borderRadius: BorderRadius.circular(999),
                                  // Set background color to indigo with 10% opacity.
                                  color:
                                      AppColors.indigo.withValues(alpha: 0.10),
                                  // Add a subtle border to the pill.
                                  border: Border.all(
                                      color: AppColors.indigo
                                          .withValues(alpha: 0.20)),
                                ),
                                // Inner Row for the flame icon and streak text.
                                child: Row(
                                  // Keep the row as small as possible to just fit its children.
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Custom flame icon widget colored indigo.
                                    const IconFlame(
                                        size: 12, color: AppColors.indigo),
                                    // Small space between icon and text.
                                    const SizedBox(width: 4),
                                    // Display the translated 'Day' word and the streak number.
                                    Text('${tr('Day', ref)} $streak',
                                        // Style the streak text: size 11, semi-bold, indigo color.
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.indigo)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expanded takes up all remaining available vertical space in the Column.
                  const Expanded(
                    // Center aligns its child to the exact middle of the available space.
                    child: Center(
                      // Custom breathing circle widget that animates.
                      child: _BreathingCircle(),
                    ),
                  ),
                  // CTA (Call To Action) section placed at the bottom of the column.
                  Padding(
                    // Add 24 pixels of padding to the bottom.
                    padding: const EdgeInsets.only(bottom: 24),
                    // Column to stack the status dot, check-in button, and quick links vertically.
                    child: Column(
                      children: [
                        // Row for the status indicator (dot + text).
                        Row(
                          // Center the children horizontally within the row.
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // A small circular dot.
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // Color changes based on whether the user checked in today.
                                color:
                                    todayDone ? AppColors.score5 : context.rrT6,
                              ),
                            ),
                            // Space between dot and text.
                            const SizedBox(width: 8),
                            // Text showing the check-in status.
                            Text(
                              // Translate the appropriate string based on whether they checked in today.
                              todayDone
                                  ? tr('Checked in today', ref)
                                  : tr('Not yet checked in today', ref),
                              // Style the text: color changes to green if checked in, else greyish.
                              style: TextStyle(
                                  fontSize: 13,
                                  color: todayDone
                                      ? const Color(0xFF3EC4A0)
                                      : context.rrT4),
                            ),
                          ],
                        ),
                        // Add 20 pixels of vertical space.
                        const SizedBox(height: 20),
                        // GestureDetector allows us to detect taps on its child.
                        GestureDetector(
                          // When tapped, trigger the onStartCheckin callback passed in the constructor.
                          onTap: onStartCheckin,
                          // AnimatedContainer animates changes to its properties (like color/border) over a duration.
                          child: AnimatedContainer(
                            // The animation takes 200 milliseconds to complete.
                            duration: const Duration(milliseconds: 200),
                            // Make the container take up the full available width.
                            width: double.infinity,
                            // Add 20 pixels of padding inside the button.
                            padding: const EdgeInsets.all(20),
                            // Style the button's background, border, and shadow.
                            decoration: BoxDecoration(
                              // Round the corners of the button.
                              borderRadius: BorderRadius.circular(16),
                              // If done, show a light green background. If not, solid indigo.
                              color: todayDone
                                  ? const Color(0xFF3EC4A0)
                                      .withValues(alpha: 0.12)
                                  : AppColors.indigo,
                              // If done, add a light green border. If not, no border.
                              border: todayDone
                                  ? Border.all(
                                      color: const Color(0xFF3EC4A0)
                                          .withValues(alpha: 0.25))
                                  : null,
                              // If NOT done, show a shadow below the indigo button to make it pop.
                              boxShadow: todayDone
                                  ? []
                                  : [
                                      BoxShadow(
                                          color: AppColors.indigo
                                              .withValues(alpha: 0.34),
                                          blurRadius: 36, // How soft the shadow is.
                                          offset: const Offset(0, 6)) // Shadow moved 6 pixels down.
                                    ],
                            ),
                            // The text displayed on the button.
                            child: Text(
                              // Determine the label text based on check-in status and translate it.
                              todayDone
                                  ? tr("View today's entry", ref)
                                  : tr("Start today's check-in", ref),
                              // Center the text horizontally.
                              textAlign: TextAlign.center,
                              // Style the button text.
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                // Color changes to green if done, else dark greyish-blue.
                                color: todayDone
                                    ? const Color(0xFF3EC4A0)
                                    : const Color(0xFF0C1220),
                                // Tighten the letter spacing slightly.
                                letterSpacing: -0.01 * 17,
                              ),
                            ),
                          ),
                        ),
                        // Add 18 pixels of vertical space.
                        const SizedBox(height: 18),
                        // Quick links section at the bottom (Trend and Support).
                        Column(
                          children: [
                            // Helper method to create a clickable link for "View my trend".
                            // Navigates to the 'trend' tab when tapped.
                            _quickLink(context, tr('View my trend', ref),
                                AppColors.indigo, () => onTab(AppTab.trend)),
                            // Add 18 pixels of vertical space.
                            const SizedBox(height: 18),
                            // Helper method to create a clickable link for "Resources & support".
                            // Navigates to the 'support' tab when tapped.
                            _quickLink(context, tr('Resources & support', ref),
                                context.rrT4, () => onTab(AppTab.support)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A private helper function that creates a row containing text and an arrow icon, making it clickable.
  // It takes the BuildContext, the text to display, the color for text/icon, and what happens when tapped.
  Widget _quickLink(
      BuildContext context, String label, Color color, VoidCallback onTap) {
    // GestureDetector makes the row clickable.
    return GestureDetector(
      // The function to run when the user taps this link.
      onTap: onTap,
      // A Row to put the text and the chevron (arrow) icon side-by-side.
      child: Row(
        // Center them horizontally.
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display the text with the given color and size 15.
          Text(label, style: TextStyle(fontSize: 15, color: color)),
          // Add a small 4-pixel space between text and icon.
          const SizedBox(width: 4),
          // Custom icon widget showing a right-pointing arrow, colored to match the text.
          IconChevronRight(size: 13, color: color),
        ],
      ),
    );
  }
}

// ── Breathing Circle ────────────────────────────────────────────────────────

// Define a stateful widget for the breathing animation circle.
// ConsumerStatefulWidget means it can both hold its own internal state (like animations)
// and read Riverpod providers.
class _BreathingCircle extends ConsumerStatefulWidget {
  const _BreathingCircle();

  @override
  // Creates the state object that manages the state for this widget.
  ConsumerState<_BreathingCircle> createState() => _BreathingCircleState();
}

// The State class for _BreathingCircle.
// 'with TickerProviderStateMixin' is required for animations. It allows this class
// to provide a "ticker" (like a frame-by-frame clock) to AnimationControllers.
class _BreathingCircleState extends ConsumerState<_BreathingCircle>
    with TickerProviderStateMixin {
  // Controller for the breathing in/out scale and opacity animation.
  late AnimationController _breatheController;
  // Controller for the continuous rotation of the circles.
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    // Initialize the breathe controller.
    _breatheController = AnimationController(
      vsync: this, // The ticker provider.
      duration: const Duration(seconds: 4), // A full breath takes 4 seconds.
    )..addStatusListener((status) {
        // Listen to changes in the animation status.
        if (status == AnimationStatus.completed) {
          // When it reaches 1.0 (fully breathed out), reverse it (breathe in).
          _breatheController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          // When it reaches 0.0 (fully breathed in), start going forward again.
          _breatheController.forward();
        }
      });
    // Start the breathing animation immediately.
    _breatheController.forward();

    // Initialize the rotate controller.
    _rotateController = AnimationController(
      vsync: this, // The ticker provider.
      duration: const Duration(seconds: 12), // One full rotation takes 12 seconds.
    )..repeat(); // Make it repeat infinitely.
  }

  @override
  void dispose() {
    // When the widget is removed from the screen, we MUST dispose of the animation controllers
    // to free up memory and stop the ticker.
    _breatheController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder rebuilds its builder function every time the animation changes.
    return AnimatedBuilder(
      // We listen to both controllers by merging them into one Listenable.
      // Every time either controller updates a frame, the widget rebuilds.
      animation: Listenable.merge([_breatheController, _rotateController]),
      builder: (context, child) {
        // Calculate the current scale factor based on the breathe animation value (which goes 0.0 to 1.0).
        // It starts at 1.0x and grows to 1.6x at its peak.
        final scale =
            1.0 + (_breatheController.value * 0.6); // Scales from 1x to 1.6x
        
        // Calculate the opacity of the circle based on the breathe animation.
        // It starts at 0.05 and goes up to 0.15.
        final opacity = 0.05 + (_breatheController.value * 0.1);
        
        // Determine if we are currently "breathing in" (expanding).
        // This is true if the animation is playing forward, or just starting.
        final isBreathingIn =
            _breatheController.status == AnimationStatus.forward ||
                _breatheController.status == AnimationStatus.dismissed;
        
        // Calculate the current rotation angle in radians.
        // _rotateController.value goes from 0.0 to 1.0, so multiplying by 2*PI gives a full circle (0 to 360 degrees).
        final time = _rotateController.value * 2 * math.pi;

        // A Column to hold the stack of animated widgets.
        return Column(
          // Take up only as much vertical space as the children need.
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stack centers its children on top of one another.
            Stack(
              // Align all children precisely in the center.
              alignment: Alignment.center,
              children: [
                // Pulsating irregular ring (the outer shape).
                // Transform.scale scales the size up and down.
                Transform.scale(
                  scale: scale, // Apply the breathing scale.
                  // Transform.rotate spins the shape around.
                  child: Transform.rotate(
                    angle: time, // Apply the continuous rotation.
                    // CustomPaint allows us to draw custom shapes using code.
                    child: CustomPaint(
                      size: const Size(140, 140), // Base size of the shape.
                      // Provide our custom painter class.
                      painter: _IrregularCirclePainter(
                        color: AppColors.indigo.withValues(alpha: opacity), // Faded indigo color.
                        isFilled: true, // This shape is filled solid.
                        time: time, // Pass rotation time to distort the shape slightly.
                      ),
                    ),
                  ),
                ),
                // Inner static irregular circle (the outline shape).
                // It rotates in the opposite direction (because of the negative sign) and at half the speed.
                Transform.rotate(
                  angle: -time * 0.5,
                  child: CustomPaint(
                    size: const Size(140, 140),
                    painter: _IrregularCirclePainter(
                      color: AppColors.indigo.withValues(alpha: 0.3), // Slightly darker but transparent.
                      isFilled: false, // This shape is just an outline, not filled.
                      time: time * 1.5, // Distort it faster than the outer one.
                    ),
                  ),
                ),
                // Text indicating whether to breathe in or breathe out.
                // AnimatedSwitcher animates transitions (like cross-fades) when its child changes.
                AnimatedSwitcher(
                  // The cross-fade takes 800 milliseconds.
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    // Show translated text based on the current breathing phase.
                    isBreathingIn
                        ? tr('Breathe in...', ref)
                        : tr('Breathe out...', ref),
                    // Using a ValueKey tells AnimatedSwitcher that this is a completely different widget
                    // when the text changes, which triggers the cross-fade animation.
                    key: ValueKey(isBreathingIn),
                    // Style the text.
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.indigo,
                      letterSpacing: 0.5, // Add a bit of space between letters.
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// A custom class that extends CustomPainter to draw our wobbly, irregular circle shapes on a canvas.
class _IrregularCirclePainter extends CustomPainter {
  // The color of the shape (fill or stroke).
  final Color color;
  // Whether to fill the shape with color (true) or just draw the outline (false).
  final bool isFilled;
  // The current rotation time factor used to offset the wobbles dynamically.
  final double time;

  // Constructor to pass the configuration for painting.
  _IrregularCirclePainter({
    required this.color,
    required this.isFilled,
    required this.time,
  });

  @override
  // The paint method is where the actual drawing on the screen happens.
  void paint(Canvas canvas, Size size) {
    // Setup a Paint object containing style settings (color, filled vs stroked, stroke width).
    final paint = Paint()
      ..color = color
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Find the center point of our drawing area.
    final center = Offset(size.width / 2, size.height / 2);
    // Determine the base radius (half the width).
    final baseRadius = size.width / 2;

    // Create a Path object to draw our custom shape point by point.
    final path = Path();
    // Number of points (or line segments) used to draw the circle. Higher = smoother.
    const int points = 180;

    // Loop through each point around the circle.
    for (int i = 0; i <= points; i++) {
      // t is a fraction going from 0.0 to 1.0 as we loop around.
      final t = i / points;
      // theta is the angle in radians (from 0 to 2*PI).
      final theta = t * 2 * math.pi;

      // Calculate the radius at this specific angle to make it irregular/wobbly.
      // We use sine and cosine waves mapped around the circumference.
      // The 'time' variable makes the wobbles shift dynamically, so it looks alive.
      final r = baseRadius +
          (baseRadius * 0.04) * math.sin(3 * theta + time * 2) + // 3 bumps, shifting fast
          (baseRadius * 0.03) * math.cos(5 * theta - time) +     // 5 bumps, shifting backwards
          (baseRadius * 0.02) * math.sin(7 * theta + time * 1.5);// 7 bumps, shifting medium speed

      // Convert polar coordinates (radius and angle) back into x,y pixel coordinates.
      final x = center.dx + r * math.cos(theta);
      final y = center.dy + r * math.sin(theta);

      // If it's the very first point, move the pen there without drawing a line.
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // For all other points, draw a line from the previous point to this new point.
        path.lineTo(x, y);
      }
    }
    // Connect the very last point back to the very first point to close the shape.
    path.close();
    // Actually draw the completed path on the canvas using our paint settings.
    canvas.drawPath(path, paint);
  }

  @override
  // Determines whether flutter needs to repaint this custom graphic.
  // It checks if any of our input properties have changed since the last frame.
  bool shouldRepaint(covariant _IrregularCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isFilled != isFilled ||
        oldDelegate.time != time;
  }
}
