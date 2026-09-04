import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/colors.dart';
import '../data/seed.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';

// ── ResourceList ─────────────────────────────────────────────────────────────
class _ResourceList extends StatelessWidget {
  const _ResourceList();

  @override
  Widget build(BuildContext context) {
    return RrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SUGGESTED FOR YOU',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.rrT6, letterSpacing: 0.10)),
          const SizedBox(height: 14),
          ...resources.asMap().entries.map((e) {
            final i = e.key;
            final r = e.value;
            return Column(
              children: [
                if (i > 0) Divider(color: context.rrDv, height: 24),
                Row(
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: r.color.withValues(alpha: 0.094),
                      ),
                      child: Center(child: _resourceIcon(r, context)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.rrT2)),
                          const SizedBox(height: 2),
                          Text(r.body, style: TextStyle(fontSize: 12, color: context.rrT3, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconChevronRight(size: 13, color: context.rrT6),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _resourceIcon(ResourceItem r, BuildContext context) {
    if (r.color == AppColors.dimSleep) return IconMoon(size: 14, color: r.color);
    if (r.color == AppColors.indigo)   return IconMessageCircle(size: 14, color: r.color);
    return IconTarget(size: 14, color: r.color);
  }
}

// ── TrendChart ────────────────────────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  const _TrendChart();

  @override
  Widget build(BuildContext context) {
    final data = buildThirtyDayData();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tickColor = isDark ? const Color(0xFF384C5E) : const Color(0xFF8898A8);
    final gridColor = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);

    return RrCard(
      padding: const EdgeInsets.fromLTRB(6, 16, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('30-DAY OVERVIEW',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.rrT6, letterSpacing: 0.10)),
                // Legend
                Row(
                  children: dims.map((d) => Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(
                      children: [
                        Container(width: 14, height: 2, decoration: BoxDecoration(borderRadius: BorderRadius.circular(1), color: dimColors[d.key])),
                        const SizedBox(width: 4),
                        Text(d.label.split(' ')[0], style: TextStyle(fontSize: 10, color: context.rrT4)),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          // Chart
          SizedBox(
            height: 172,
            child: LineChart(
              LineChartData(
                minX: 1, maxX: 30, minY: 1, maxY: 5,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 24,
                      getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: tickColor)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final label = chartXLabels[v.toInt()];
                        if (label == null) return const SizedBox.shrink();
                        return Text(label, style: TextStyle(fontSize: 10, color: tickColor));
                      },
                    ),
                  ),
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                      final dim = dims[s.barIndex];
                      final col = dimColors[dim.key]!;
                      return LineTooltipItem(
                        '${dim.label.split(' ')[0]}: ${s.y.toInt()}',
                        TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: dims.map((d) => LineChartBarData(
                  spots: data.map((p) => FlSpot(p.day.toDouble(), p.forKey(d.key))).toList(),
                  isCurved: true,
                  color: dimColors[d.key],
                  barWidth: 1.75,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 0, color: Colors.transparent, strokeWidth: 0, strokeColor: Colors.transparent,
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── TrendScreen ───────────────────────────────────────────────────────────────
class TrendScreen extends ConsumerWidget {
  const TrendScreen({super.key, required this.history});
  final List<Entry> history;

  double _avg(DimKey key) {
    if (history.isEmpty) return 0;
    return history.map((e) => e.score(key)).reduce((a, b) => a + b) / history.length;
  }

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
              // Heading row
              Text('My trend', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: context.rrT1)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Last 7 entries · 13-day streak',
                    style: TextStyle(fontSize: 13, color: context.rrT4)),
                  Row(
                    children: [
                      IconLock(size: 10, color: context.rrT7),
                      const SizedBox(width: 5),
                      Text('Visible only to you', style: TextStyle(fontSize: 11, color: context.rrT6)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 30-day chart
              const _TrendChart(),
              const SizedBox(height: 12),
              // 7-day averages
              RrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('7-day average',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.rrT6, letterSpacing: 0.06)),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 3.5,
                      children: dims.map((d) {
                        final a = _avg(d.key);
                        final col = scoreColor(a.round());
                        return Row(
                          children: [
                            dimIcon(d.key, size: 15, color: col),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(d.label, style: TextStyle(fontSize: 11, color: context.rrT4)),
                                Row(
                                  children: [
                                    Text(a.toStringAsFixed(1),
                                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: col, height: 1.1)),
                                    Text('/5', style: TextStyle(fontSize: 11, color: context.rrT6)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Suggested resources
              const _ResourceList(),
              const SizedBox(height: 12),
              // History list
              ...history.asMap().entries.map((e) {
                final entry = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RrCardSm(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              IconCalendar(size: 12, color: context.rrT4),
                              const SizedBox(width: 6),
                              Text(entry.date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.rrT2)),
                            ]),
                            Text(scoreLabel(entry.overall),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: scoreColor(entry.overall))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: dims.map((d) => Expanded(
                            child: Column(
                              children: [
                                dimIcon(d.key, size: 14, color: scoreColor(entry.score(d.key))),
                                const SizedBox(height: 6),
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: scoreColor(entry.score(d.key))),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                        if (entry.note.isNotEmpty) ...[
                          Divider(color: context.rrDv, height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(entry.note, style: TextStyle(fontSize: 12, color: context.rrT3, height: 1.6)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
