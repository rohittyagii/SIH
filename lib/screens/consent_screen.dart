// Import the core Flutter material library, which provides UI widgets like Scaffold, Text, Container, etc.
import 'package:flutter/material.dart';
// Import the flutter_riverpod library, which is used for state management in the app.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import the custom color definitions for the app's theme.
import '../theme/colors.dart';
// Import the data definitions, likely where 'Assurance' and 'assurances' list are defined.
import '../data/seed.dart';
// Import custom icon widgets used throughout the app.
import '../widgets/icon_widgets.dart';
// Import a custom card widget used to wrap the assurance items.
import '../widgets/rr_card.dart';
// Import the translations file to support internationalization and dynamic text generation.
import '../data/translations.dart';
// Import a custom button widget that provides a bouncy animation when tapped.
import '../widgets/bouncy_button.dart';

// ── ConsentScreen ────────────────────────────────────────────────────────────
// Define the ConsentScreen class as a ConsumerStatefulWidget so it can interact with Riverpod state and maintain its own state.
class ConsentScreen extends ConsumerStatefulWidget {
  // The constructor takes an optional key and a required callback function 'onAgree' which is called when the user agrees.
  const ConsentScreen({super.key, required this.onAgree});
  
  // Declare the final callback function variable.
  final VoidCallback onAgree;

  // Override the createState method to return the mutable state for this widget.
  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

// Define the state class for ConsentScreen.
class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  // A boolean state variable to track if the "Learn more" details section is expanded or collapsed.
  bool _expanded = false;

  // A helper method that returns a specific icon widget based on the color property of the Assurance object.
  Widget _assuranceIcon(Assurance a) {
    // If the color matches the app's primary indigo color, return a lock icon.
    if (a.color == AppColors.indigo) return IconLock(size: 16, color: a.color);
    
    // If the color is a specific light blue (0xFF56B4E9), return an eye-off icon.
    if (a.color == const Color(0xFF56B4E9)) {
      return IconEyeOff(size: 16, color: a.color);
    }
    
    // For any other color, return a circle check icon.
    return IconCircleCheck(size: 16, color: a.color);
  }

  // The build method is called every time the widget needs to be drawn on the screen.
  @override
  Widget build(BuildContext context) {
    // Return a Scaffold widget, which provides the basic visual layout structure for a screen.
    return Scaffold(
      // Set the background color of the scaffold using an extension property on the context (likely from the theme).
      backgroundColor: context.rrBg,
      // SafeArea ensures that the content avoids system intrusions like the notch, status bar, and home indicator.
      body: SafeArea(
        // SingleChildScrollView allows the child content to be scrollable if it exceeds the screen height.
        child: SingleChildScrollView(
          // Add padding around the scrollable content: 24 pixels on left/right, 0 on top, 32 on bottom.
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          // Column lays out its children vertically.
          child: Column(
            // Align all children to the start (left edge) of the column.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shield icon section
              // Center widget horizontally aligns its child in the middle of the available space.
              Center(
                // Add padding around the container to space it out from surrounding elements.
                child: Padding(
                  padding: const EdgeInsets.only(top: 64, bottom: 36),
                  // Container creates a box that can be styled and dimensioned.
                  child: Container(
                    // Set fixed width for the container.
                    width: 68,
                    // Set fixed height for the container.
                    height: 68,
                    // BoxDecoration allows us to apply styles like color, borders, radius, and shadows.
                    decoration: BoxDecoration(
                      // Round the corners of the container with an 18-pixel radius.
                      borderRadius: BorderRadius.circular(18),
                      // Set the background color to indigo with 10% opacity.
                      color: AppColors.indigo.withValues(alpha: 0.10),
                      // Add a border around the container in indigo with 24% opacity.
                      border: Border.all(
                          color: AppColors.indigo.withValues(alpha: 0.24)),
                      // Add a list of box shadows to create a glowing or depth effect.
                      boxShadow: [
                        BoxShadow(
                            // Shadow color is indigo with 10% opacity.
                            color: AppColors.indigo.withValues(alpha: 0.10),
                            // Blur radius determines how spread out and soft the shadow is.
                            blurRadius: 48)
                      ],
                    ),
                    // Place the shield icon exactly in the center of the container.
                    child: const Center(
                        child: IconShield(size: 30, color: AppColors.indigo)),
                  ),
                ),
              ),
              
              // Heading section
              // Text widget to display a small, styled label, translated using 'tr' and the current ref.
              Text(tr('READINESS', ref),
                  style: TextStyle(
                      // Set the font size to 10 pixels.
                      fontSize: 10,
                      // Set the font weight to medium (w500).
                      fontWeight: FontWeight.w500,
                      // Set the text color using the context's theme extension property.
                      color: context.rrT6,
                      // Add letter spacing to make the text look more airy.
                      letterSpacing: 0.10)),
              // SizedBox adds a vertical empty space of 10 pixels.
              const SizedBox(height: 10),
              
              // RichText allows for a paragraph with mixed text styles.
              RichText(
                  // TextSpan defines a chunk of text. This is the first part.
                  text: TextSpan(
                // The main translated text chunk.
                text: tr('Your check-ins,\n', ref),
                style: TextStyle(
                    // Set a large font size for the main heading.
                    fontSize: 27,
                    // Set a bold font weight.
                    fontWeight: FontWeight.w600,
                    // Set the text color.
                    color: context.rrT1,
                    // Set the line height.
                    height: 1.25),
                // children allow us to append more TextSpans that inherit the parent's style unless overridden.
                children: [TextSpan(text: tr('your call', ref))],
              )),
              // Add vertical spacing of 14 pixels.
              const SizedBox(height: 14),
              
              // A Text widget explaining the tool's purpose to the user.
              Text(
                  tr('This is a personal readiness tool — not an assessment, and not a record that goes anywhere else. You decide what you log, and you stay in control of it.', ref),
                  style: TextStyle(
                      // Set font size to 14.
                      fontSize: 14, 
                      // Set a subtle text color.
                      color: context.rrT3, 
                      // Set line height for readability.
                      height: 1.65)),
              // Add a larger vertical gap of 28 pixels.
              const SizedBox(height: 28),
              
              // Assurances card section
              // RrCard is a custom widget to create a styled card container.
              RrCard(
                // Column to list out the different assurances vertically inside the card.
                child: Column(
                  // Map over the 'assurances' list from the data layer, turning each item into a Widget.
                  // asMap().entries provides access to both the index and the item during iteration.
                  children: assurances.asMap().entries.map((e) {
                    // Extract the index of the current item.
                    final i = e.key;
                    // Extract the actual Assurance object.
                    final a = e.value;
                    // Return a Column for each assurance item to allow for a divider and the item itself.
                    return Column(
                      children: [
                        // If it's not the first item, insert a Divider above it.
                        if (i > 0) ...[
                          // Divider draws a horizontal line to separate items.
                          Divider(color: context.rrDv, height: 32),
                        ],
                        // Row lays out the icon and text horizontally.
                        Row(
                          // Align items to the start (top) of the row.
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Container to hold the assurance icon with a colored background.
                            Container(
                              // Fixed width for the icon container.
                              width: 36,
                              // Fixed height for the icon container.
                              height: 36,
                              // Style the background of the icon.
                              decoration: BoxDecoration(
                                // Round the corners slightly.
                                borderRadius: BorderRadius.circular(10),
                                // Set the background color to match the item's color, but highly transparent (11%).
                                color: a.color.withValues(alpha: 0.11),
                              ),
                              // Use the helper method to render the correct icon inside the container.
                              child: Center(child: _assuranceIcon(a)),
                            ),
                            // Horizontal gap of 14 pixels between the icon and text.
                            const SizedBox(width: 14),
                            // Expanded ensures the text column takes up all remaining horizontal space.
                            Expanded(
                              // Column to hold the title and body of the assurance vertically.
                              child: Column(
                                // Align text to the left.
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // The title text for the assurance.
                                  Text(tr(a.title, ref),
                                      style: TextStyle(
                                          // Font size 14 for the title.
                                          fontSize: 14,
                                          // Medium font weight.
                                          fontWeight: FontWeight.w500,
                                          // Darker text color.
                                          color: context.rrT2,
                                          // Tighter line height for headers.
                                          height: 1.2)),
                                  // Small vertical gap between title and body.
                                  const SizedBox(height: 4),
                                  // The body text for the assurance.
                                  Text(tr(a.body, ref),
                                      style: TextStyle(
                                          // Smaller font size for body.
                                          fontSize: 13,
                                          // Lighter text color.
                                          color: context.rrT3,
                                          // Relaxed line height for readability.
                                          height: 1.6)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }).toList(), // Convert the mapped iterable back to a list of Widgets.
                ),
              ),
              
              // Expandable details section
              // This part of the UI is conditionally rendered only if the '_expanded' state is true.
              if (_expanded) ...[
                // Vertical gap before the details container.
                const SizedBox(height: 16),
                // Container to hold the expanded details.
                Container(
                  // Inner padding for the details container.
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // Rounded corners for the details container.
                    borderRadius: BorderRadius.circular(12),
                    // Background color for the details box.
                    color: context.rrOv,
                    // Border color for the details box.
                    border: Border.all(color: context.rrDv2),
                  ),
                  // Column to hold the header and the list of items vertically.
                  child: Column(
                    // Align items to the start (left).
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header text for the expanded details section.
                      Text(tr('A few more details', ref),
                          style: TextStyle(
                              // Small font size.
                              fontSize: 12,
                              // Medium font weight.
                              fontWeight: FontWeight.w500,
                              // Section text color.
                              color: context.rrT6,
                              // Slight letter spacing.
                              letterSpacing: 0.06)),
                      // Vertical space below the header.
                      const SizedBox(height: 12),
                      
                      // Map over the 'learnMoreItems' list from the data layer.
                      // The spread operator (...) unwraps the resulting list of Widgets into the column's children.
                      ...learnMoreItems.map((item) => Padding(
                            // Add bottom padding for spacing between list items.
                            padding: const EdgeInsets.only(bottom: 10),
                            // Row for the bullet point and text.
                            child: Row(
                              // Align bullet and text to the top.
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // The bullet point graphic.
                                Container(
                                  // Width of the bullet point.
                                  width: 4,
                                  // Height of the bullet point.
                                  height: 4,
                                  // Margins to align the bullet vertically with the text and space it horizontally.
                                  margin:
                                      const EdgeInsets.only(top: 7, right: 10),
                                  // Style the bullet to be circular and colored.
                                  decoration: BoxDecoration(
                                      // Shape it as a circle.
                                      shape: BoxShape.circle,
                                      // Bullet color.
                                      color: context.rrT6),
                                ),
                                // Expanded ensures the text wraps and takes remaining horizontal space.
                                Expanded(
                                    // The translated text for the list item.
                                    child: Text(tr(item, ref),
                                        style: TextStyle(
                                            // Font size for details text.
                                            fontSize: 13,
                                            // Text color for details.
                                            color: context.rrT3,
                                            // Line height for readability.
                                            height: 1.6))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              
              // Large gap before the buttons at the bottom.
              const SizedBox(height: 32),
              
              // Agree button section
              // Custom bouncy button that animates when tapped.
              BouncyButton(
                // The callback function passed to this screen from its parent is triggered on tap.
                onTap: widget.onAgree,
                // The visual representation of the button.
                child: Container(
                  // Make the button take up the full available width.
                  width: double.infinity,
                  // Vertical padding inside the button.
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    // Round the button's corners.
                    borderRadius: BorderRadius.circular(14),
                    // Set the button's background color to indigo.
                    color: AppColors.indigo,
                    // Add a shadow below the button to make it pop.
                    boxShadow: [
                      BoxShadow(
                          // Shadow color based on indigo.
                          color: AppColors.indigo.withValues(alpha: 0.28),
                          // Spread of the shadow.
                          blurRadius: 28,
                          // Offset the shadow slightly downwards by 4 pixels.
                          offset: const Offset(0, 4))
                    ],
                  ),
                  // Center the text inside the button.
                  child: Center(
                    // The text inside the button.
                    child: Text(tr('I agree, continue', ref),
                        style: const TextStyle(
                            // Font size.
                            fontSize: 15,
                            // Bold font weight.
                            fontWeight: FontWeight.w600,
                            // Very dark, almost black color for the text on the indigo background.
                            color: Color(0xFF0C1220))),
                  ),
                ),
              ),
              
              // Small vertical space between the main button and the toggle button.
              const SizedBox(height: 16),
              
              // Toggle button to show/hide the details section.
              Center(
                // Another bouncy button for the toggle action.
                child: BouncyButton(
                  // On tap, update the state to flip the boolean value of '_expanded'.
                  // setState tells Flutter to rebuild the widget tree with the new state.
                  onTap: () => setState(() => _expanded = !_expanded),
                  // The text displayed changes depending on whether the section is currently expanded or not.
                  child: Text(
                    // If expanded, show "Show less", otherwise show "Learn more...".
                    _expanded ? tr('Show less', ref) : tr('Learn more about data handling', ref),
                    style: TextStyle(fontSize: 14, color: context.rrT3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
