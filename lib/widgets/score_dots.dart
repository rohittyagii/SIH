// Import the core Flutter material design library, which provides UI components like Row and Container.
import 'package:flutter/material.dart';
// Import the custom color definitions for the app's theme.
import '../theme/colors.dart';
// Import the data definitions, which presumably contains the 'scoreColor' function.
import '../data/seed.dart';

// ── ScoreDots ───────────────────────────────────────────────────────────────
// Row of 5 small filled/unfilled dots showing a score.

// A stateless widget that displays a score as a series of 5 small dots.
// We use StatelessWidget because the widget itself doesn't need to change its own state over time.
class ScoreDots extends StatelessWidget {
  // The constructor for the ScoreDots widget.
  // 'super.key' allows Flutter to uniquely identify this widget in the widget tree.
  // 'required this.score' means anyone using this widget MUST provide a score value.
  const ScoreDots({super.key, required this.score});
  
  // The final integer variable that holds the score value passed into the widget.
  // Because this is a StatelessWidget, all properties must be final (unchangeable after creation).
  final int score;

  // The build method describes the part of the user interface represented by this widget.
  // It is called whenever Flutter needs to draw or redraw the widget.
  @override
  Widget build(BuildContext context) {
    // Determine the color of the filled dots based on the score value.
    // 'scoreColor' is a helper function likely defined in '../data/seed.dart'.
    final col = scoreColor(score);
    
    // Return a Row widget, which arranges its children horizontally in a line.
    return Row(
      // mainAxisSize: MainAxisSize.min tells the Row to take up only as much horizontal space as its children need.
      // If we didn't specify this, it might stretch to fill all available horizontal space.
      mainAxisSize: MainAxisSize.min,
      
      // The children of the Row are generated dynamically using List.generate.
      // We want exactly 5 dots in total, so the length is 5.
      children: List.generate(5, (i) {
        // 'i' is the index of the current dot being generated, going from 0 to 4.
        // We determine if the current dot should be filled by checking if its index is less than the score.
        // For example, if score is 3, indices 0, 1, and 2 will be true (filled), and 3, 4 will be false.
        final filled = i < score;
        
        // Return a Container widget for each dot. A Container is a versatile widget used for styling and layout.
        return Container(
          // Set the dimensions of the dot to 6x6 logical pixels.
          width: 6, height: 6,
          
          // Add a margin to the left of the dot to space them out.
          // If it's the first dot (i == 0), no margin is added so it aligns perfectly to the left edge.
          // Otherwise, we add 4 logical pixels of space between this dot and the previous one.
          margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
          
          // The decoration property allows us to visually style the Container.
          // We use BoxDecoration to give it a background color and shape.
          decoration: BoxDecoration(
            // Set the shape of the box to be a circle, instead of the default rectangle.
            shape: BoxShape.circle,
            
            // Set the color of the dot.
            // If the dot should be 'filled' (based on the score), use the 'col' we calculated earlier.
            // Otherwise, use 'context.rrIb', which seems to be a custom theme color extension for the unfilled state.
            color: filled ? col : context.rrIb,
          ),
        );
      }), // End of List.generate
    ); // End of Row
  } // End of build method
} // End of ScoreDots class
