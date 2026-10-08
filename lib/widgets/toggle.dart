// Import the core Flutter material design library, which provides built-in UI components like widgets, colors, and animations.
import 'package:flutter/material.dart';
// Import a custom colors file from the theme folder of this project. This likely contains predefined colors used across the app (like AppColors.indigo).
import '../theme/colors.dart';

// ── Toggle ──────────────────────────────────────────────────────────────────
// Animated on/off switch — maps to the Toggle React component.

// Define a new custom widget named 'Toggle'. 
// It extends 'StatelessWidget', which means this widget's visual state is determined entirely by the inputs (properties) passed to it and cannot change itself internally.
class Toggle extends StatelessWidget {
  // The constructor for the Toggle widget. 
  // 'super.key' is used by Flutter to uniquely identify this widget in the widget tree.
  // 'required this.on' means whoever uses this widget MUST provide a boolean (true/false) value for 'on'.
  // 'required this.onToggle' means whoever uses this widget MUST provide a function to run when the toggle is tapped.
  const Toggle({super.key, required this.on, required this.onToggle});
  
  // A boolean variable (true or false) indicating whether the toggle switch is currently "on" or "off".
  // It is marked 'final' because a StatelessWidget's properties cannot change after being created.
  final bool on;
  
  // A callback function with no arguments and no return value (VoidCallback).
  // This function will be executed whenever the user taps on the toggle switch to change its state.
  final VoidCallback onToggle;

  // The 'build' method is called by Flutter to draw the widget on the screen.
  // It takes a 'BuildContext' which contains information about this widget's location in the widget tree.
  @override
  Widget build(BuildContext context) {
    // Return a GestureDetector widget. This widget doesn't have a visual appearance itself, 
    // but it listens for touch events (like taps, swipes, etc.) on its child widget.
    return GestureDetector(
      // When the user taps this area, call the 'onToggle' function that was passed in.
      onTap: onToggle,
      // The visual part of the toggle is an AnimatedContainer. 
      // Whenever its properties (like color or size) change, it will smoothly animate to the new values instead of snapping instantly.
      child: AnimatedContainer(
        // Set the duration of the animation to 200 milliseconds, making the transition quick and smooth.
        duration: const Duration(milliseconds: 200),
        // Set a fixed width of 44 logical pixels for the toggle switch background.
        width: 44, 
        // Set a fixed height of 26 logical pixels for the toggle switch background.
        height: 26,
        // Add padding of 3 pixels on all sides inside the container. This creates a small gap between the background and the circular knob.
        padding: const EdgeInsets.all(3),
        // Style the container's appearance using a BoxDecoration.
        decoration: BoxDecoration(
          // Make the corners fully rounded (a high radius like 999 ensures it looks like a pill shape).
          borderRadius: BorderRadius.circular(999),
          // Set the background color based on the 'on' state.
          // If 'on' is true, use 'AppColors.indigo'. 
          // If 'on' is false, use 'context.rrB2' (an extension property on BuildContext defining a custom color from the theme).
          color: on ? AppColors.indigo : context.rrB2,
        ),
        // The child inside the container is an AnimatedAlign widget.
        // It smoothly moves its child (the circular knob) from one alignment to another.
        child: AnimatedAlign(
          // Set the movement animation duration to 200 milliseconds, matching the background color animation.
          duration: const Duration(milliseconds: 200),
          // Align the knob to the center-right if 'on' is true, or center-left if 'on' is false.
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          // The actual knob of the toggle switch is a simple Container.
          child: Container(
            // Set the width of the circular knob to 20 pixels.
            width: 20, 
            // Set the height of the circular knob to 20 pixels.
            height: 20,
            // Style the knob to be a white circle.
            decoration: const BoxDecoration(
              // Make the shape of this container a perfect circle.
              shape: BoxShape.circle, 
              // Fill the circular knob with a solid white color.
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
