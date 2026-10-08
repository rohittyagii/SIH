// Import the core Flutter material design library, which provides UI widgets like Scaffold, Text, Column, etc.
import 'package:flutter/material.dart';
// Import Riverpod, which is a state management library used to read and update app data.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import the intl package to easily format dates and times (e.g., 'EEEE, d MMM yyyy').
import 'package:intl/intl.dart';
// Import custom color definitions specific to the app's theme.
import '../theme/colors.dart';
// Import seed data or models (like 'Dim', 'DimKey', and 'dims') used across the app.
import '../data/seed.dart';
// Import custom icon widgets (like 'dimIcon') used to display icons for different dimensions.
import '../widgets/icon_widgets.dart';
// Import a custom rounded card widget used as a container for UI elements.
import '../widgets/rr_card.dart';
// Import the scale picker widget, which allows users to select a score (e.g., 1 to 5).
import '../widgets/scale_picker.dart';
// Import translation helpers to support multiple languages using the 'tr()' function.
import '../data/translations.dart';
// Import a custom button widget that provides a bouncing animation when tapped.
import '../widgets/bouncy_button.dart';

// ── DimCard ──────────────────────────────────────────────────────────────────
// This is a private custom widget that displays a card for a single "dimension" (like Sleep, Mood, etc.).
// It uses ConsumerWidget from Riverpod so it can listen to state changes if needed.
class _DimCard extends ConsumerWidget {
  // Constructor requiring the dimension info, current score value, and a callback when the score changes.
  const _DimCard({required this.dim, required this.value, required this.onChanged});
  
  // The specific dimension this card represents (contains label, hint, and key).
  final Dim dim;
  // The current score value for this dimension (0 if not yet rated).
  final int value;
  // A callback function triggered when the user selects a new score.
  final ValueChanged<int> onChanged;

  // The build method is where the UI for this widget is constructed.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine the color for the icon and text based on the current score.
    // If a score is selected (value > 0), use the score's specific color, otherwise use a default inactive text color (rrT4).
    final col = value > 0 ? scoreColor(value) : context.rrT4;
    
    // Return a custom RrCard widget to give this section a card-like appearance with padding and rounded corners.
    return RrCard(
      // Use a Column to stack the header row and the scale picker vertically.
      child: Column(
        // Align children to the start (left edge) of the column.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A Row to display the icon, dimension details, and the score label horizontally.
          Row(
            // Align the top edges of the row's children.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add a tiny bit of padding above the icon to align it with the text visually.
              Padding(
                padding: const EdgeInsets.only(top: 2),
                // Display the custom icon for this dimension using its key and determined color.
                child: dimIcon(dim.key, size: 15, color: col),
              ),
              // Add a fixed width space between the icon and the text.
              const SizedBox(width: 10),
              // Use Expanded to allow the text column to take up all remaining horizontal space in the middle.
              Expanded(
                // A nested Column to stack the dimension label and hint text vertically.
                child: Column(
                  // Align text to the start (left edge).
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display the translated dimension label (e.g., "Physical Readiness").
                    Text(tr(dim.label, ref),
                      // Apply styling: size 15, medium font weight, primary text color, and adjusted line height.
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.rrT1, height: 1.2)),
                    // Add a tiny space between the label and the hint.
                    const SizedBox(height: 2),
                    // Display the translated dimension hint/description in a smaller, secondary text color.
                    Text(tr(dim.hint, ref), style: TextStyle(fontSize: 12, color: context.rrT3)),
                  ],
                ),
              ),
              // If a valid score is selected (value > 0), display the score label on the far right.
              if (value > 0)
                Padding(
                  // Align the score label with the top text.
                  padding: const EdgeInsets.only(top: 2),
                  // Display the translated label for the selected score (e.g., "Optimal").
                  child: Text(tr(scoreLabel(value), ref),
                    // Style the score text to match the score's color and make it medium weight.
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: col)),
                ),
            ],
          ),
          // Add a larger space between the header row and the interactive scale picker below it.
          const SizedBox(height: 16),
          // Display the scale picker widget, passing in the current value and the callback to update it.
          ScalePicker(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── CheckinScreen ────────────────────────────────────────────────────────────
// The main screen widget where the user performs their daily check-in.
// It is a ConsumerStatefulWidget, meaning it has mutable state (like text input) and can read Riverpod providers.
class CheckinScreen extends ConsumerStatefulWidget {
  // Constructor requiring various data and callback functions from the parent widget/screen.
  const CheckinScreen({
    super.key,
    required this.scores,         // A map containing the current scores for all dimensions.
    required this.note,           // The current text note entered by the user.
    required this.onScoreChanged, // Callback when any score is updated.
    required this.onNoteChanged,  // Callback when the note text changes.
    required this.onSubmit,       // Callback when the final submit button is pressed.
    required this.onBack,         // Callback when the back/home button is pressed.
  });
  
  // Define the types and names for all the required properties passed in.
  final Map<DimKey, int> scores;
  final String note;
  final void Function(DimKey, int) onScoreChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  // Create the mutable state object associated with this Stateful widget.
  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

// The State class that holds the mutable data and builds the UI for CheckinScreen.
class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  // A controller used to manage the text typed into the "Anything to add?" TextField.
  late final TextEditingController _noteCtrl;

  // The initState method is called once when the widget is inserted into the widget tree.
  @override
  void initState() {
    super.initState();
    // Initialize the text controller with the initial note value passed to the widget.
    _noteCtrl = TextEditingController(text: widget.note)
      // Add a listener to notify the parent whenever the text changes using the onNoteChanged callback.
      ..addListener(() => widget.onNoteChanged(_noteCtrl.text));
  }

  // The dispose method is called when this widget is permanently removed from the tree.
  @override
  void dispose() { 
    // Always dispose of controllers to prevent memory leaks!
    _noteCtrl.dispose(); 
    super.dispose(); 
  }

  // The build method constructs the visual layout of this screen.
  @override
  Widget build(BuildContext context) {
    // Count how many dimensions have been scored (value > 0).
    final filled   = dims.where((d) => widget.scores[d.key]! > 0).length;
    // Check if all 4 dimensions have been scored, which means the form is complete.
    final allDone  = filled == 4;
    // Calculate how many characters are left in the 200-character limit for the note.
    final remaining = 200 - widget.note.length;

    // Return a Scaffold, which provides a basic material design visual layout structure.
    return Scaffold(
      // Set the background color using the custom app theme (context.rrBg).
      backgroundColor: context.rrBg,
      // SafeArea ensures UI isn't hidden by device notches, status bars, or home indicators.
      body: SafeArea(
        // SingleChildScrollView allows the screen content to scroll vertically if it exceeds screen height.
        child: SingleChildScrollView(
          // Add padding around the edges of the scrolling content.
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          // Use a Column to stack the elements vertically from top to bottom.
          child: Column(
            // Align all children to the start (left side) of the screen.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button Section
              // BouncyButton gives a nice press-down animation when tapped.
              BouncyButton(
                // Trigger the onBack callback provided by the parent.
                onTap: widget.onBack,
                // Use a Row to place an icon and text side-by-side horizontally.
                child: Row(
                  // Ensure the row only takes up as much horizontal space as its children need.
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A small left-pointing chevron icon.
                    Icon(Icons.chevron_left, size: 16, color: context.rrT4),
                    // The translated "Home" text label for the back button.
                    Text(tr('Home', ref), style: TextStyle(fontSize: 13, color: context.rrT4)),
                  ],
                ),
              ),
              // Add vertical spacing below the back button.
              const SizedBox(height: 12),
              
              // Heading Section
              // Display the current date formatted nicely, like "Monday, 1 Jan 2023".
              Text(DateFormat('EEEE, d MMM yyyy').format(DateTime.now()), style: TextStyle(fontSize: 13, color: context.rrT4)),
              // Small gap between the date and the main title.
              const SizedBox(height: 4),
              // Main bold title for the screen.
              Text(tr('Daily readiness check-in', ref),
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: context.rrT1, height: 1.2)),
              // Small gap between the title and subtitle.
              const SizedBox(height: 6),
              // Subtitle explaining the purpose and privacy of the check-in.
              Text(tr('Private to you and your unit lead. Takes about a minute.', ref),
                style: TextStyle(fontSize: 13, color: context.rrT3)),
              // Add vertical spacing before the dimension cards start.
              const SizedBox(height: 12),
              
              // Dim cards Section (Dynamically generated)
              // Loop through the 'dims' list and map each one to a _DimCard widget.
              // The spread operator (...) unpacks this resulting list of widgets directly into the Column's children.
              ...dims.map((dim) => Padding(
                // Add spacing at the bottom of each card so they aren't touching.
                padding: const EdgeInsets.only(bottom: 12),
                // Display the individual card for a dimension.
                child: _DimCard(
                  dim: dim,
                  // Pass down the current score from the map, ensuring it exists with '!'.
                  value: widget.scores[dim.key]!,
                  // When the user changes a score, trigger the parent's onScoreChanged callback.
                  onChanged: (n) => widget.onScoreChanged(dim.key, n),
                ),
              )),
              
              // Optional note Section
              // Wrap the note input field inside a custom card widget for styling.
              RrCard(
                child: Column(
                  // Align text and input to the left.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // RichText allows mixing different text styles within a single paragraph.
                    RichText(text: TextSpan(
                      // Main label prompt.
                      text: tr('Anything to add? ', ref),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.rrT2),
                      children: [
                        // The word "(optional)" styled slightly differently (lighter font weight and color).
                        TextSpan(text: tr('(optional)', ref), style: TextStyle(fontWeight: FontWeight.w400, color: context.rrT4)),
                      ],
                    )),
                    // Gap between label and the text field.
                    const SizedBox(height: 12),
                    // TextField allows the user to type in text.
                    TextField(
                      // Attach the controller we created in initState to manage the text content.
                      controller: _noteCtrl,
                      // Allow up to 3 lines of text to be visible at once (making it a multi-line box).
                      maxLines: 3,
                      // Restrict the total characters typed to 200.
                      maxLength: 200,
                      // Styling and placeholder configuration for the text field.
                      decoration: InputDecoration(
                        // Placeholder text shown when the field is empty.
                        hintText: tr('Brief note for your record...', ref),
                        hintStyle: TextStyle(color: context.rrT6, fontSize: 14),
                        // Hide the built-in character counter (we build a custom one below).
                        counterText: '',
                        // Fill the background of the text field.
                        filled: true,
                        fillColor: context.rrIn,
                        // Default border styling when not focused.
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.rrIb),
                        ),
                        // Border styling when the user taps on it to type.
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.indigo.withValues(alpha: 0.35)),
                        ),
                        // Border styling when it is enabled but not focused.
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.rrIb),
                        ),
                        // Padding inside the text field around the typed text.
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      // Text styling for what the user actually types.
                      style: TextStyle(fontSize: 14, color: context.rrT1, height: 1.6),
                    ),
                    // Custom character limit counter: only show it when getting close to the limit (>160 chars).
                    if (widget.note.length > 160)
                      Align(
                        // Align the counter to the right side of the card.
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          // Display how many characters are remaining.
                          child: Text('$remaining remaining',
                            style: TextStyle(fontSize: 11, color: context.rrT4)),
                        ),
                      ),
                  ],
                ),
              ),
              // Gap before the submit button.
              const SizedBox(height: 12),
              
              // Submit Button Section
              // Another bouncy button for the final submission.
              BouncyButton(
                // Only allow tapping if all 4 dimensions are scored (allDone is true). Otherwise pass null to disable.
                onTap: allDone ? widget.onSubmit : null,
                // Use AnimatedContainer to smoothly transition colors/shadows when the button becomes enabled/disabled.
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  // Make the button stretch to full horizontal width.
                  width: double.infinity,
                  // Internal padding for the button to give it height.
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    // Rounded corners for the button.
                    borderRadius: BorderRadius.circular(14),
                    // If all complete, use full solid color. If not, make it faded/transparent.
                    color: allDone ? AppColors.indigo : AppColors.indigo.withValues(alpha: 0.14),
                    // Add a glowing drop shadow only when fully enabled.
                    boxShadow: allDone
                        ? [BoxShadow(color: AppColors.indigo.withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Center(
                    // Depending on if it's done, show either "Log today's readiness" or a progress tracker like "3 of 4 complete".
                    child: Text(
                      allDone ? tr("Log today's readiness", ref) : "$filled of 4 ${tr('complete', ref)}",
                      // Text style updates its color depending on whether the button is enabled or disabled.
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: allDone ? const Color(0xFF0C1220) : AppColors.indigo.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
              // Extra space at the very bottom so content isn't flush with the screen edge when scrolled.
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
