import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/seed.dart';

// ── ScoreDots ───────────────────────────────────────────────────────────────
// Row of 5 small filled/unfilled dots showing a score.
class ScoreDots extends StatelessWidget {
  const ScoreDots({super.key, required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final col = scoreColor(score);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < score;
        return Container(
          width: 6, height: 6,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? col : context.rrIb,
          ),
        );
      }),
    );
  }
}
