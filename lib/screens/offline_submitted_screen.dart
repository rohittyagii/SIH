// Import the core Flutter material design library, which provides UI components like Scaffold, Container, Text, etc.
import 'package:flutter/material.dart';
// Import Riverpod, a state management library for Flutter, which allows us to use ConsumerWidget and WidgetRef.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import our custom color palette to keep the app's styling consistent.
import '../theme/colors.dart';
// Import seed data or dummy data, which likely contains the 'dims' and 'offlineScores' variables used later.
import '../data/seed.dart';
// Import custom icon widgets that we created for our app, such as IconCloudQueue and IconNoWifi.
import '../widgets/icon_widgets.dart';
// Import a custom card widget (RrCard) used to display content in a rounded, styled box.
import '../widgets/rr_card.dart';
// Import a custom widget (ScoreDots) that visually represents a score using small circles/dots.
import '../widgets/score_dots.dart';
// Import the translations system so we can translate text strings into different languages using the 'tr' function.
import '../data/translations.dart';
// Import a custom button widget (BouncyButton) that gives a physical bouncing effect when tapped.
import '../widgets/bouncy_button.dart';

// ── OfflineSubmittedScreen ────────────────────────────────────────────────────
// We define a new screen called OfflineSubmittedScreen.
// It extends ConsumerWidget so that it can listen to Riverpod providers (though here it mainly uses ref for translations).
class OfflineSubmittedScreen extends ConsumerWidget {
  // The constructor for our screen. It takes an optional 'key' (for Flutter's widget tree)
  // and an optional 'onDone' callback function that runs when the user taps "Back to home".
  const OfflineSubmittedScreen({super.key, this.onDone});
  
  // This variable holds the callback function. It's 'final' because it won't change after the widget is created.
  final VoidCallback? onDone;

  // We define a constant amber color used specifically in this screen to indicate the 'offline/pending' status.
  static const _amber = Color(0xFFC4A870);

  // The 'build' method is called by Flutter to draw the widget on the screen.
  // It receives the current 'context' (info about the widget's location in the tree)
  // and 'ref' (to access Riverpod providers).
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Scaffold provides the basic structural layout for a material design screen (background, app bar, etc.).
    return Scaffold(
      // Set the background color of the screen using an extension property (rrBg) defined on our context.
      backgroundColor: context.rrBg,
      // Stack allows us to place widgets on top of each other.
      body: Stack(
        children: [
          // Warm atmospheric wash
          // Positioned.fill makes this child stretch to fill the entire Stack (the whole screen).
          Positioned.fill(
            // Container is an empty box that we can style. Here we use it to draw a gradient background.
            child: Container(
              // BoxDecoration allows us to paint colors, gradients, and borders.
              decoration: const BoxDecoration(
                // We use a RadialGradient to create a glowing effect radiating from a specific point.
                gradient: RadialGradient(
                  // The center of the glow is placed towards the top of the screen (y: -1.5).
                  center: Alignment(0, -1.5),
                  // The radius controls how far the gradient spreads.
                  radius: 1.0,
                  // The gradient transitions from a very faint amber color to completely transparent.
                  colors: [Color(0x0EC4A870), Colors.transparent],
                ),
              ),
            ),
          ),
          // SafeArea ensures that the content is not hidden by the device's notches, status bars, or home indicators.
          SafeArea(
            // SingleChildScrollView allows the content to scroll vertically if it overflows the screen height.
            child: SingleChildScrollView(
              // We add padding around the scrollable content: 24 pixels on left and right, 36 on bottom.
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              // Column arranges its children vertically in a line.
              child: Column(
                children: [
                  // A fixed-height invisible box (SizedBox) used to create 56 pixels of empty space at the top.
                  const SizedBox(height: 56),
                  // Icon
                  // Another Stack is used here to overlay a small "badge" on top of the main icon.
                  Stack(
                    // Clip.none ensures that if a child is positioned outside the Stack's bounds, it won't be cut off.
                    clipBehavior: Clip.none,
                    children: [
                      // This Container holds the main cloud icon.
                      Container(
                        // We set a fixed width and height of 72 pixels.
                        width: 72,
                        height: 72,
                        // Styling the container with rounded corners, a background color, and a border.
                        decoration: BoxDecoration(
                          // Border radius of 20 makes the corners rounded.
                          borderRadius: BorderRadius.circular(20),
                          // The background color is a very transparent amber.
                          color: _amber.withValues(alpha: 0.07),
                          // A solid border around the container.
                          border: Border.all(
                              // The border color is a slightly more visible amber.
                              color: _amber.withValues(alpha: 0.24),
                              // The border has a thickness of 1.5 pixels.
                              width: 1.5),
                        ),
                        // Center aligns the cloud icon exactly in the middle of the container.
                        child: const Center(
                            // IconCloudQueue is our custom cloud icon widget.
                            child: IconCloudQueue(size: 30, color: _amber)),
                      ),
                      // Queue badge
                      // Positioned places the badge slightly outside the bottom-right corner of the icon container.
                      Positioned(
                        // Shift it 9 pixels below the bottom edge.
                        bottom: -9,
                        // Shift it 9 pixels to the right of the right edge.
                        right: -9,
                        // This Container draws the small badge background.
                        child: Container(
                          // Fixed width and height for a small square.
                          width: 22,
                          height: 22,
                          // Styling for the badge container.
                          decoration: BoxDecoration(
                            // Rounded corners for the badge.
                            borderRadius: BorderRadius.circular(8),
                            // The background color matches the screen's background color so it looks like a cutout.
                            color: context.rrBg,
                            // A border around the badge to make it stand out.
                            border: Border.all(
                                color: _amber.withValues(alpha: 0.28),
                                width: 1.5),
                          ),
                          // Center aligns the text inside the badge.
                          child: const Center(
                            // The text '···' represents a "waiting" or "pending" state.
                            child: Text('···',
                                // Text styling to make it look small, bold, and colored correctly.
                                style: TextStyle(
                                    color: _amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.04,
                                    height: 1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Space below the icon setup.
                  const SizedBox(height: 22),
                  // Main title text for the screen.
                  // We use the 'tr' function to translate the string based on the user's current language settings.
                  Text(tr('Saved on your device', ref),
                      // Styling for the title text.
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          // The text color comes from our custom theme context extension (rrT1 is likely a primary text color).
                          color: context.rrT1,
                          height: 1.25),
                      // Align the text centrally on the screen.
                      textAlign: TextAlign.center),
                  // Space below the main title.
                  const SizedBox(height: 10),
                  // The date and time of the save operation. (Hardcoded here, likely will be dynamic in a real app).
                  Text('Thu, 4 Sep 2026 · 14:32',
                      // Styling for the date text.
                      style: TextStyle(fontSize: 13, color: context.rrT4),
                      textAlign: TextAlign.center),
                  // Space below the date text.
                  const SizedBox(height: 14),
                  // A detailed description explaining why the data is saved locally instead of on the server.
                  Text(
                    tr("You're offline right now. This check-in is stored locally and will sync automatically when your connection is restored.", ref),
                    // Styling for the description text.
                    style: TextStyle(
                        fontSize: 14, color: context.rrT3, height: 1.65),
                    textAlign: TextAlign.center,
                  ),
                  // Space below the description text.
                  const SizedBox(height: 20),
                  // Offline chip
                  // A pill-shaped container holding an icon and some text to indicate the offline state visually.
                  Container(
                    // Padding inside the pill container (horizontal and vertical space around the content).
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    // Styling the pill container.
                    decoration: BoxDecoration(
                      // A very large border radius makes it completely rounded on the ends (pill shape).
                      borderRadius: BorderRadius.circular(999),
                      // A light amber background color.
                      color: _amber.withValues(alpha: 0.08),
                      // A solid amber border.
                      border: Border.all(color: _amber.withValues(alpha: 0.22)),
                    ),
                    // A Row places the icon and text horizontally side-by-side.
                    child: Row(
                      // MainAxisSize.min tells the row to only take up as much horizontal space as its children need.
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Custom icon showing no Wi-Fi.
                        const IconNoWifi(size: 11, color: _amber),
                        // Small horizontal space between the icon and the text.
                        const SizedBox(width: 7),
                        // Text inside the pill indicating the sync status.
                        Text(tr('Offline · Syncs when reconnected', ref),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _amber)),
                      ],
                    ),
                  ),
                  // Space below the offline chip.
                  const SizedBox(height: 24),
                  // Score summary
                  // A custom card widget that acts as a container with rounded corners and a background.
                  RrCard(
                    // Column to lay out the title and a list of dimension scores vertically.
                    child: Column(
                      // Aligns children to the left (start) of the column.
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The heading for the score summary section.
                        Text(tr('WHAT YOU LOGGED', ref),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: context.rrT6,
                                letterSpacing: 0.10)),
                        // Space below the heading.
                        const SizedBox(height: 14),
                        // Here we use the spread operator (...) to insert a list of widgets into this children array.
                        // We take the 'dims' list, convert it to a map to access indices, and loop over its entries.
                        ...dims.asMap().entries.map((e) {
                          // The index of the current item in the list.
                          final i = e.key;
                          // The actual dimension data object.
                          final d = e.value;
                          // The score associated with this dimension key, fetched from the dummy 'offlineScores' map.
                          final s = offlineScores[d.key]!;
                          // A helper function 'scoreColor' calculates the appropriate color for the score.
                          final col = scoreColor(s);
                          // For each dimension, we return a Column that might include a divider and a row with score details.
                          return Column(
                            children: [
                              // If this is not the first item (index > 0), we draw a Divider line above it.
                              if (i > 0) ...[
                                // Divider creates a horizontal line.
                                Divider(color: context.rrDv, height: 24)
                              ],
                              // Row lays out the icon, name, dots, and label horizontally.
                              Row(
                                children: [
                                  // Helper function 'dimIcon' creates the icon for this specific dimension key.
                                  dimIcon(d.key, size: 15, color: col),
                                  // Space after the icon.
                                  const SizedBox(width: 12),
                                  // Expanded ensures this text takes up any remaining space in the middle, pushing everything else to the sides.
                                  Expanded(
                                      // The label of the dimension, translated.
                                      child: Text(tr(d.label, ref),
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: context.rrT3))),
                                  // Custom widget that draws dots representing the numerical score.
                                  ScoreDots(score: s),
                                  // Space after the score dots.
                                  const SizedBox(width: 8),
                                  // A fixed-width box for the text label so they all align neatly on the right.
                                  SizedBox(
                                    width: 68,
                                    // A text label describing the score (e.g., "Good", "Bad"), translated.
                                    child: Text(tr(scoreLabel(s), ref),
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: col),
                                        // Align the text to the right.
                                        textAlign: TextAlign.right),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  // Space below the score summary card.
                  const SizedBox(height: 12),
                  // Reassurance note
                  // A container acting as a small alert/info box to reassure the user.
                  Container(
                    // Padding inside the box.
                    padding: const EdgeInsets.all(14),
                    // Styling for the box.
                    decoration: BoxDecoration(
                      // Rounded corners.
                      borderRadius: BorderRadius.circular(10),
                      // Background color (likely a subtle overlay color).
                      color: context.rrOv,
                      // A thin border around the box.
                      border: Border.all(color: context.rrDv),
                    ),
                    // The actual reassurance message.
                    child: Text(
                      tr('Nothing is lost. Your data is on this device and will appear in your trend as soon as the sync completes.', ref),
                      style: TextStyle(
                          fontSize: 12, color: context.rrT4, height: 1.65),
                    ),
                  ),
                  // Space below the reassurance note.
                  const SizedBox(height: 28),
                  // Back to home button
                  // BouncyButton provides an animation when the user presses down on it.
                  BouncyButton(
                    // Calls the onDone callback when tapped.
                    onTap: onDone,
                    // The button's visual body.
                    child: Container(
                      // Make the button span the entire available width.
                      width: double.infinity,
                      // Vertical padding to make the button tall enough to tap easily.
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      // Styling the button.
                      decoration: BoxDecoration(
                        // Rounded corners.
                        borderRadius: BorderRadius.circular(13),
                        // Indigo background color with high transparency.
                        color: AppColors.indigo.withValues(alpha: 0.09),
                      ),
                      // Center aligns the text inside the button container.
                      child: Center(
                        // The button text.
                        child: Text(tr('Back to home', ref),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.indigo)),
                      ),
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
}
