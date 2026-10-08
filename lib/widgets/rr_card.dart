// Importing the material design library from Flutter which provides UI components like Widgets, Colors, etc.
import 'package:flutter/material.dart';
// Importing custom color themes from the local 'theme/colors.dart' file to style our app consistently.
import '../theme/colors.dart';
// Importing a custom widget 'bouncy_button.dart' to give our cards a bounce effect when tapped.
import 'bouncy_button.dart';

// ── RrCard ─────────────────────────────────────────────────────────────────
// Maps to .rr-card CSS class — the primary card container.

// Declaring a public class named 'RrCard' which extends 'StatelessWidget'.
// A StatelessWidget is used because the card's visual state does not change dynamically on its own.
class RrCard extends StatelessWidget {
  // Constructor for the RrCard class.
  // We use 'super.key' to pass a unique identifier to the parent widget.
  // 'required this.child' means every RrCard must have a child widget inside it.
  // 'this.padding' has a default value of 18 pixels on all sides using 'EdgeInsets.all(18)'.
  // 'this.onTap' is an optional callback function that triggers when the card is tapped.
  const RrCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap});
  
  // This variable holds the widget that will be displayed inside our card.
  final Widget child;
  
  // This variable holds the padding (empty space) inside the card around the child widget.
  final EdgeInsetsGeometry padding;
  
  // This variable stores the function to execute when the user taps on the card. It can be null.
  final VoidCallback? onTap;

  // The 'build' method describes the part of the user interface represented by this widget.
  // It is called whenever Flutter needs to draw or redraw this widget on the screen.
  @override
  Widget build(BuildContext context) {
    // We wrap our card content inside a 'BouncyButton' to add a tap animation effect.
    return BouncyButton(
      // If 'onTap' is provided, use it. Otherwise, use an empty function '() {}' so the button doesn't crash if tapped.
      onTap: onTap ?? () {},
      
      // 'scaleDown: 0.98' makes the button shrink to 98% of its original size when pressed down.
      scaleDown: 0.98,
      
      // The actual visual representation of the card is a 'Container'.
      child: Container(
        // Applying the padding defined earlier so the content isn't touching the edges.
        padding: padding,
        
        // 'decoration' allows us to style the container (background color, borders, shadows, etc.).
        decoration: BoxDecoration(
          // Setting the background color of the card. 'context.rrBgc' gets the background color from our custom theme.
          color: context.rrBgc,
          
          // Rounding the corners of the card with a radius of 14 pixels.
          borderRadius: BorderRadius.circular(14),
          
          // Adding a border around the card. The color is from our theme ('context.rrCb') and the width is 1 pixel.
          border: Border.all(color: context.rrCb, width: 1),
          
          // Adding a drop shadow to give a 3D elevated effect.
          boxShadow: [
            BoxShadow(
              // The color of the shadow, fetched from our custom theme extension.
              color: context.rrCsh, 
              // 'blurRadius: 20' determines how soft and blurry the shadow looks.
              blurRadius: 20, 
              // 'offset' moves the shadow slightly downwards by 2 pixels on the Y-axis.
              offset: const Offset(0, 2)
            )
          ],
        ),
        // Finally, placing the provided 'child' widget inside this decorated container.
        child: child,
      ),
    );
  }
}

// ── RrCardSm ───────────────────────────────────────────────────────────────
// Maps to .rr-card-sm CSS class — compact card for history entries.

// Declaring another public class named 'RrCardSm' which is a smaller version of RrCard.
// It also extends 'StatelessWidget' as its core design doesn't change on its own.
class RrCardSm extends StatelessWidget {
  // Constructor for the RrCardSm class.
  // Very similar to RrCard, but notice the default padding here is smaller: 14 pixels instead of 18.
  const RrCardSm({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});
  
  // The widget to display inside this smaller card.
  final Widget child;
  
  // The padding around the child widget.
  final EdgeInsetsGeometry padding;
  
  // The optional function to run when this small card is tapped.
  final VoidCallback? onTap;

  // The 'build' method that constructs the visual layout for this small card.
  @override
  Widget build(BuildContext context) {
    // Using 'BouncyButton' again for consistent tap animations across the app.
    return BouncyButton(
      // Execute the provided 'onTap' function, or do nothing if none was provided.
      onTap: onTap ?? () {},
      
      // Shrink to 98% of its original size on press.
      scaleDown: 0.98,
      
      // A 'Container' widget forms the body of our small card.
      child: Container(
        // Applying the padding (default is 14 pixels).
        padding: padding,
        
        // Styling the container's appearance.
        decoration: BoxDecoration(
          // Using the theme's background color.
          color: context.rrBgc,
          
          // Rounding the corners slightly less than the large card: 12 pixels instead of 14.
          borderRadius: BorderRadius.circular(12),
          
          // Adding a 1-pixel border using the theme's border color.
          border: Border.all(color: context.rrCb, width: 1),
          
          // Adding a slightly smaller shadow for this compact card.
          boxShadow: [
            BoxShadow(
              // Using the theme's shadow color.
              color: context.rrCsh, 
              // A smaller blur radius of 14 makes the shadow look closer to the surface.
              blurRadius: 14, 
              // Pushing the shadow down by 2 pixels.
              offset: const Offset(0, 2)
            )
          ],
        ),
        // Adding the 'child' widget into this container.
        child: child,
      ),
    );
  }
}
