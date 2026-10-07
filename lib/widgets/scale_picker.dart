import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/seed.dart';

// ── ScalePicker ─────────────────────────────────────────────────────────────
class ScalePicker extends StatefulWidget {
  const ScalePicker({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<ScalePicker> createState() => _ScalePickerState();
}

class _ScalePickerState extends State<ScalePicker> {
  double? _dragX; // Current pixel position of drag
  bool _isDragging = false;

  void _handlePanStart(DragStartDetails details, double maxWidth) {
    setState(() {
      _isDragging = true;
      _dragX = details.localPosition.dx.clamp(0.0, maxWidth);
    });
    _updateValue(maxWidth);
  }

  void _handlePanUpdate(DragUpdateDetails details, double maxWidth) {
    setState(() {
      _dragX = details.localPosition.dx.clamp(0.0, maxWidth);
    });
    _updateValue(maxWidth);
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragX = null;
    });
  }

  void _handleTapDown(TapDownDetails details, double maxWidth) {
    setState(() {
      _dragX = details.localPosition.dx.clamp(0.0, maxWidth);
    });
    _updateValue(maxWidth);
    setState(() {
      _dragX = null;
    });
  }

  void _updateValue(double maxWidth) {
    if (_dragX == null) return;
    final segment = maxWidth / 5;
    int newValue = (_dragX! / segment).floor() + 1;
    if (newValue > 5) newValue = 5;
    if (newValue < 1) newValue = 1;
    if (newValue != widget.value) {
      widget.onChanged(newValue);
    }
  }

  IconData _getIconForValue(int v) {
    switch (v) {
      case 1: return Icons.sentiment_very_dissatisfied_rounded;
      case 2: return Icons.sentiment_dissatisfied_rounded;
      case 3: return Icons.sentiment_neutral_rounded;
      case 4: return Icons.sentiment_satisfied_rounded;
      case 5: return Icons.sentiment_very_satisfied_rounded;
      default: return Icons.sentiment_neutral_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final trackHeight = 44.0;
            final thumbSize = 56.0;
            final maxWidth = constraints.maxWidth;
            final segment = maxWidth / 5;

            // Calculate active position
            double thumbX;
            if (_isDragging && _dragX != null) {
              thumbX = _dragX! - (thumbSize / 2);
            } else if (widget.value > 0) {
              thumbX = (widget.value - 1) * segment + (segment / 2) - (thumbSize / 2);
            } else {
              thumbX = (2) * segment + (segment / 2) - (thumbSize / 2); // Default to center if no value
            }

            // Clamp thumb position within widget bounds
            thumbX = thumbX.clamp(0.0, maxWidth - thumbSize);

            final col = widget.value > 0 ? scoreColor(widget.value) : context.rrT4;
            final activeIcon = _getIconForValue(widget.value > 0 ? widget.value : 3);

            return GestureDetector(
              onHorizontalDragStart: (d) => _handlePanStart(d, maxWidth),
              onHorizontalDragUpdate: (d) => _handlePanUpdate(d, maxWidth),
              onHorizontalDragEnd: _handlePanEnd,
              onTapDown: (d) => _handleTapDown(d, maxWidth),
              child: SizedBox(
                height: thumbSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Track background
                    Container(
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: context.rrBgn,
                        borderRadius: BorderRadius.circular(trackHeight / 2),
                        border: Border.all(color: context.rrDv2, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: context.rrCsh.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                    // Track icons and separators
                    SizedBox(
                      height: trackHeight,
                      child: Row(
                        children: List.generate(5, (i) {
                          final n = i + 1;
                          return Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (i > 0)
                                  Positioned(
                                    left: 0,
                                    child: Container(width: 1, height: 16, color: context.rrDv2),
                                  ),
                                Icon(
                                  _getIconForValue(n),
                                  color: context.rrT4.withOpacity(0.3),
                                  size: 28,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    // Animated Thumb
                    if (widget.value > 0 || _isDragging)
                      AnimatedPositioned(
                        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        left: thumbX,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: thumbSize,
                          height: thumbSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: col,
                            boxShadow: [
                              BoxShadow(
                                color: col.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              activeIcon,
                              color: Colors.white.withOpacity(0.95),
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Not ready', style: TextStyle(fontSize: 11, color: context.rrT4, fontWeight: FontWeight.w500)),
            Text('Fully ready', style: TextStyle(fontSize: 11, color: context.rrT4, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

