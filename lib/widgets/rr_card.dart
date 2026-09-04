import 'package:flutter/material.dart';
import '../theme/colors.dart';

// ── RrCard ─────────────────────────────────────────────────────────────────
// Maps to .rr-card CSS class — the primary card container.
class RrCard extends StatelessWidget {
  const RrCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.rrBgc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.rrCb, width: 1),
        boxShadow: [BoxShadow(color: context.rrCsh, blurRadius: 20, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

// ── RrCardSm ───────────────────────────────────────────────────────────────
// Maps to .rr-card-sm CSS class — compact card for history entries.
class RrCardSm extends StatelessWidget {
  const RrCardSm({super.key, required this.child, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.rrBgc,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.rrCb, width: 1),
        boxShadow: [BoxShadow(color: context.rrCsh, blurRadius: 14, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
