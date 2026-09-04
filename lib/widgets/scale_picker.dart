import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/seed.dart';

// ── ScalePicker ─────────────────────────────────────────────────────────────
// 5 circular tap targets for 1–5 rating.
class ScalePicker extends StatelessWidget {
  const ScalePicker({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final n = i + 1;
            final on = value == n;
            final col = scoreColor(n);
            final glow = scoreGlow(n);
            return GestureDetector(
              onTap: () => onChanged(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: on ? col : context.rrB3, width: on ? 2 : 1.5),
                  color: on ? glow : context.rrOv,
                  boxShadow: on ? [BoxShadow(color: glow, blurRadius: 18)] : [],
                ),
                child: on
                    ? Center(
                        child: Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: col,
                            boxShadow: [BoxShadow(color: col, blurRadius: 8)],
                          ),
                        ),
                      )
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Not ready', style: TextStyle(fontSize: 11, color: context.rrT4)),
            Text('Fully ready', style: TextStyle(fontSize: 11, color: context.rrT4)),
          ],
        ),
      ],
    );
  }
}
