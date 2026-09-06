import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../data/seed.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';
import '../widgets/score_dots.dart';

// ── OfflineSubmittedScreen ────────────────────────────────────────────────────
class OfflineSubmittedScreen extends ConsumerWidget {
  const OfflineSubmittedScreen({super.key, this.onDone});
  final VoidCallback? onDone;

  static const _amber = Color(0xFFC4A870);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.rrBg,
      body: Stack(
        children: [
          // Warm atmospheric wash
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.5),
                  radius: 1.0,
                  colors: [Color(0x0EC4A870), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: Column(
                children: [
                  const SizedBox(height: 56),
                  // Icon
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _amber.withValues(alpha: 0.07),
                          border: Border.all(
                              color: _amber.withValues(alpha: 0.24),
                              width: 1.5),
                        ),
                        child: const Center(
                            child: IconCloudQueue(size: 30, color: _amber)),
                      ),
                      // Queue badge
                      Positioned(
                        bottom: -9,
                        right: -9,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: context.rrBg,
                            border: Border.all(
                                color: _amber.withValues(alpha: 0.28),
                                width: 1.5),
                          ),
                          child: const Center(
                            child: Text('···',
                                style: TextStyle(
                                    color: _amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.04,
                                    height: 1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('Saved on your device',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: context.rrT1,
                          height: 1.25),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text('Thu, 4 Sep 2026 · 14:32',
                      style: TextStyle(fontSize: 13, color: context.rrT4),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  Text(
                    "You're offline right now. This check-in is stored locally and will sync automatically when your connection is restored.",
                    style: TextStyle(
                        fontSize: 14, color: context.rrT3, height: 1.65),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Offline chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: _amber.withValues(alpha: 0.08),
                      border: Border.all(color: _amber.withValues(alpha: 0.22)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconNoWifi(size: 11, color: _amber),
                        SizedBox(width: 7),
                        Text('Offline · Syncs when reconnected',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _amber)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Score summary
                  RrCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WHAT YOU LOGGED',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: context.rrT6,
                                letterSpacing: 0.10)),
                        const SizedBox(height: 14),
                        ...dims.asMap().entries.map((e) {
                          final i = e.key;
                          final d = e.value;
                          final s = offlineScores[d.key]!;
                          final col = scoreColor(s);
                          return Column(
                            children: [
                              if (i > 0) ...[
                                Divider(color: context.rrDv, height: 24)
                              ],
                              Row(
                                children: [
                                  dimIcon(d.key, size: 15, color: col),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(d.label,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: context.rrT3))),
                                  ScoreDots(score: s),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 68,
                                    child: Text(scoreLabel(s),
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: col),
                                        textAlign: TextAlign.right),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Reassurance note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: context.rrOv,
                      border: Border.all(color: context.rrDv),
                    ),
                    child: Text(
                      'Nothing is lost. Your data is on this device and will appear in your trend as soon as the sync completes.',
                      style: TextStyle(
                          fontSize: 12, color: context.rrT4, height: 1.65),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Back to home
                  GestureDetector(
                    onTap: onDone,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: AppColors.indigo.withValues(alpha: 0.09),
                      ),
                      child: const Center(
                        child: Text('Back to home',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.indigo)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
