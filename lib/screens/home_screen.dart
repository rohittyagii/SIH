import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/animated_orbs.dart';
import '../providers/app_state.dart';
import '../data/translations.dart';

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
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider) ?? 'User';

    return Scaffold(
      backgroundColor: context.rrBg,
      body: Stack(
        children: [
          // Animated background
          const AnimatedOrbsBackground(),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 52, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tr(_greeting, ref)},',
                            style:
                                TextStyle(fontSize: 14, color: context.rrT4)),
                        const SizedBox(height: 2),
                        Text(userName,
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: context.rrT1,
                                letterSpacing: -0.01 * 32)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: Text(_todayLabel,
                                  style: TextStyle(
                                      fontSize: 13, color: context.rrT5),
                                  overflow: TextOverflow.ellipsis),
                            ),
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
                                  color:
                                      AppColors.indigo.withValues(alpha: 0.10),
                                  border: Border.all(
                                      color: AppColors.indigo
                                          .withValues(alpha: 0.20)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const IconFlame(
                                        size: 12, color: AppColors.indigo),
                                    const SizedBox(width: 4),
                                    Text('${tr('Day', ref)} $streak',
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
                  const Expanded(
                    child: Center(
                      child: _BreathingCircle(),
                    ),
                  ),
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
                                  ? tr('Checked in today', ref)
                                  : tr('Not yet checked in today', ref),
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
                                  ? tr("View today's entry", ref)
                                  : tr("Start today's check-in", ref),
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
                            _quickLink(context, tr('View my trend', ref),
                                AppColors.indigo, () => onTab(AppTab.trend)),
                            const SizedBox(height: 18),
                            _quickLink(context, tr('Resources & support', ref),
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

// ── Breathing Circle ────────────────────────────────────────────────────────
class _BreathingCircle extends ConsumerStatefulWidget {
  const _BreathingCircle();

  @override
  ConsumerState<_BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends ConsumerState<_BreathingCircle>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _breatheController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _breatheController.forward();
        }
      });
    _breatheController.forward();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breatheController, _rotateController]),
      builder: (context, child) {
        final scale =
            1.0 + (_breatheController.value * 0.6); // Scales from 1x to 1.6x
        final opacity = 0.05 + (_breatheController.value * 0.1);
        final isBreathingIn =
            _breatheController.status == AnimationStatus.forward ||
                _breatheController.status == AnimationStatus.dismissed;
        final time = _rotateController.value * 2 * math.pi;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulsating irregular ring
                Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: time,
                    child: CustomPaint(
                      size: const Size(140, 140),
                      painter: _IrregularCirclePainter(
                        color: AppColors.indigo.withValues(alpha: opacity),
                        isFilled: true,
                        time: time,
                      ),
                    ),
                  ),
                ),
                // Inner static irregular circle
                Transform.rotate(
                  angle: -time * 0.5,
                  child: CustomPaint(
                    size: const Size(140, 140),
                    painter: _IrregularCirclePainter(
                      color: AppColors.indigo.withValues(alpha: 0.3),
                      isFilled: false,
                      time: time * 1.5,
                    ),
                  ),
                ),
                // Text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    isBreathingIn
                        ? tr('Breathe in...', ref)
                        : tr('Breathe out...', ref),
                    key: ValueKey(isBreathingIn),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.indigo,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _IrregularCirclePainter extends CustomPainter {
  final Color color;
  final bool isFilled;
  final double time;

  _IrregularCirclePainter({
    required this.color,
    required this.isFilled,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    final path = Path();
    const int points = 180;

    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final theta = t * 2 * math.pi;

      // Map overlapping sine waves around the circumference
      final r = baseRadius +
          (baseRadius * 0.04) * math.sin(3 * theta + time * 2) +
          (baseRadius * 0.03) * math.cos(5 * theta - time) +
          (baseRadius * 0.02) * math.sin(7 * theta + time * 1.5);

      final x = center.dx + r * math.cos(theta);
      final y = center.dy + r * math.sin(theta);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _IrregularCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isFilled != isFilled ||
        oldDelegate.time != time;
  }
}
