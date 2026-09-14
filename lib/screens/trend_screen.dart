import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../data/seed.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';
import '../providers/app_state.dart';
import '../services/calendar_service.dart';
import '../data/translations.dart';

// ── ResourceList ─────────────────────────────────────────────────────────────
class _ResourceList extends ConsumerWidget {
  const _ResourceList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('SUGGESTED FOR YOU', ref),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.rrT6, letterSpacing: 0.10)),
          const SizedBox(height: 14),
          ...resources.asMap().entries.map((e) {
            final i = e.key;
            final r = e.value;
            return Column(
              children: [
                if (i > 0) Divider(color: context.rrDv, height: 24),
                GestureDetector(
                  onTap: () async {
                    if (r.url != null) {
                      final uri = Uri.parse(r.url!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
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
                            Text(tr(r.title, ref), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.rrT2)),
                            const SizedBox(height: 2),
                            Text(tr(r.body, ref), style: TextStyle(fontSize: 12, color: context.rrT3, height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconChevronRight(size: 13, color: context.rrT6),
                    ],
                  ),
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

// ── BiometricsCard ────────────────────────────────────────────────────────────
class _BiometricsCard extends ConsumerWidget {
  const _BiometricsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simulated HRV data point
    return RrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('BIOMETRICS (SIMULATED)', ref),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.rrT6,
                      letterSpacing: 0.10)),
              IconActivity(size: 14, color: context.rrT6),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('48', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: AppColors.indigo, height: 1.0)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('ms', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.rrT4)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.score2.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('HRV down 12% vs baseline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.score2)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Heart Rate Variability (HRV) metrics are securely synced from your connected wearable device.',
              style: TextStyle(fontSize: 12, color: context.rrT4, height: 1.4)),
        ],
      ),
    );
  }
}

// ── TrendChart ────────────────────────────────────────────────────────────────
class _TrendChart extends ConsumerStatefulWidget {
  const _TrendChart();

  @override
  ConsumerState<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends ConsumerState<_TrendChart> {
  DimKey? _selectedDim;

  /// Converts an [Entry.date] string to an x-axis value 1–30 where
  /// 30 = today and 1 = 30 days ago. Returns null if out of window or unparseable.
  static double? _dayOffset(String entryDate) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    DateTime? date;

    // ISO: "2026-09-11"
    try {
      final parts = entryDate.split('-');
      if (parts.length == 3) {
        date = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}

    // Friendly: "Thu, Sep 11"
    if (date == null) {
      try {
        final stripped = entryDate.replaceAll(',', '').trim();
        final parts = stripped.split(' ');
        final dateParts = parts.length == 3 ? parts.sublist(1) : parts;
        final month = months[dateParts[0]];
        final day = int.parse(dateParts[1]);
        if (month != null) {
          date = DateTime(today.year, month, day);
          // Handle year boundary (e.g. Dec entry in a Jan context)
          if (date.isAfter(today)) {
            date = DateTime(today.year - 1, month, day);
          }
        }
      } catch (_) {}
    }

    if (date == null) return null;
    final daysAgo = today.difference(date).inDays;
    if (daysAgo < 0 || daysAgo > 29) return null;
    // x = 30 means today, x = 1 means 29 days ago
    return (30 - daysAgo).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tickColor = isDark ? const Color(0xFF384C5E) : const Color(0xFF8898A8);
    final gridColor = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);

    // Build x-label map: show labels at roughly weekly intervals
    final today = DateTime.now();
    final Map<int, String> xLabels = {};
    const labelOffsets = [2, 9, 16, 23, 30];
    const shortMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    for (final offset in labelOffsets) {
      final d = today.subtract(Duration(days: 30 - offset));
      xLabels[offset] = '${shortMonths[d.month - 1]} ${d.day}';
    }

    // Build spots per dimension from real history only
    List<FlSpot> spotsFor(DimKey key) {
      final spots = <FlSpot>[];
      for (final entry in history) {
        final x = _dayOffset(entry.date);
        if (x != null) {
          spots.add(FlSpot(x, entry.score(key).toDouble()));
        }
      }
      // Sort ascending by x so the line connects correctly
      spots.sort((a, b) => a.x.compareTo(b.x));
      return spots;
    }

    final hasData = history.any((e) => _dayOffset(e.date) != null);

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
                Text(tr('30-DAY OVERVIEW', ref),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.rrT6, letterSpacing: 0.10)),
                const SizedBox(width: 8),
                // Legend Scroll Box
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // Align content to the right if it doesn't overflow
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedDim = null),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _selectedDim == null ? (isDark ? Colors.white10 : Colors.black12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(tr('All', ref), style: TextStyle(fontSize: 10, fontWeight: _selectedDim == null ? FontWeight.w600 : FontWeight.normal, color: _selectedDim == null ? context.rrT2 : context.rrT4)),
                          ),
                        ),
                        ...dims.map((d) {
                          final isSelected = _selectedDim == d.key;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDim = d.key),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? dimColors[d.key]!.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: dimColors[d.key])),
                                  const SizedBox(width: 4),
                                  Text(tr(d.label, ref).split(' ')[0], style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? dimColors[d.key] : context.rrT4)),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chart or empty state
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  tr('No check-in data in the last 30 days', ref),
                  style: TextStyle(fontSize: 12, color: context.rrT5),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 18, left: 2),
              child: SizedBox(
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
                          getTitlesWidget: (v, meta) => SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(v.toInt().toString(),
                              style: TextStyle(fontSize: 10, color: tickColor)),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 26,
                          getTitlesWidget: (v, meta) {
                            final label = xLabels[v.toInt()];
                            if (label == null) return const SizedBox.shrink();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 6,
                              child: Text(label, style: TextStyle(fontSize: 10, color: tickColor)),
                            );
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
                            '${tr(dim.label, ref).split(' ')[0]}: ${s.y.toInt()}',
                            TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.w600),
                          );
                        }).toList(),
                      ),
                    ),
                    lineBarsData: dims
                        .where((d) => _selectedDim == null || _selectedDim == d.key)
                        .map((d) {
                      final spots = spotsFor(d.key);
                      return LineChartBarData(
                        spots: spots,
                        isCurved: spots.length > 2,
                        preventCurveOverShooting: true,
                        color: dimColors[d.key],
                        barWidth: 1.75,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                            radius: spots.length == 1 ? 3.0 : 2.0,
                            color: dimColors[d.key]!,
                            strokeWidth: 0,
                            strokeColor: Colors.transparent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// ── Device calendar card ─────────────────────────────────────────────────────
class _DeviceCalendarCard extends ConsumerStatefulWidget {
  const _DeviceCalendarCard();

  @override
  ConsumerState<_DeviceCalendarCard> createState() => _DeviceCalendarCardState();
}

class _DeviceCalendarCardState extends ConsumerState<_DeviceCalendarCard> {
  late Future<List<DeviceCalendarEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(calendarServiceProvider).fetchUpcomingEvents(days: 30);
  }

  @override
  Widget build(BuildContext context) {
    return RrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('UPCOMING CALENDAR', ref),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.rrT6,
                      letterSpacing: 0.10)),
              IconCalendar(size: 12, color: context.rrT6),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<DeviceCalendarEvent>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: context.rrT6),
                    ),
                  ),
                );
              }
              if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    snap.hasError
                        ? 'Calendar access denied. Enable in Settings → Privacy.'
                        : 'No upcoming events in the next 30 days.',
                    style: TextStyle(fontSize: 12, color: context.rrT5, height: 1.5),
                  ),
                );
              }
              final events = snap.data!;
              return Column(
                children: events.asMap().entries.map((e) {
                  final i  = e.key;
                  final ev = e.value;
                  final dateLabel = DateFormat('EEE, d MMM').format(ev.date);
                  return Column(
                    children: [
                      if (i > 0) Divider(color: context.rrDv, height: 20),
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              color: AppColors.indigo.withValues(alpha: 0.08),
                            ),
                            child: const Center(
                              child: IconCalendar(size: 14, color: AppColors.indigo),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ev.title,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: context.rrT2),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('$dateLabel · ${ev.startTime}',
                                    style: TextStyle(
                                        fontSize: 11, color: context.rrT5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              );
            },
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
    final streak = ref.watch(streakProvider);

    return Scaffold(
      backgroundColor: context.rrBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading row
              Text(tr('My trend', ref),
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600, color: context.rrT1)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      streak > 0
                          ? '${tr('Last 7 entries', ref)} · $streak-day streak'
                          : tr('Last 7 entries', ref),
                      style: TextStyle(fontSize: 13, color: context.rrT4),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconLock(size: 10, color: context.rrT7),
                      const SizedBox(width: 5),
                      Text(tr('Visible only to you', ref),
                          style: TextStyle(fontSize: 11, color: context.rrT6)),
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
                    Text(tr('7-day average', ref),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.rrT6,
                            letterSpacing: 0.06)),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 3.5,
                      children: dims.map((d) {
                        final a   = _avg(d.key);
                        final col = scoreColor(a.round());
                        return Row(
                          children: [
                            dimIcon(d.key, size: 15, color: col),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(tr(d.label, ref),
                                    style: TextStyle(fontSize: 11, color: context.rrT4)),
                                Row(
                                  children: [
                                    Text(a.toStringAsFixed(1),
                                        style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w600,
                                            color: col,
                                            height: 1.1)),
                                    Text('/5',
                                        style: TextStyle(
                                            fontSize: 11, color: context.rrT6)),
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
              // Biometrics (HRV)
              const _BiometricsCard(),
              const SizedBox(height: 12),
              // Device calendar events
              const _DeviceCalendarCard(),
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
                              Text(entry.date,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: context.rrT2)),
                            ]),
                            Text(tr(scoreLabel(entry.overall), ref),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: scoreColor(entry.overall))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: dims.map((d) => Expanded(
                            child: Column(
                              children: [
                                dimIcon(d.key,
                                    size: 14,
                                    color: scoreColor(entry.score(d.key))),
                                const SizedBox(height: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: scoreColor(entry.score(d.key))),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                        if (entry.note.isNotEmpty) ...[
                          Divider(color: context.rrDv, height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(entry.note,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: context.rrT3,
                                    height: 1.6)),
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
