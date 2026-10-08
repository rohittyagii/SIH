import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../widgets/icon_widgets.dart';
import '../data/translations.dart';
import '../providers/app_state.dart';

import '../widgets/bouncy_button.dart';

// ── Tab definition ─────────────────────────────────────────────────────────
enum AppTab { home, trend, support, settings }

// ── BottomNav ───────────────────────────────────────────────────────────────
class BottomNav extends ConsumerWidget {
  const BottomNav({super.key, required this.active, required this.onTab});
  final AppTab active;
  final ValueChanged<AppTab> onTab;

  static const _tabs = [
    (tab: AppTab.home,     label: 'Home',     icon: IconHome.new),
    (tab: AppTab.trend,    label: 'Trend',    icon: IconTrend.new),
    (tab: AppTab.support,  label: 'Support',  icon: IconMessageCircle.new),
    (tab: AppTab.settings, label: 'Settings', icon: IconSliders.new),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use the deepest background color so it stands out against the lighter cards
    final bgColor = context.rrBgd; 

    final bottomPadding = MediaQuery.of(context).padding.bottom > 0
        ? MediaQuery.of(context).padding.bottom - 12 // Drop it lower than safe area
        : 16.0;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomPadding),
      child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark ? context.rrDv : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              void handleDrag(double x) {
                final width = constraints.maxWidth;
                final segment = width / 5;
                final index = (x / segment).floor().clamp(0, 4);
                if (index == 0) onTab(AppTab.home);
                if (index == 1) onTab(AppTab.trend);
                // index 2 is the check-in button, skip triggering during drag
                if (index == 3) onTab(AppTab.support);
                if (index == 4) onTab(AppTab.settings);
              }

              return GestureDetector(
                onPanDown: (d) => handleDrag(d.localPosition.dx),
                onPanUpdate: (d) => handleDrag(d.localPosition.dx),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTab(context, ref, _tabs[0]),
                    _buildTab(context, ref, _tabs[1]),
                    _buildCheckinButton(context, ref),
                    _buildTab(context, ref, _tabs[2]),
                    _buildTab(context, ref, _tabs[3]),
                  ],
                ),
              );
            },
          ),
        ),
    );
  }

  Widget _buildCheckinButton(BuildContext context, WidgetRef ref) {
    return BouncyButton(
      onTap: () {
        final todayDone = ref.read(todayDoneProvider);
        if (todayDone) {
          ref.read(submittedProvider.notifier).state = true;
        } else {
          ref.read(scoresProvider.notifier).state = emptyScores();
          ref.read(noteProvider.notifier).state = '';
          ref.read(inCheckinProvider.notifier).state = true;
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.indigo,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.indigo.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, WidgetRef ref, dynamic t) {
    final isActive = active == t.tab;
    final color = isActive ? AppColors.indigo : context.rrT6;
    
    return GestureDetector(
      onTap: () => onTab(t.tab),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56, // Fixed width for consistent spacing
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: const ElasticOutCurve(0.7), // Dramatic bounce
              transform: Matrix4.identity()
                ..translateByDouble(0.0, isActive ? -4.0 : 0.0, 0.0, 1.0) // Move up slightly
                ..scaleByDouble(isActive ? 1.35 : 1.0, isActive ? 1.35 : 1.0, isActive ? 1.35 : 1.0, 1.0), // Large scale
              transformAlignment: Alignment.center,
              child: t.icon(size: 24.0, color: color),
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isActive ? 1.0 : 0.4,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: isActive ? 11 : 9, 
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, 
                  color: color,
                  fontFamily: 'Outfit',
                ),
                child: Text(tr(t.label, ref), maxLines: 1, overflow: TextOverflow.visible),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


