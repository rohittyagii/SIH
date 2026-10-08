// Import the core material design library from Flutter which contains UI components like widgets and gestures.
import 'package:flutter/material.dart';

// Defines a custom widget called `BouncyButton` that changes its appearance (shrinks) when pressed.
// It extends `StatefulWidget` because it needs to maintain internal animation state.
class BouncyButton extends StatefulWidget {
  // The widget that will be displayed inside this button (e.g., Text, Icon, Container).
  final Widget child;
  
  // A callback function that triggers when the user fully taps (presses and releases) the button.
  // Using `?` makes it optional (can be null).
  final VoidCallback? onTap;
  
  // A callback function that triggers the moment the user's finger touches the screen on this button.
  final GestureTapDownCallback? onTapDown;
  
  // A callback function that triggers the moment the user's finger is lifted off the screen.
  final GestureTapUpCallback? onTapUp;
  
  // A callback function that triggers if the tap is canceled (e.g., finger drags away before releasing).
  final GestureTapCancelCallback? onTapCancel;
  
  // Determines how this widget behaves during hit testing (how it catches touch events).
  // E.g., `HitTestBehavior.opaque` means it will catch taps even if its background is transparent.
  final HitTestBehavior behavior;
  
  // The scale factor to shrink the button down to when pressed. 
  // For example, 0.95 means it will shrink to 95% of its original size.
  final double scaleDown;

  // The constructor for BouncyButton to initialize its properties.
  const BouncyButton({
    super.key, // Passes the key to the parent class (StatefulWidget) to uniquely identify this widget.
    required this.child, // The `child` property must be provided when using this widget.
    this.onTap, // Optional tap callback.
    this.onTapDown, // Optional tap down callback.
    this.onTapUp, // Optional tap up callback.
    this.onTapCancel, // Optional tap cancel callback.
    this.behavior = HitTestBehavior.opaque, // Sets a default behavior to catch taps reliably.
    this.scaleDown = 0.95, // Sets a default shrink scale of 95%.
  });

  // Creates the mutable state for this widget at a given location in the tree.
  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

// The State class that holds the logic and animation details for the BouncyButton.
// `SingleTickerProviderStateMixin` is required to provide a `vsync` for the animation controller,
// ensuring the animation syncs with the screen's refresh rate.
class _BouncyButtonState extends State<BouncyButton> with SingleTickerProviderStateMixin {
  // The controller that drives the animation forward (shrinking) and backward (restoring size).
  // The `late` keyword means it will be initialized later in the `initState` method.
  late AnimationController _controller;

  // This method is called exactly once when this state object is first created.
  @override
  void initState() {
    super.initState(); // Always call the parent class's initState first.
    
    // Initialize the AnimationController.
    _controller = AnimationController(
      vsync: this, // Uses this state object (via the mixin) to synchronize the animation.
      duration: const Duration(milliseconds: 100), // How long it takes to shrink when pressed (100ms).
      reverseDuration: const Duration(milliseconds: 150), // How long it takes to bounce back when released (150ms).
    );
  }

  // This method is called when the widget is permanently removed from the widget tree.
  @override
  void dispose() {
    _controller.dispose(); // Always dispose of the animation controller to prevent memory leaks!
    super.dispose(); // Always call the parent class's dispose last.
  }

  // Internal method called when a tap down event occurs.
  void _handleTapDown(TapDownDetails details) {
    // If there is an action defined for tapping, start the shrink animation by moving the controller forward.
    if (widget.onTap != null || widget.onTapDown != null) _controller.forward();
    // If a custom onTapDown callback was provided by the user, call it and pass the details.
    if (widget.onTapDown != null) widget.onTapDown!(details);
  }

  // Internal method called when a tap up event occurs.
  void _handleTapUp(TapUpDetails details) {
    // If there is an action defined for tapping, reverse the animation to bounce back to normal size.
    if (widget.onTap != null || widget.onTapUp != null) _controller.reverse();
    // If a custom onTapUp callback was provided, call it.
    if (widget.onTapUp != null) widget.onTapUp!(details);
  }

  // Internal method called when a full tap (down and up) is successfully completed.
  void _handleTap() {
    // If a custom onTap callback was provided, execute it.
    if (widget.onTap != null) widget.onTap!();
  }

  // Internal method called if the tap gets cancelled (e.g., dragging finger off the button).
  void _handleTapCancel() {
    // Reverse the animation so the button goes back to normal size instead of staying shrunk.
    if (widget.onTap != null || widget.onTapCancel != null) _controller.reverse();
    // If a custom onTapCancel callback was provided, call it.
    if (widget.onTapCancel != null) widget.onTapCancel!();
  }

  // This method builds the visual representation of the widget on the screen.
  // It gets called whenever the widget needs to be drawn or updated.
  @override
  Widget build(BuildContext context) {
    // GestureDetector is used to detect various touch events (taps, drags, etc.).
    return GestureDetector(
      behavior: widget.behavior, // Pass the hit test behavior.
      
      // Wire up the tap down event. If either onTap or onTapDown exist, use our custom handler; otherwise, pass null (disabled).
      onTapDown: (widget.onTap != null || widget.onTapDown != null) ? _handleTapDown : null,
      
      // Wire up the tap up event.
      onTapUp: (widget.onTap != null || widget.onTapUp != null) ? _handleTapUp : null,
      
      // Wire up the tap cancel event.
      onTapCancel: (widget.onTap != null || widget.onTapCancel != null) ? _handleTapCancel : null,
      
      // Wire up the final tap event.
      onTap: widget.onTap != null ? _handleTap : null,
      
      // AnimatedBuilder listens to the _controller. Every time the controller's value changes,
      // it rebuilds just this specific part of the widget tree efficiently.
      child: AnimatedBuilder(
        animation: _controller, // The animation to listen to.
        builder: (context, child) {
          // Calculate the current scale. 
          // _controller.value goes from 0.0 to 1.0 during `forward()`.
          // If scaleDown is 0.95, the math becomes: 1.0 - (value * 0.05).
          // This smoothly transitions the scale from 1.0 down to 0.95.
          final scale = 1.0 - (_controller.value * (1.0 - widget.scaleDown));
          
          // Transform.scale scales its child widget by the calculated scale factor.
          return Transform.scale(
            scale: scale, // Apply the scaling factor (between 1.0 and 0.95).
            child: child, // The original widget passed into BouncyButton.
          );
        },
        child: widget.child, // Passing the child here is an optimization so it doesn't get rebuilt from scratch on every animation frame.
      ),
    );
  }
}
