import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/bottom_nav.dart';

// ── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onStartCheckin,
    required this.onTab,
    required this.todayDone,
    required this.streak,
  });
  final VoidCallback onStartCheckin;
  final ValueChanged<AppTab> onTab;
  final bool todayDone;
  final int streak;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _todayLabel {
    final now = DateTime.now();
    const days   = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.rrBg,
      body: Stack(
        children: [
          // Atmospheric glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.4),
                  radius: 1.1,
                  colors: [Color(0x17818CF8), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_greeting,',
                            style:
                                TextStyle(fontSize: 14, color: context.rrT4)),
                        const SizedBox(height: 2),
                        Text('Foxtrot-42',
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: context.rrT1,
                                letterSpacing: -0.01 * 32)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(_todayLabel,
                                style: TextStyle(
                                    fontSize: 13, color: context.rrT5)),
                            if (streak > 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.rrT7)),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: AppColors.indigo.withValues(alpha: 0.10),
                                  border: Border.all(
                                      color: AppColors.indigo
                                          .withValues(alpha: 0.20)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const IconFlame(size: 12, color: AppColors.indigo),
                                    const SizedBox(width: 4),
                                    Text('Day $streak',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.indigo)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // CTA section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        // Status dot
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    todayDone ? AppColors.score5 : context.rrT6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              todayDone
                                  ? 'Checked in today'
                                  : 'Not yet checked in today',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: todayDone
                                      ? const Color(0xFF3EC4A0)
                                      : context.rrT4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Check-in CTA button
                        GestureDetector(
                          onTap: onStartCheckin,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: todayDone
                                  ? const Color(0xFF3EC4A0)
                                      .withValues(alpha: 0.12)
                                  : AppColors.indigo,
                              border: todayDone
                                  ? Border.all(
                                      color: const Color(0xFF3EC4A0)
                                          .withValues(alpha: 0.25))
                                  : null,
                              boxShadow: todayDone
                                  ? []
                                  : [
                                      BoxShadow(
                                          color: AppColors.indigo
                                              .withValues(alpha: 0.34),
                                          blurRadius: 36,
                                          offset: const Offset(0, 6))
                                    ],
                            ),
                            child: Text(
                              todayDone
                                  ? "View today's entry"
                                  : "Start today's check-in",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: todayDone
                                    ? const Color(0xFF3EC4A0)
                                    : const Color(0xFF0C1220),
                                letterSpacing: -0.01 * 17,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Quick links
                        Column(
                          children: [
                            _quickLink(context, 'View my trend',
                                AppColors.indigo, () => onTab(AppTab.trend)),
                            const SizedBox(height: 18),
                            _quickLink(context, 'Resources & support',
                                context.rrT4, () => onTab(AppTab.support)),
                          ],
                        ),
                      ],
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

  Widget _quickLink(
      BuildContext context, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: color)),
          const SizedBox(width: 4),
          IconChevronRight(size: 13, color: color),
        ],
      ),
    );
  }
}
