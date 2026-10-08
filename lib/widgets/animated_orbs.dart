// We import the 'dart:math' library because we need mathematical functions like 'sin' (sine), 'cos' (cosine), and the constant 'pi' for our animations.
import 'dart:math';
// We import the material design library from Flutter which provides essential widgets, drawing tools, and layout systems needed to build the UI.
import 'package:flutter/material.dart';
// We import our custom colors defined in another file, so we can use consistent theme colors throughout the application.
import '../theme/colors.dart';

// We define a new class 'AnimatedOrbsBackground' that extends 'StatefulWidget'. 
// We use a StatefulWidget because our background has state that changes over time (the animation of the orbs).
class AnimatedOrbsBackground extends StatefulWidget {
  // This is the constructor for our widget. The 'super.key' allows Flutter to uniquely identify this widget in the widget tree.
  const AnimatedOrbsBackground({super.key});

  // Here we override the 'createState' method to create the mutable state for this widget.
  // It returns an instance of our private state class '_AnimatedOrbsBackgroundState'.
  @override
  State<AnimatedOrbsBackground> createState() => _AnimatedOrbsBackgroundState();
}

// This is the state class where the actual logic and UI for the AnimatedOrbsBackground live.
// We use 'with SingleTickerProviderStateMixin' to provide a single "ticker" to our AnimationController.
// A ticker calls its callback once per animation frame, which is required for animations to run smoothly.
class _AnimatedOrbsBackgroundState extends State<AnimatedOrbsBackground> with SingleTickerProviderStateMixin {
  // We declare an 'AnimationController' named '_controller'. 
  // 'late' means we promise to initialize it before it's used, which we will do in 'initState'.
  // This controller will drive our animation by going from 0.0 to 1.0 over a specified duration.
  late AnimationController _controller;

  // The 'initState' method is called exactly once when this widget is first added to the screen.
  // It's the perfect place to set up things like our AnimationController.
  @override
  void initState() {
    // We must always call super.initState() first.
    super.initState();
    // We initialize the AnimationController.
    _controller = AnimationController(
      // 'vsync: this' ties the animation to the screen's refresh rate using the SingleTickerProviderStateMixin we added earlier.
      vsync: this,
      // We set the duration of one complete animation cycle to 20 seconds. This makes the orbs move slowly and gracefully.
      duration: const Duration(seconds: 20),
    // The '..repeat()' is a cascade operator that immediately tells the controller to loop the animation continuously.
    )..repeat();
  }

  // The 'dispose' method is called when this widget is permanently removed from the screen.
  // We use it to clean up resources to prevent memory leaks.
  @override
  void dispose() {
    // We must dispose of our AnimationController to free up the resources it was using.
    _controller.dispose();
    // We must always call super.dispose() at the end.
    super.dispose();
  }

  // The 'build' method describes the part of the user interface represented by this widget.
  // It is called whenever Flutter needs to draw or redraw the widget.
  @override
  Widget build(BuildContext context) {
    // We return an 'AnimatedBuilder', which is a special widget that automatically rebuilds 
    // every time the 'animation' (our controller) changes its value (i.e., every frame of the animation).
    return AnimatedBuilder(
      // We pass our AnimationController as the animation to listen to.
      animation: _controller,
      // The 'builder' function defines what the AnimatedBuilder should draw on the screen.
      // It is called repeatedly as the animation progresses.
      builder: (context, child) {
        // We calculate 't', which represents time or progress.
        // _controller.value goes from 0.0 to 1.0. Multiplying it by 2 * pi gives us a value from 0 to 2π, 
        // which represents one full circle (360 degrees) in radians. This is perfect for sine and cosine functions.
        final t = _controller.value * 2 * pi;
        // We get the current size of the screen (or the parent container) using MediaQuery.
        // We need this to position the orbs relative to the screen dimensions.
        final size = MediaQuery.of(context).size;
        
        // We use a 'Stack' widget to layer multiple widgets on top of each other.
        return Stack(
          children: [
            // Base background
            // The first child of the Stack is at the very bottom.
            // It's a Container that fills the whole screen with a base background color.
            // Note: 'context.rrBg' seems to be an extension method defined elsewhere that provides a specific background color from the theme.
            Container(color: context.rrBg),
            
            // Orb 1: Indigo (moves in an infinity loop)
            // A 'Positioned' widget lets us place its child at an exact coordinate within the Stack.
            Positioned(
              // To calculate the horizontal 'left' position:
              // 1. 'size.width * 0.5' starts at the horizontal center of the screen.
              // 2. 'sin(t) * size.width * 0.4' oscillates left and right by 40% of the screen width.
              // 3. '- 150' subtracts half the width of the orb (which is 300) to perfectly center the orb on that coordinate.
              left: size.width * 0.5 + sin(t) * size.width * 0.4 - 150,
              // To calculate the vertical 'top' position:
              // 1. 'size.height * 0.4' starts at 40% down from the top of the screen.
              // 2. 'sin(t * 2) * size.height * 0.2' oscillates up and down. The 't * 2' makes it move vertically twice as fast as horizontally, creating an infinity (figure-eight) shape.
              // 3. '- 150' subtracts half the height of the orb to center it.
              top: size.height * 0.4 + sin(t * 2) * size.height * 0.2 - 150,
              // We call our helper function '_buildOrb' to create the visual representation of the orb.
              // We pass the indigo color from our theme and a size of 300 pixels.
              child: _buildOrb(AppColors.indigo, 300),
            ),
            
            // Orb 2: Score5 (Teal) (moves in a circle)
            // This is the second orb in our stack, placed above the base and first orb.
            Positioned(
              // Horizontal position: Uses 'cos(t * 1.5)'. Combined with 'sin' for the vertical position, this creates circular motion. The '1.5' speed modifier makes it move 1.5 times faster.
              // It starts from the center and moves in a radius of 30% of the screen width. '- 120' centers the 240px orb.
              left: size.width * 0.5 + cos(t * 1.5) * size.width * 0.3 - 120,
              // Vertical position: Uses 'sin(t * 1.5)'. Starting from 60% down the screen, moving in a radius of 30% of screen height.
              top: size.height * 0.6 + sin(t * 1.5) * size.height * 0.3 - 120,
              // We draw the orb using a color named 'score5' (likely teal) and a size of 240 pixels.
              child: _buildOrb(AppColors.score5, 240),
            ),
            
            // Orb 3: Accent Blue (moves up and down)
            // This is the third and topmost orb.
            Positioned(
              // Horizontal position: starts 20% from the left, oscillates using 'cos' at 0.8x speed. Radius is 20% of screen width. Centers the 200px orb by subtracting 100.
              left: size.width * 0.2 + cos(t * 0.8) * size.width * 0.2 - 100,
              // Vertical position: starts 20% from the top, oscillates using 'sin' at 1.2x speed.
              top: size.height * 0.2 + sin(t * 1.2) * size.height * 0.2 - 100,
              // We draw the orb using 'score3' color (likely blue) and a size of 200 pixels.
              child: _buildOrb(AppColors.score3, 200),
            ),
          ],
        );
      },
    );
  }

  // This is a helper method we created to draw a single orb.
  // It takes a 'color' and a 'size' and returns a customized Container widget.
  Widget _buildOrb(Color color, double size) {
    // We use a Container to draw the orb.
    return Container(
      // We set the width and height of the container to the provided size.
      width: size,
      height: size,
      // We use a BoxDecoration to style the container and make it look like a glowing orb.
      decoration: BoxDecoration(
        // 'BoxShape.circle' makes the container perfectly round instead of a rectangle.
        shape: BoxShape.circle,
        // The 'boxShadow' creates an outer glow effect around the orb.
        boxShadow: [
          BoxShadow(
            // The shadow uses the orb's color but with a very low opacity (15% alpha) so it looks like a soft glow.
            color: color.withValues(alpha: 0.15),
            // The blur radius makes the shadow fuzzy. We set it to half the size of the orb for a wide blur.
            blurRadius: size / 2,
            // The spread radius determines how far the shadow extends past the container's borders. We set it to a quarter of the size.
            spreadRadius: size / 4,
          )
        ],
        // The 'gradient' creates a smooth color transition inside the orb.
        // We use a RadialGradient, which radiates outward from the center.
        gradient: RadialGradient(
          colors: [
            // At the center, the color is slightly visible (20% alpha).
            color.withValues(alpha: 0.2),
            // At the outer edge, the color fades to completely transparent (0% alpha).
            // This makes the orb look like a soft, diffused light source without hard edges.
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
