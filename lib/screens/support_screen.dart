import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';

// ── SupportScreen ─────────────────────────────────────────────────────────────
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.rrBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resources & support',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: context.rrT1)),
              const SizedBox(height: 4),
              Text('Confidential support, available any time',
                style: TextStyle(fontSize: 13, color: context.rrT4)),
              const SizedBox(height: 24),
              // Welfare officer card
              RrCard(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: AppColors.indigo.withValues(alpha: 0.12),
                          ),
                          child: const Center(child: IconShield(size: 14, color: AppColors.indigo)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Talk to your welfare officer',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.rrT1)),
                              const SizedBox(height: 4),
                              Text('Conversations are confidential unless you decide otherwise. No formal record is created.',
                                style: TextStyle(fontSize: 13, color: context.rrT3, height: 1.6)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.indigo.withValues(alpha: 0.12),
                        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.20)),
                      ),
                      child: const Center(
                        child: Text('Contact welfare office',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.indigo)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 24-hour line card
              RrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('24-hour support line',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.rrT1)),
                    const SizedBox(height: 4),
                    Text('Free and confidential — any time, any day.',
                      style: TextStyle(fontSize: 13, color: context.rrT3, height: 1.6)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.score5.withValues(alpha: 0.10),
                              border: Border.all(color: AppColors.score5.withValues(alpha: 0.20)),
                            ),
                            child: Center(
                              child: Text('0800 323 4444',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.score5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.dimSleep.withValues(alpha: 0.10),
                              border: Border.all(color: AppColors.dimSleep.withValues(alpha: 0.20)),
                            ),
                            child: Center(
                              child: Text('Text BLUE to 85258',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.dimSleep)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // About card
              RrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About this service',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.rrT2)),
                    const SizedBox(height: 8),
                    Text('Your check-ins are stored locally on this device and are never shared without your consent. This app is provided by your unit welfare office as a voluntary wellbeing tool.',
                      style: TextStyle(fontSize: 13, color: context.rrT3, height: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
