// Import the core Flutter material design library, which provides UI components like Widgets, Colors, and Icons.
import 'package:flutter/material.dart';
// Import custom color definitions for the application's theme.
import '../theme/colors.dart';
// Import seed data or utility functions (such as scoreColor) used across the app.
import '../data/seed.dart';

// ── ScalePicker ─────────────────────────────────────────────────────────────
// Define a Stateful Widget named ScalePicker. A StatefulWidget is used because the 
// internal state of this widget (like the drag position) can change over time.
class ScalePicker extends StatefulWidget {
  // The constructor for ScalePicker. It requires a starting 'value' and an 
  // 'onChanged' callback to notify the parent widget when the value updates.
  // 'super.key' is used to uniquely identify this widget in the widget tree.
  const ScalePicker({super.key, required this.value, required this.onChanged});
  
  // The current selected value on the scale (typically 1 to 5).
  final int value;
  // A function that gets called whenever the user selects a new value on the scale.
  final ValueChanged<int> onChanged;

  // This method creates the mutable state for this widget, which is managed 
  // by the _ScalePickerState class defined below.
  @override
  State<ScalePicker> createState() => _ScalePickerState();
}

// The State class for ScalePicker. This holds the mutable data that can change 
// during the lifetime of the widget.
class _ScalePickerState extends State<ScalePicker> {
  // A variable to keep track of the current horizontal position (X-coordinate) 
  // of the user's finger while dragging. It is nullable (double?) because it 
  // is null when the user is not dragging.
  double? _dragX; 
  // A boolean flag to indicate whether the user is currently dragging the thumb.
  bool _isDragging = false;

  // Called when the user starts a horizontal drag gesture on the picker.
  // 'details' gives information about the touch, and 'maxWidth' is the total width of the picker.
  void _handlePanStart(DragStartDetails details, double maxWidth) {
    // setState tells Flutter to rebuild the widget with the updated state variables.
    setState(() {
      // Set the dragging flag to true.
      _isDragging = true;
      // Record the starting X position of the drag, making sure it stays between 0 and maxWidth.
      _dragX = details.localPosition.dx.clamp(0.0, maxWidth);
    });
    // Update the selected value based on the new drag position.
    _updateValue(maxWidth);
  }

  // Called continuously as the user moves their finger horizontally during a drag.
  void _handlePanUpdate(DragUpdateDetails details, double maxWidth) {
    // Update the state with the new X position of the drag.
    setState(() {
      // Constrain the X position so it doesn't go outside the bounds of the widget.
      _dragX = details.localPosition.dx.clamp(0.0, maxWidth);
    });
    // Calculate and update the selected value based on this new position.
    _updateValue(maxWidth);
  }

  // Called when the user lifts their finger, ending the drag gesture.
  void _handlePanEnd(DragEndDetails details) {
    // Update the state to reflect that the drag has finished.
    setState(() {
      // Set the dragging flag back to false.
      _isDragging = false;
      // Reset the drag position to null since dragging has stopped.
      _dragX = null;
    });
  }

  // Called when the user simply taps on the picker instead of dragging.
  void _handleTapDown(TapDownDetails details, double maxWidth) {
    // Update the state with the X position of the tap.
    setState(() {
      // Ensure the tapped position is within the bounds (0 to maxWidth).
      _dragX = details.localPosition.dx.clamp(0.0, maxWidth);
    });
    // Update the selected value based on where the tap occurred.
    _updateValue(maxWidth);
    // Immediately reset the drag position to null since it was just a quick tap.
    setState(() {
      _dragX = null;
    });
  }

  // A helper function to calculate the new scale value (1 to 5) based on the current drag/tap position.
  void _updateValue(double maxWidth) {
    // If there is no current drag position, do nothing.
    if (_dragX == null) return;
    
    // Divide the total width into 5 equal segments (since the scale goes from 1 to 5).
    final segment = maxWidth / 5;
    
    // Calculate the new value by seeing which segment the drag position falls into.
    // We use .floor() to round down to the nearest whole number and add 1 (to make it 1-indexed).
    int newValue = (_dragX! / segment).floor() + 1;
    
    // Ensure the new value does not exceed the maximum possible value of 5.
    if (newValue > 5) newValue = 5;
    // Ensure the new value does not go below the minimum possible value of 1.
    if (newValue < 1) newValue = 1;
    
    // Only notify the parent widget if the value actually changed.
    if (newValue != widget.value) {
      // Call the onChanged callback provided by the parent widget.
      widget.onChanged(newValue);
    }
  }

  // A helper function that returns a specific icon based on the numerical value (1 to 5).
  IconData _getIconForValue(int v) {
    // Use a switch statement to check the value of 'v'.
    switch (v) {
      case 1:
        // Return a very sad face icon for the lowest score (1).
        return Icons.sentiment_very_dissatisfied_rounded;
      case 2:
        // Return a slightly sad face icon for a score of 2.
        return Icons.sentiment_dissatisfied_rounded;
      case 3:
        // Return a neutral face icon for a middle score of 3.
        return Icons.sentiment_neutral_rounded;
      case 4:
        // Return a happy face icon for a score of 4.
        return Icons.sentiment_satisfied_rounded;
      case 5:
        // Return a very happy face icon for the highest score (5).
        return Icons.sentiment_very_satisfied_rounded;
      default:
        // If the value doesn't match any case, return a neutral face as a fallback.
        return Icons.sentiment_neutral_rounded;
    }
  }

  // The build method is called every time Flutter needs to render this widget on the screen.
  @override
  Widget build(BuildContext context) {
    // Return a Column widget to arrange its children vertically.
    return Column(
      children: [
        // LayoutBuilder gives us access to the 'constraints', which tell us how much space is available.
        LayoutBuilder(
          builder: (context, constraints) {
            // Define the constant height for the background track.
            const trackHeight = 44.0;
            // Define the constant size (width and height) for the movable thumb.
            const thumbSize = 56.0;
            // Get the maximum available width for this widget from the constraints.
            final maxWidth = constraints.maxWidth;
            // Calculate the width of one single segment (total width divided by 5).
            final segment = maxWidth / 5;

            // Variable to store the final X-coordinate position of the thumb.
            double thumbX;
            // If the user is currently dragging and we have a valid drag X position...
            if (_isDragging && _dragX != null) {
              // Position the center of the thumb exactly where the user is dragging.
              // Subtract half the thumbSize so the thumb is centered on the finger.
              thumbX = _dragX! - (thumbSize / 2);
            } 
            // If not dragging, but a valid value (greater than 0) is set...
            else if (widget.value > 0) {
              // Calculate the position based on the selected value.
              // Find the start of the correct segment, add half a segment to center it, 
              // and subtract half the thumb size to align the thumb itself.
              thumbX = (widget.value - 1) * segment +
                  (segment / 2) -
                  (thumbSize / 2);
            } 
            // If there's no valid value (e.g., initial state)...
            else {
              // Default the thumb to the center position (segment index 2, which is the 3rd segment).
              thumbX = (2) * segment +
                  (segment / 2) -
                  (thumbSize / 2); // Default to center if no value
            }

            // Ensure the thumb doesn't go off the left (0.0) or right edge (maxWidth - thumbSize) of the widget.
            thumbX = thumbX.clamp(0.0, maxWidth - thumbSize);

            // Determine the color of the thumb. 
            // If a valid value is selected, use a custom color function based on the value.
            // Otherwise, fallback to a theme color (context.rrT4).
            final col =
                widget.value > 0 ? scoreColor(widget.value) : context.rrT4;
                
            // Determine which icon should be displayed on the active thumb.
            // Default to value 3 (neutral) if no specific value is set.
            final activeIcon =
                _getIconForValue(widget.value > 0 ? widget.value : 3);

            // GestureDetector allows the widget to respond to touch events (taps and drags).
            return GestureDetector(
              // Triggered when the user starts dragging horizontally.
              onHorizontalDragStart: (d) => _handlePanStart(d, maxWidth),
              // Triggered continuously while the user drags horizontally.
              onHorizontalDragUpdate: (d) => _handlePanUpdate(d, maxWidth),
              // Triggered when the user stops dragging.
              onHorizontalDragEnd: _handlePanEnd,
              // Triggered when the user taps anywhere on the widget.
              onTapDown: (d) => _handleTapDown(d, maxWidth),
              // The main container for the picker graphics.
              child: SizedBox(
                // The total height needs to accommodate the larger thumb size.
                height: thumbSize,
                // Stack allows us to overlay widgets on top of each other (e.g., thumb over the track).
                child: Stack(
                  // Center the children vertically within the Stack.
                  alignment: Alignment.center,
                  children: [
                    // --- 1. The Track Background ---
                    Container(
                      // Set the height of the track.
                      height: trackHeight,
                      // Style the track with colors, borders, and shadows.
                      decoration: BoxDecoration(
                        // The background color of the track.
                        color: context.rrBgn,
                        // Make the edges of the track perfectly rounded.
                        borderRadius: BorderRadius.circular(trackHeight / 2),
                        // Add a subtle border around the track.
                        border: Border.all(color: context.rrDv2, width: 1),
                        // Add a very soft shadow underneath the track to give it depth.
                        boxShadow: [
                          BoxShadow(
                            color: context.rrCsh.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                    
                    // --- 2. Track Icons and Separators ---
                    // This row contains the inactive background icons spread evenly across the track.
                    SizedBox(
                      // Restrict the height to the track height.
                      height: trackHeight,
                      // A Row widget displays its children horizontally side-by-side.
                      child: Row(
                        // Generate exactly 5 children dynamically, one for each scale value.
                        children: List.generate(5, (i) {
                          // 'i' goes from 0 to 4. 'n' is the actual 1-to-5 value.
                          final n = i + 1;
                          // Expanded makes each segment take up exactly 1/5th of the available width.
                          return Expanded(
                            // Stack allows us to place a separator line and an icon in the same area.
                            child: Stack(
                              // Center the icon within its segment.
                              alignment: Alignment.center,
                              children: [
                                // If this is not the first segment, draw a vertical separator line on its left side.
                                if (i > 0)
                                  Positioned(
                                    // Align the line exactly to the left edge of this segment.
                                    left: 0,
                                    child: Container(
                                        width: 1, // 1 pixel wide
                                        height: 16, // 16 pixels tall
                                        color: context.rrDv2), // Color of the separator line
                                  ),
                                // Display the corresponding inactive icon for this segment.
                                Icon(
                                  // Get the specific face icon for value 'n'.
                                  _getIconForValue(n),
                                  // Make the icon semi-transparent (alpha 0.3) so it looks inactive.
                                  color: context.rrT4.withValues(alpha: 0.3),
                                  // Set the size of the background icon.
                                  size: 28,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    
                    // --- 3. The Animated Thumb ---
                    // Only show the moving thumb if a value is selected or the user is actively dragging it.
                    if (widget.value > 0 || _isDragging)
                      // AnimatedPositioned automatically animates changes to its position (left, right, top, bottom).
                      AnimatedPositioned(
                        // If dragging, transition instantly (duration zero) to stick to the finger.
                        // Otherwise (e.g., on tap), smoothly animate to the new spot over 300 milliseconds.
                        duration: _isDragging
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        // Gives the animation a slight bouncy effect at the end.
                        curve: Curves.easeOutBack,
                        // Set the calculated X-coordinate for the thumb's horizontal placement.
                        left: thumbX,
                        // AnimatedContainer automatically animates changes to its color or shape.
                        child: AnimatedContainer(
                          // The duration for color or shadow changes.
                          duration: const Duration(milliseconds: 200),
                          // Give the thumb its fixed width and height.
                          width: thumbSize,
                          height: thumbSize,
                          // Style the thumb as a colored circle with a shadow.
                          decoration: BoxDecoration(
                            // Make the thumb a perfect circle.
                            shape: BoxShape.circle,
                            // Apply the calculated dynamic color based on the selected value.
                            color: col,
                            // Add a soft glowing shadow below the thumb to make it pop out.
                            boxShadow: [
                              BoxShadow(
                                // Use the thumb's color for the shadow but make it slightly transparent.
                                color: col.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          // Center the active icon inside the circular thumb.
                          child: Center(
                            child: Icon(
                              // Display the chosen face icon.
                              activeIcon,
                              // Make the icon mostly white so it stands out against the colored background.
                              color: Colors.white.withValues(alpha: 0.95),
                              // Set the size of the active icon (slightly larger than background icons).
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // --- 4. Bottom Text Labels ---
        // Add a small 12-pixel vertical space between the slider and the text labels below it.
        const SizedBox(height: 12),
        // Row to place the "Not ready" and "Fully ready" texts horizontally.
        Row(
          // Push the children to the far left and far right edges.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // The left label indicating the lowest scale meaning.
            Text('Not ready',
                style: TextStyle(
                    fontSize: 11, // Small text size
                    color: context.rrT4, // Theme color for text
                    fontWeight: FontWeight.w500)), // Medium thickness font
            // The right label indicating the highest scale meaning.
            Text('Fully ready',
                style: TextStyle(
                    fontSize: 11, // Small text size
                    color: context.rrT4, // Theme color for text
                    fontWeight: FontWeight.w500)), // Medium thickness font
          ],
        ),
      ],
    );
  }
}
