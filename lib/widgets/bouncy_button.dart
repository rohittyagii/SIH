import 'package:flutter/material.dart';

class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final HitTestBehavior behavior;
  final double scaleDown;

  const BouncyButton({
    super.key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.behavior = HitTestBehavior.opaque,
    this.scaleDown = 0.95,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onTapDown != null) _controller.forward();
    if (widget.onTapDown != null) widget.onTapDown!(details);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null || widget.onTapUp != null) _controller.reverse();
    if (widget.onTapUp != null) widget.onTapUp!(details);
  }

  void _handleTap() {
    if (widget.onTap != null) widget.onTap!();
  }

  void _handleTapCancel() {
    if (widget.onTap != null || widget.onTapCancel != null) _controller.reverse();
    if (widget.onTapCancel != null) widget.onTapCancel!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (widget.onTap != null || widget.onTapDown != null) ? _handleTapDown : null,
      onTapUp: (widget.onTap != null || widget.onTapUp != null) ? _handleTapUp : null,
      onTapCancel: (widget.onTap != null || widget.onTapCancel != null) ? _handleTapCancel : null,
      onTap: widget.onTap != null ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * (1.0 - widget.scaleDown));
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
