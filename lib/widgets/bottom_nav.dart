import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/icon_widgets.dart';

// ── Tab definition ─────────────────────────────────────────────────────────
enum AppTab { home, trend, support, settings }

// ── BottomNav ───────────────────────────────────────────────────────────────
class BottomNav extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.rrBgn,
        border: Border(top: BorderSide(color: context.rrDv2, width: 1)),
      ),
      child: Row(
        children: _tabs.map((t) {
          final isActive = active == t.tab;
          final color = isActive ? AppColors.indigo : context.rrT6;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTab(t.tab),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    t.icon(size: 20, color: color),
                    const SizedBox(height: 3),
                    Text(t.label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
