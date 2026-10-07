import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../data/seed.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';
import '../widgets/score_dots.dart';
import '../providers/app_state.dart';
import '../data/translations.dart';
import '../widgets/bouncy_button.dart';

// ── SubmittedScreen ───────────────────────────────────────────────────────────
class SubmittedScreen extends ConsumerWidget {
  const SubmittedScreen({
    super.key,
    required this.scores,
    required this.note,
    required this.onDone,
  });
  final Map<DimKey, int> scores;
  final String note;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.rrBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          child: Column(
            children: [
              // Success icon
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.score5.withValues(alpha: 0.10),
                  border: Border.all(color: AppColors.score5.withValues(alpha: 0.28), width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.score5.withValues(alpha: 0.12), blurRadius: 48)],
                ),
                child: const Center(child: IconCheck(size: 30, color: AppColors.score5)),
              ),
              const SizedBox(height: 28),
              Text(tr('Readiness logged', ref),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: context.rrT1),
                textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Thursday, 4 Sep 2026 · See you tomorrow',
                style: TextStyle(fontSize: 14, color: context.rrT3, height: 1.6),
                textAlign: TextAlign.center),
              const SizedBox(height: 32),
              // Scores summary
              RrCard(
                child: Column(
                  children: [
                    ...dims.asMap().entries.map((e) {
                      final i = e.key;
                      final d = e.value;
                      final s = scores[d.key]!;
                      final col = scoreColor(s);
                      return Column(
                        children: [
                          if (i > 0) const SizedBox(height: 16),
                          Row(
                            children: [
                              dimIcon(d.key, size: 15, color: col),
                              const SizedBox(width: 12),
                              Expanded(child: Text(tr(d.label, ref), style: TextStyle(fontSize: 13, color: context.rrT3))),
                              ScoreDots(score: s),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 72,
                                child: Text(tr(scoreLabel(s), ref),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: col),
                                  textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                    if (note.isNotEmpty) ...[
                      Divider(color: context.rrDv2, height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('Note', ref), style: TextStyle(fontSize: 11, color: context.rrT6)),
                            const SizedBox(height: 4),
                            Text(note, style: TextStyle(fontSize: 13, color: context.rrT2b, height: 1.6)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Streak chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppColors.indigo.withValues(alpha: 0.09),
                  border: Border.all(color: AppColors.indigo.withValues(alpha: 0.20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const IconFlame(size: 13, color: AppColors.indigo),
                    const SizedBox(width: 8),
                    Text('${ref.watch(streakProvider)}-day streak — well done',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.indigo)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              BouncyButton(
                onTap: onDone,
                child: Text(tr('Back to home', ref),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.indigo)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
