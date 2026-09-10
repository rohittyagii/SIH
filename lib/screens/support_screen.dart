import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';
import '../services/support_service.dart';
import '../data/translations.dart';

// ── SupportScreen ─────────────────────────────────────────────────────────────
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  bool _requesting = false;
  bool _requested = false;
  
  Future<void> _handleCallback(WidgetRef ref) async {
    if (_requesting || _requested) return;
    setState(() => _requesting = true);
    try {
      await ref.read(supportServiceProvider).requestCallback();
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _requested = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Callback requested. Your welfare officer will contact you shortly.', ref)), backgroundColor: AppColors.score5)
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _requesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Failed to request callback. Please try again.', ref)), backgroundColor: AppColors.score1)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.rrBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Resources & support', ref),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.rrT1)),
              const SizedBox(height: 4),
              Text(tr('Confidential support, available any time', ref),
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
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: AppColors.indigo.withValues(alpha: 0.12),
                          ),
                          child: const Center(
                              child: IconShield(
                                  size: 14, color: AppColors.indigo)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('Talk to your welfare officer', ref),
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: context.rrT1)),
                              const SizedBox(height: 4),
                              Text(
                                  tr('Conversations are confidential unless you decide otherwise. No formal record is created.', ref),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: context.rrT3,
                                      height: 1.6)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _handleCallback(ref),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _requested 
                              ? AppColors.score5.withValues(alpha: 0.12)
                              : AppColors.indigo.withValues(alpha: 0.12),
                          border: Border.all(
                              color: _requested 
                                  ? AppColors.score5.withValues(alpha: 0.20)
                                  : AppColors.indigo.withValues(alpha: 0.20)),
                        ),
                        child: Center(
                          child: Text(
                              _requesting ? tr('Requesting...', ref) : _requested ? tr('Callback Requested', ref) : tr('Contact welfare office', ref),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _requested ? AppColors.score5 : AppColors.indigo)),
                        ),
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
                    Text(tr('24-hour support line', ref),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.rrT1)),
                    const SizedBox(height: 4),
                    Text(tr('Free and confidential — any time, any day.', ref),
                        style: TextStyle(
                            fontSize: 13, color: context.rrT3, height: 1.6)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => launchUrl(Uri.parse('tel:08003234444')),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.score5.withValues(alpha: 0.10),
                                border: Border.all(
                                    color:
                                        AppColors.score5.withValues(alpha: 0.20)),
                              ),
                              child: const Center(
                                child: Text('0800 323 4444',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.score5)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => launchUrl(Uri.parse('sms:85258?body=BLUE')),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.dimSleep.withValues(alpha: 0.10),
                                border: Border.all(
                                    color: AppColors.dimSleep
                                        .withValues(alpha: 0.20)),
                              ),
                              child: const Center(
                                child: Text('Text BLUE to 85258',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.dimSleep)),
                              ),
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
                    Text(tr('About this service', ref),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.rrT2)),
                    const SizedBox(height: 8),
                    Text(
                        tr('Your check-ins are synchronized with your unit welfare dashboard to monitor overall readiness. Personal data is managed in accordance with policy.', ref),
                        style: TextStyle(
                            fontSize: 13, color: context.rrT3, height: 1.6)),
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
