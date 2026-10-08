// Import the core Flutter material library, which provides UI widgets and themes.
import 'package:flutter/material.dart';
// Import the Riverpod package, which is used for state management in the app.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import custom color definitions used throughout the app.
import '../theme/colors.dart';
// Import initial data structures like dimensions (dims) and their keys (DimKey).
import '../data/seed.dart';
// Import custom icon widgets that we use instead of standard Flutter icons.
import '../widgets/icon_widgets.dart';
// Import a custom card widget used to wrap content with specific styling.
import '../widgets/rr_card.dart';
// Import a widget that displays a score as a series of dots.
import '../widgets/score_dots.dart';
// Import providers for application state, like the user's current streak.
import '../providers/app_state.dart';
// Import translation functions to handle multiple languages.
import '../data/translations.dart';
// Import a custom button that has a bouncy animation when pressed.
import '../widgets/bouncy_button.dart';

// ── SubmittedScreen ───────────────────────────────────────────────────────────
// This screen is shown after the user successfully submits their daily readiness scores.
// It extends ConsumerWidget so that it can listen to Riverpod providers (like the streak counter).
class SubmittedScreen extends ConsumerWidget {
  // The constructor requires a 'key', 'scores', 'note', and an 'onDone' callback.
  const SubmittedScreen({
    super.key, // Passes the key to the parent class (ConsumerWidget).
    required this.scores, // The map of dimension keys to their submitted scores.
    required this.note, // The optional note the user added to their submission.
    required this.onDone, // The function to call when the user wants to leave this screen.
  });

  // A map that holds the score (1 to 5) for each dimension (e.g., sleep, mood).
  final Map<DimKey, int> scores;
  // A string holding the note the user typed in (can be empty).
  final String note;
  // A callback function that gets triggered when the "Back to home" button is pressed.
  final VoidCallback onDone;

  // The build method describes the UI of this widget. It is called whenever the widget needs to be drawn.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Scaffold provides the basic visual layout structure for a screen (like background color).
    return Scaffold(
      // Set the background color of the screen using an extension property (rrBg) on the context.
      backgroundColor: context.rrBg,
      // SafeArea ensures that the content doesn't overlap with system UI like the notch or status bar.
      body: SafeArea(
        // SingleChildScrollView allows the content to be scrolled if it exceeds the screen height.
        child: SingleChildScrollView(
          // Apply padding around the entire scrollable content (left, top, right, bottom).
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          // Column arranges its children vertically from top to bottom.
          child: Column(
            children: [
              // Success icon section
              // Container is a versatile widget used to draw a box with specific dimensions and styling.
              Container(
                // Set the width of the container to 80 logical pixels.
                width: 80, 
                // Set the height of the container to 80 logical pixels.
                height: 80,
                // BoxDecoration defines how the container is drawn (shape, color, borders, shadows).
                decoration: BoxDecoration(
                  // Make the container a perfect circle.
                  shape: BoxShape.circle,
                  // Set the background color to a semi-transparent version of the "score5" color.
                  color: AppColors.score5.withValues(alpha: 0.10),
                  // Add a border around the circle using a slightly more opaque version of the color.
                  border: Border.all(color: AppColors.score5.withValues(alpha: 0.28), width: 1.5),
                  // Add a glowing drop shadow effect behind the circle.
                  boxShadow: [BoxShadow(color: AppColors.score5.withValues(alpha: 0.12), blurRadius: 48)],
                ),
                // Center aligns its child (the check icon) exactly in the middle of the container.
                // Display a custom checkmark icon, colored to match the success theme.
                child: const Center(child: IconCheck(size: 30, color: AppColors.score5)),
              ),
              // Add a vertical space of 28 pixels below the icon.
              const SizedBox(height: 28),
              // Display the main success text, translating 'Readiness logged' based on the current locale.
              Text(tr('Readiness logged', ref),
                // Style the text to be large (22), semi-bold, and using the primary text color (rrT1).
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: context.rrT1),
                // Center-align the text horizontally.
                textAlign: TextAlign.center),
              // Add a small vertical space of 6 pixels.
              const SizedBox(height: 6),
              // Display a secondary text showing the date and a friendly message.
              // Note: The date is currently hardcoded here.
              Text('Thursday, 4 Sep 2026 · See you tomorrow',
                // Style the text to be smaller (14), use a tertiary text color (rrT3), and add line height.
                style: TextStyle(fontSize: 14, color: context.rrT3, height: 1.6),
                // Center-align the text horizontally.
                textAlign: TextAlign.center),
              // Add a larger vertical space of 32 pixels before the scores summary.
              const SizedBox(height: 32),
              // Scores summary section
              // RrCard is a custom widget that provides a card-like appearance (rounded corners, background).
              RrCard(
                // The card contains a column to layout the individual scores vertically.
                child: Column(
                  children: [
                    // We use the spread operator (...) to insert a list of widgets generated from the 'dims' list.
                    // .asMap().entries gives us access to both the index (e.key) and the dimension object (e.value).
                    ...dims.asMap().entries.map((e) {
                      // Extract the index of the current dimension in the list.
                      final i = e.key;
                      // Extract the actual dimension object (contains key, label, etc.).
                      final d = e.value;
                      // Retrieve the specific score (1-5) for this dimension from the 'scores' map.
                      // The '!' assumes the score is guaranteed to be present in the map.
                      final s = scores[d.key]!;
                      // Determine the appropriate color for this score using the scoreColor helper function.
                      final col = scoreColor(s);
                      // Return a Column for each dimension to allow adding spacing between them.
                      return Column(
                        children: [
                          // If this is not the first item, add a 16-pixel gap above it.
                          if (i > 0) const SizedBox(height: 16),
                          // Row arranges its children horizontally.
                          Row(
                            children: [
                              // Display the specific icon for this dimension, colored based on the score.
                              dimIcon(d.key, size: 15, color: col),
                              // Add a horizontal space of 12 pixels next to the icon.
                              const SizedBox(width: 12),
                              // Expanded makes the Text widget take up all remaining horizontal space.
                              // Display the translated label for the dimension (e.g., 'Sleep').
                              Expanded(child: Text(tr(d.label, ref), style: TextStyle(fontSize: 13, color: context.rrT3))),
                              // Display the visual representation of the score using the ScoreDots widget.
                              ScoreDots(score: s),
                              // Add a horizontal space of 8 pixels next to the dots.
                              const SizedBox(width: 8),
                              // Use a SizedBox with fixed width to ensure the text alignment is consistent across all rows.
                              SizedBox(
                                // Set a fixed width of 72 pixels for the label area.
                                width: 72,
                                // Display the translated text label corresponding to the score (e.g., 'Excellent').
                                child: Text(tr(scoreLabel(s), ref),
                                  // Style it to be small (12), medium weight, and colored to match the score.
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: col),
                                  // Right-align the text within its fixed-width box.
                                  textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                    // Conditionally add the note section if the user provided one.
                    // isNotEmpty checks if the string has at least one character.
                    if (note.isNotEmpty) ...[
                      // Add a horizontal line (Divider) to separate the scores from the note.
                      Divider(color: context.rrDv2, height: 32),
                      // Align positions its child within itself. Here, it aligns it to the center-left.
                      Align(
                        alignment: Alignment.centerLeft,
                        // Use a column to stack the "Note" title and the actual note text.
                        child: Column(
                          // Align the children of this column to the start (left side).
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display the word 'Note' translated into the current language.
                            Text(tr('Note', ref), style: TextStyle(fontSize: 11, color: context.rrT6)),
                            // Add a tiny vertical gap of 4 pixels.
                            const SizedBox(height: 4),
                            // Display the actual note text written by the user.
                            Text(note, style: TextStyle(fontSize: 13, color: context.rrT2b, height: 1.6)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Add a vertical space of 20 pixels below the card.
              const SizedBox(height: 20),
              // Streak chip section
              // A decorative container to highlight the user's current streak.
              Container(
                // Add inner padding: 16 pixels left/right, 10 pixels top/bottom.
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                // Define the background, border, and rounded corners of the chip.
                decoration: BoxDecoration(
                  // Make the corners fully rounded (pill shape).
                  borderRadius: BorderRadius.circular(999),
                  // Set background color to a very transparent indigo.
                  color: AppColors.indigo.withValues(alpha: 0.09),
                  // Add a subtle border using a slightly more opaque indigo.
                  border: Border.all(color: AppColors.indigo.withValues(alpha: 0.20)),
                ),
                // Row arranges the flame icon and the text horizontally.
                child: Row(
                  // Tell the row to only take up as much horizontal space as its children need.
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Display a custom flame icon to represent a streak.
                    const IconFlame(size: 13, color: AppColors.indigo),
                    // Add an 8-pixel gap between the icon and the text.
                    const SizedBox(width: 8),
                    // Display the streak text. 
                    // ref.watch(streakProvider) reads the current streak value from the state manager.
                    // Whenever the streak changes, this widget will automatically rebuild.
                    Text('${ref.watch(streakProvider)}-day streak — well done',
                      // Style the text with font size 13, medium weight, and indigo color.
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.indigo)),
                  ],
                ),
              ),
              // Add a vertical space of 32 pixels before the button.
              const SizedBox(height: 32),
              // Back to home button
              // BouncyButton provides a scaling animation when tapped.
              BouncyButton(
                // Trigger the onDone callback that was passed into the screen when tapped.
                onTap: onDone,
                // Display the translated text 'Back to home' inside the button.
                child: Text(tr('Back to home', ref),
                  // Style it with font size 14, medium weight, and indigo color.
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.indigo)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
