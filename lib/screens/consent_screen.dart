import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../data/seed.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';

// ── ConsentScreen ────────────────────────────────────────────────────────────
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key, required this.onAgree});
  final VoidCallback onAgree;

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _expanded = false;

  Widget _assuranceIcon(Assurance a) {
    if (a.color == AppColors.indigo) return IconLock(size: 16, color: a.color);
    if (a.color == const Color(0xFF56B4E9))
      return IconEyeOff(size: 16, color: a.color);
    return IconCircleCheck(size: 16, color: a.color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.rrBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shield icon
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 64, bottom: 36),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.indigo.withValues(alpha: 0.10),
                      border: Border.all(
                          color: AppColors.indigo.withValues(alpha: 0.24)),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.indigo.withValues(alpha: 0.10),
                            blurRadius: 48)
                      ],
                    ),
                    child: const Center(
                        child: IconShield(size: 30, color: AppColors.indigo)),
                  ),
                ),
              ),
              // Heading
              Text('READINESS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: context.rrT6,
                      letterSpacing: 0.10)),
              const SizedBox(height: 10),
              RichText(
                  text: TextSpan(
                text: 'Your check-ins,\n',
                style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    color: context.rrT1,
                    height: 1.25),
                children: const [TextSpan(text: 'your call')],
              )),
              const SizedBox(height: 14),
              Text(
                  'This is a personal readiness tool — not an assessment, and not a record that goes anywhere else. You decide what you log, and you stay in control of it.',
                  style: TextStyle(
                      fontSize: 14, color: context.rrT3, height: 1.65)),
              const SizedBox(height: 28),
              // Assurances card
              RrCard(
                child: Column(
                  children: assurances.asMap().entries.map((e) {
                    final i = e.key;
                    final a = e.value;
                    return Column(
                      children: [
                        if (i > 0) ...[
                          Divider(color: context.rrDv, height: 32),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: a.color.withValues(alpha: 0.11),
                              ),
                              child: Center(child: _assuranceIcon(a)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.title,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: context.rrT2,
                                          height: 1.2)),
                                  const SizedBox(height: 4),
                                  Text(a.body,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: context.rrT3,
                                          height: 1.6)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              // Expandable details
              if (_expanded) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.rrOv,
                    border: Border.all(color: context.rrDv2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A few more details',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.rrT6,
                              letterSpacing: 0.06)),
                      const SizedBox(height: 12),
                      ...learnMoreItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin:
                                      const EdgeInsets.only(top: 7, right: 10),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.rrT6),
                                ),
                                Expanded(
                                    child: Text(item,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: context.rrT3,
                                            height: 1.6))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Agree button
              GestureDetector(
                onTap: widget.onAgree,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.indigo,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.indigo.withValues(alpha: 0.28),
                          blurRadius: 28,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Center(
                    child: Text('I agree, continue',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0C1220))),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Show less' : 'Learn more about data handling',
                    style: TextStyle(fontSize: 14, color: context.rrT3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
