// Import necessary Flutter material package for building UI components
import 'package:flutter/material.dart';
// Import Riverpod for state management (accessing shared state/providers)
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import fl_chart package to draw charts (like the line chart used here)
import 'package:fl_chart/fl_chart.dart';
// Import intl package to format dates and times
import 'package:intl/intl.dart';
// Import url_launcher to open links (URLs) in the device's web browser
import 'package:url_launcher/url_launcher.dart';

// Import local project files for theme colors
import '../theme/colors.dart';
// Import sample or seed data (like history entries, resources)
import '../data/seed.dart';
// Import custom icon widgets used across the app
import '../widgets/icon_widgets.dart';
// Import a custom card widget used to display content blocks with standard styling
import '../widgets/rr_card.dart';
// Import app state providers (like historyProvider, streakProvider)
import '../providers/app_state.dart';
// Import a service for fetching device calendar events
import '../services/calendar_service.dart';
// Import translation utilities to handle multiple languages
import '../data/translations.dart';

// ── ResourceList ─────────────────────────────────────────────────────────────
// This widget displays a list of suggested resources (like articles or links) to the user.
// It extends ConsumerWidget, which means it can listen to Riverpod providers (though it only uses 'ref' for translations here).
class _ResourceList extends ConsumerWidget {
  // A constant constructor for performance optimization
  const _ResourceList();

  @override
  // The build method describes the part of the user interface represented by this widget
  Widget build(BuildContext context, WidgetRef ref) {
    // Return our custom card widget to wrap the content
    return RrCard(
      // A Column arranges its children vertically
      child: Column(
        // Align children to the start (left edge) of the column
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the section title "SUGGESTED FOR YOU"
          // 'tr' translates the string based on the current language
          Text(tr('SUGGESTED FOR YOU', ref),
            // Style the text with specific size, weight, color (using extension on context), and spacing
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.rrT6, letterSpacing: 0.10)),
          // Add some vertical space
          const SizedBox(height: 14),
          // Map over the list of resources to create a widget for each one
          // 'resources' comes from seed.dart. We use asMap().entries to get both the index (i) and the resource (r)
          ...resources.asMap().entries.map((e) {
            final i = e.key; // The index of the item
            final r = e.value; // The actual resource item
            return Column(
              children: [
                // If this is not the first item, add a divider line above it
                if (i > 0) Divider(color: context.rrDv, height: 24),
                // GestureDetector makes the row clickable
                GestureDetector(
                  // Action to perform when tapped
                  onTap: () async {
                    // Check if the resource has a URL
                    if (r.url != null) {
                      // Parse the string URL into a Uri object
                      final uri = Uri.parse(r.url!);
                      // Check if the device can open this URL
                      if (await canLaunchUrl(uri)) {
                        // Launch the URL (opens in a browser)
                        await launchUrl(uri);
                      }
                    }
                  },
                  // Make the entire area clickable, even empty spaces
                  behavior: HitTestBehavior.opaque,
                  // A Row arranges its children horizontally
                  child: Row(
                    children: [
                      // A container for the resource's icon
                      Container(
                        width: 34, height: 34, // Fixed size
                        decoration: BoxDecoration(
                          // Rounded corners
                          borderRadius: BorderRadius.circular(10),
                          // Background color derived from the resource's specific color with some transparency
                          color: r.color.withValues(alpha: 0.094),
                        ),
                        // Center the icon inside the container
                        child: Center(child: _resourceIcon(r, context)),
                      ),
                      // Space between the icon and text
                      const SizedBox(width: 12),
                      // Expanded makes this column take up all remaining horizontal space
                      Expanded(
                        child: Column(
                          // Align text to the left
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display the resource title, translated
                            Text(tr(r.title, ref), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.rrT2)),
                            // Small space between title and body
                            const SizedBox(height: 2),
                            // Display the resource body/description, translated
                            Text(tr(r.body, ref), style: TextStyle(fontSize: 12, color: context.rrT3, height: 1.4)),
                          ],
                        ),
                      ),
                      // Space before the chevron icon
                      const SizedBox(width: 8),
                      // A right-pointing arrow icon indicating it's clickable
                      IconChevronRight(size: 13, color: context.rrT6),
                    ],
                  ),
                ),
              ],
            );
          }), // End of mapping resources
        ],
      ),
    );
  }

  // A helper method to determine which icon to show based on the resource's color
  Widget _resourceIcon(ResourceItem r, BuildContext context) {
    // If the color matches the 'dimSleep' theme color, return a Moon icon
    if (r.color == AppColors.dimSleep) return IconMoon(size: 14, color: r.color);
    // If it matches indigo, return a Message Bubble icon
    if (r.color == AppColors.indigo)   return IconMessageCircle(size: 14, color: r.color);
    // Otherwise, return a Target icon as a default
    return IconTarget(size: 14, color: r.color);
  }
}

// ── BiometricsCard ────────────────────────────────────────────────────────────
// This widget displays simulated Heart Rate Variability (HRV) data
class _BiometricsCard extends ConsumerWidget {
  // Constant constructor
  const _BiometricsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simulated HRV data point wrapped in our custom card
    return RrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with title and an icon
          Row(
            // Spread items to opposite ends
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Display title, translated
              Text(tr('BIOMETRICS (SIMULATED)', ref),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.rrT6,
                      letterSpacing: 0.10)),
              // Activity/Heartbeat icon
              IconActivity(size: 14, color: context.rrT6),
            ],
          ),
          // Vertical spacing
          const SizedBox(height: 14),
          // Row for the actual data value and percentage change badge
          Row(
            // Align items to the bottom of the row
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // The main value (e.g., 48)
              const Text('48', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: AppColors.indigo, height: 1.0)),
              const SizedBox(width: 4),
              // The unit "ms" (milliseconds) with some padding to align properly
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('ms', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.rrT4)),
              ),
              // Spacer pushes the next widget to the far right
              const Spacer(),
              // A badge showing the percentage change against a baseline
              Container(
                // Internal padding for the badge
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  // Background color indicating state (e.g., green/red)
                  color: AppColors.score2.withValues(alpha: 0.15),
                  // Slightly rounded corners
                  borderRadius: BorderRadius.circular(6),
                ),
                // The text inside the badge
                child: const Text('HRV down 12% vs baseline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.score2)),
              ),
            ],
          ),
          // Vertical space
          const SizedBox(height: 8),
          // A descriptive text explaining where the data comes from
          Text('Heart Rate Variability (HRV) metrics are securely synced from your connected wearable device.',
              style: TextStyle(fontSize: 12, color: context.rrT4, height: 1.4)),
        ],
      ),
    );
  }
}

// ── TrendChart ────────────────────────────────────────────────────────────────
// A stateful widget that displays a line chart of trends over time
// It's a ConsumerStatefulWidget to listen to Riverpod state and hold its own local state
class _TrendChart extends ConsumerStatefulWidget {
  // Constructor requiring a target date and a boolean indicating if we are viewing a calendar month
  const _TrendChart({required this.targetDate, required this.isCalendarMonth});
  
  // The date around which to center or limit data
  final DateTime targetDate;
  // Whether we are looking at a specific calendar month vs a rolling 30-day window
  final bool isCalendarMonth;

  @override
  // Creates the state object for this widget
  ConsumerState<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends ConsumerState<_TrendChart> {
  // Holds the currently selected dimension (e.g., mood, sleep) to filter the chart
  // Null means "All" dimensions are shown
  DimKey? _selectedDim;

  // A helper function to calculate where on the X-axis a given entry date should go
  static double? dayOffset(String entryDate, DateTime targetDate, bool isCalendarMonth) {
    // Normalize target date to remove time (set to midnight)
    final today = DateTime(
        targetDate.year, targetDate.month, targetDate.day);
    // A map to convert month abbreviations to numbers
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    DateTime? date;

    // Try to parse the date if it's in ISO format like "2026-09-11"
    try {
      final parts = entryDate.split('-');
      if (parts.length == 3) {
        date = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {} // Ignore errors, we'll try another format if this fails

    // Try to parse the date if it's in a friendly format like "Thu, Sep 11"
    if (date == null) {
      try {
        // Remove commas
        final stripped = entryDate.replaceAll(',', '').trim();
        // Split by space
        final parts = stripped.split(' ');
        // Get the month and day parts (skip the day name if present)
        final dateParts = parts.length == 3 ? parts.sublist(1) : parts;
        // Lookup the month number
        final month = months[dateParts[0]];
        // Parse the day number
        final day = int.parse(dateParts[1]);
        if (month != null) {
          // Assume the current year initially
          date = DateTime(today.year, month, day);
          // Handle year boundaries: if the parsed date is in the future, it must be from last year
          // (e.g., reading a "Dec 31" entry in January)
          if (date.isAfter(today)) {
            date = DateTime(today.year - 1, month, day);
          }
        }
      } catch (_) {} // Ignore parsing errors
    }

    // If we still couldn't parse it, return null (skip this entry)
    if (date == null) return null;
    
    // Calculate position based on the view mode
    if (isCalendarMonth) {
      // In calendar mode, just use the day of the month as the X coordinate (1-31)
      if (date.year == targetDate.year && date.month == targetDate.month) {
        return date.day.toDouble();
      }
      return null; // Ignore dates outside this month
    } else {
      // In rolling 30-day mode, calculate how many days ago it was
      final daysAgo = today.difference(date).inDays;
      // If it's in the future or older than 29 days, ignore it
      if (daysAgo < 0 || daysAgo > 29) return null;
      // Map "29 days ago" to X=1, and "today" to X=30
      return (30 - daysAgo).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read the history data from the global state provider
    final history = ref.watch(historyProvider);
    // Check if the current theme is dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Set colors for chart grid and ticks based on theme
    final tickColor = isDark ? const Color(0xFF384C5E) : const Color(0xFF8898A8);
    final gridColor = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);

    // Build the labels for the X-axis (showing roughly weekly intervals)
    final today = widget.targetDate;
    final isCal = widget.isCalendarMonth;
    // Determine the max X value (days in the month or 30 days)
    final daysInMonth = isCal ? DateTime(today.year, today.month + 1, 0).day : 30;

    // A map holding the text labels to show at specific X coordinate values
    final Map<int, String> xLabels = {};
    const shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    if (isCal) {
      // Points where we want to show a label in calendar mode
      final labelOffsets = [1, 8, 15, 22, daysInMonth];
      for (final day in labelOffsets) {
        // Format label like "Sep 15"
        xLabels[day] = '${shortMonths[today.month - 1]} $day';
      }
    } else {
      // Points where we want to show a label in 30-day mode
      const labelOffsets = [2, 9, 16, 23, 30];
      for (final offset in labelOffsets) {
        // Calculate what date "offset" corresponds to
        final d = today.subtract(Duration(days: 30 - offset));
        xLabels[offset] = '${shortMonths[d.month - 1]} ${d.day}';
      }
    }

    // A helper function to create chart data points (FlSpots) for a specific dimension
    List<FlSpot> spotsFor(DimKey key) {
      final spots = <FlSpot>[];
      // Iterate through the history entries
      for (final entry in history) {
        // Find the X coordinate
        final x = dayOffset(entry.date, widget.targetDate, widget.isCalendarMonth);
        if (x != null) {
          // Add a point: X is the calculated day offset, Y is the score (1 to 5)
          spots.add(FlSpot(x, entry.score(key).toDouble()));
        }
      }
      // Sort points ascending by X coordinate so the chart lines connect left-to-right
      spots.sort((a, b) => a.x.compareTo(b.x));
      return spots;
    }

    // Check if we have any valid data to display
    final hasData = history.any((e) => dayOffset(e.date, widget.targetDate, widget.isCalendarMonth) != null);

    return RrCard(
      // Padding inside the chart card
      padding: const EdgeInsets.fromLTRB(6, 16, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section of the chart
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title (translating either 'MONTHLY OVERVIEW' or '30-DAY OVERVIEW')
                Text(tr(widget.isCalendarMonth ? 'MONTHLY OVERVIEW' : '30-DAY OVERVIEW', ref),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.rrT6, letterSpacing: 0.10)),
                const SizedBox(width: 8),
                // Legend Scroll Box: allows selecting a specific dimension line to view
                Expanded(
                  child: SingleChildScrollView(
                    // Scroll horizontally
                    scrollDirection: Axis.horizontal,
                    // Align content to the right if there's extra space
                    reverse: true, 
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "All" button
                        GestureDetector(
                          // Reset selection to null (show all)
                          onTap: () => setState(() => _selectedDim = null),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              // Highlight background if "All" is selected
                              color: _selectedDim == null ? (isDark ? Colors.white10 : Colors.black12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // Text style changes if selected
                            child: Text(tr('All', ref), style: TextStyle(fontSize: 10, fontWeight: _selectedDim == null ? FontWeight.w600 : FontWeight.normal, color: _selectedDim == null ? context.rrT2 : context.rrT4)),
                          ),
                        ),
                        // Buttons for each individual dimension (e.g., mood, sleep)
                        // 'dims' is a list of dimensions from seed.dart
                        ...dims.map((d) {
                          // Check if this specific dimension is currently selected
                          final isSelected = _selectedDim == d.key;
                          return GestureDetector(
                            // When tapped, update the selected dimension
                            onTap: () => setState(() => _selectedDim = d.key),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                // Tint background with dimension color if selected
                                color: isSelected ? dimColors[d.key]!.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Small colored dot for the legend
                                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: dimColors[d.key])),
                                  const SizedBox(width: 4),
                                  // Name of the dimension (only take the first word)
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
          // Body of the chart area
          // If there is no data for the selected period, show an empty state message
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  tr(widget.isCalendarMonth ? 'No check-in data for this month' : 'No check-in data in the last 30 days', ref),
                  style: TextStyle(fontSize: 12, color: context.rrT5),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          // If there is data, show the line chart
          else
            Padding(
              padding: const EdgeInsets.only(right: 18, left: 2),
              // Constrain the height of the chart
              child: SizedBox(
                height: 172,
                // FlChart widget for drawing line charts
                child: LineChart(
                  LineChartData(
                    // Set axis limits (X is days, Y is score 1-5)
                    minX: 1, maxX: daysInMonth.toDouble(), minY: 1, maxY: 5,
                    // Configure the background grid
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false, // Only show horizontal grid lines
                      horizontalInterval: 1, // Draw line at every integer Y value
                      // Function to draw the grid line with custom color
                      getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
                    ),
                    // Hide the border around the chart
                    borderData: FlBorderData(show: false),
                    // Configure axis labels (titles)
                    titlesData: FlTitlesData(
                      // Left axis (Y-axis: scores 1-5)
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1, // Label every 1 unit
                          reservedSize: 24, // Space allocated for labels
                          // Widget to render each Y label
                          getTitlesWidget: (v, meta) => SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            // Cast value to int and convert to string
                            child: Text(v.toInt().toString(),
                              style: TextStyle(fontSize: 10, color: tickColor)),
                          ),
                        ),
                      ),
                      // Bottom axis (X-axis: dates)
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1, // Evaluate every 1 unit (day)
                          reservedSize: 26,
                          // Widget to render each X label
                          getTitlesWidget: (v, meta) {
                            // Look up the pre-calculated label text
                            final label = xLabels[v.toInt()];
                            // If no label is meant for this day, return an empty widget
                            if (label == null) return const SizedBox.shrink();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 6,
                              // Display the label
                              child: Text(label, style: TextStyle(fontSize: 10, color: tickColor)),
                            );
                          },
                        ),
                      ),
                      // Hide top and right axes completely
                      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    // Setup tooltips when tapping on data points
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        // Create a tooltip item for each line (spot) at the touched X coordinate
                        getTooltipItems: (spots) => spots.map((s) {
                          // Find the dimension corresponding to this line
                          final dim = dims[s.barIndex];
                          final col = dimColors[dim.key]!;
                          // Return the tooltip text and style (e.g. "Mood: 4")
                          return LineTooltipItem(
                            '${tr(dim.label, ref).split(' ')[0]}: ${s.y.toInt()}',
                            TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.w600),
                          );
                        }).toList(),
                      ),
                    ),
                    // Configure the actual data lines to draw
                    lineBarsData: dims
                        // Filter dimensions based on whether "All" or a specific one is selected
                        .where((d) => _selectedDim == null || _selectedDim == d.key)
                        .map((d) {
                      // Get the points for this dimension
                      final spots = spotsFor(d.key);
                      return LineChartBarData(
                        spots: spots,
                        // Make line curvy if we have enough points, otherwise straight
                        isCurved: spots.length > 2,
                        preventCurveOverShooting: true,
                        // Set the line color based on dimension
                        color: dimColors[d.key],
                        barWidth: 1.75, // Line thickness
                        // Configure the dots drawn at each data point
                        dotData: FlDotData(
                          show: true,
                          // Draw circles for dots
                          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                            // Draw larger dot if there's only 1 point, so it's easier to see
                            radius: spots.length == 1 ? 3.0 : 2.0,
                            color: dimColors[d.key]!,
                            strokeWidth: 0,
                            strokeColor: Colors.transparent,
                          ),
                        ),
                      );
                    }).toList(), // Convert iterable back to a list
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
// A stateful widget to fetch and display upcoming calendar events from the user's device
class _DeviceCalendarCard extends ConsumerStatefulWidget {
  // Constant constructor
  const _DeviceCalendarCard();

  @override
  ConsumerState<_DeviceCalendarCard> createState() => _DeviceCalendarCardState();
}

class _DeviceCalendarCardState extends ConsumerState<_DeviceCalendarCard> {
  // Future that will hold the list of calendar events once fetched
  late Future<List<DeviceCalendarEvent>> _future;

  @override
  void initState() {
    super.initState();
    // Start fetching events for the next 30 days as soon as the widget initializes
    // We read the calendarServiceProvider to access the fetching logic
    _future = ref.read(calendarServiceProvider).fetchUpcomingEvents(days: 30);
  }

  @override
  Widget build(BuildContext context) {
    // Return a styled card
    return RrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and icon
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
          // FutureBuilder listens to a Future and rebuilds when its state changes
          FutureBuilder<List<DeviceCalendarEvent>>(
            future: _future,
            builder: (context, snap) {
              // If the future is still running, show a loading indicator
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      // A circular spinning loader
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: context.rrT6),
                    ),
                  ),
                );
              }
              // If the future failed or returned no events, show an empty/error message
              if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    // Show specific message if there was an error (likely permissions issue)
                    snap.hasError
                        ? 'Calendar access denied. Enable in Settings → Privacy.'
                        : 'No upcoming events in the next 30 days.',
                    style: TextStyle(fontSize: 12, color: context.rrT5, height: 1.5),
                  ),
                );
              }
              // The future succeeded and we have events
              final events = snap.data!;
              // Build a column of event items
              return Column(
                // Map over the events list, keeping track of the index
                children: events.asMap().entries.map((e) {
                  final i  = e.key;
                  final ev = e.value;
                  // Format the event date, e.g., "Mon, 5 Sep"
                  final dateLabel = DateFormat('EEE, d MMM').format(ev.date);
                  return Column(
                    children: [
                      // Add a divider between events, but not above the first one
                      if (i > 0) Divider(color: context.rrDv, height: 20),
                      // Row displaying single event details
                      Row(
                        children: [
                          // A box wrapping the calendar icon
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              // Soft indigo background
                              color: AppColors.indigo.withValues(alpha: 0.08),
                            ),
                            child: const Center(
                              child: IconCalendar(size: 14, color: AppColors.indigo),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Expanded widget contains title and date/time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Event title
                                Text(ev.title,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: context.rrT2),
                                    // Restrict to one line, adding '...' if too long
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                // Subtitle combining formatted date and start time
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
                }).toList(), // Convert back to list for Column.children
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── TrendScreen ───────────────────────────────────────────────────────────────
// This is the main screen widget for showing trends and stats.
// It receives the user's check-in history as a parameter.
class TrendScreen extends ConsumerStatefulWidget {
  // Constructor requires the list of entries (history)
  const TrendScreen({super.key, required this.history});
  // List holding the data entries
  final List<Entry> history;

  @override
  ConsumerState<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends ConsumerState<TrendScreen> {
  // State variable tracking which time period is selected in the dropdown
  String _selectedPeriod = 'Last 30 days';
  // List of available periods (e.g., 'Last 30 days', 'September 2026')
  late final List<String> _periods;

  @override
  void initState() {
    super.initState();
    // Initialize the list of periods based on the current date
    final now = DateTime.now();
    // The first option is always rolling 30 days
    _periods = ['Last 30 days'];
    // Full names of months to build historical options
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    // Generate options for the last 12 months
    for (int i = 0; i < 12; i++) {
      // Calculate month by subtracting i from current month
      int month = now.month - i;
      int year = now.year;
      // If we go past January (month <= 0), subtract a year and reset month count
      while (month <= 0) {
        month += 12;
        year -= 1;
      }
      // Add formatted string like "September 2026"
      _periods.add('${months[month - 1]} $year');
    }
  }

  // A getter that calculates the reference date for the currently selected period
  DateTime get _targetDate {
    final now = DateTime.now();
    // If 'Last 30 days', the target is today
    if (_selectedPeriod == 'Last 30 days') return now;
    
    // Otherwise, parse the month and year from the selected string
    final parts = _selectedPeriod.split(' ');
    if (parts.length == 2) {
      // Map names to numbers
      const months = {'January': 1, 'February': 2, 'March': 3, 'April': 4, 'May': 5, 'June': 6, 'July': 7, 'August': 8, 'September': 9, 'October': 10, 'November': 11, 'December': 12};
      final month = months[parts[0]];
      final year = int.tryParse(parts[1]);
      if (month != null && year != null) {
        // Return the last day of that month by setting day to 0 of the next month
        return DateTime(year, month + 1, 0); 
      }
    }
    // Default fallback
    return now;
  }

  // A helper function to compute the average score for a specific dimension (e.g., mood) across the history
  double _avg(DimKey key) {
    if (widget.history.isEmpty) return 0;
    // Map each entry to its score for this dimension, sum them up, and divide by total entries
    return widget.history.map((e) => e.score(key)).reduce((a, b) => a + b) / widget.history.length;
  }

  // A helper function to build the UI cell showing an average score
  Widget _buildAvgCell(BuildContext context, WidgetRef ref, dynamic d) {
    // Calculate the average for dimension d
    final a   = _avg(d.key);
    // Get a color mapped to the rounded average value
    final col = scoreColor(a.round());
    return Row(
      children: [
        // Display an icon for the dimension, colored accordingly
        dimIcon(d.key, size: 15, color: col),
        const SizedBox(width: 10),
        // Column for text labels
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dimension label, translated (e.g., "Mood")
            Text(tr(d.label, ref),
                style: TextStyle(fontSize: 11, color: context.rrT4)),
            // Row for the actual score and max possible score
            Row(
              children: [
                // Format average to 1 decimal place
                Text(a.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: col,
                        height: 1.1)),
                // Show max score "/5"
                Text('/5',
                    style: TextStyle(fontSize: 11, color: context.rrT6)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the current user streak from Riverpod provider
    final streak = ref.watch(streakProvider);
    // Determine if we are looking at a full calendar month or just the rolling 30 days
    final isCalendarMonth = _selectedPeriod != 'Last 30 days';
    
    // Filter the full history to only include entries that belong in the selected time period
    final filteredHistory = widget.history.where((e) => _TrendChartState.dayOffset(e.date, _targetDate, isCalendarMonth) != null).toList();

    // The main layout wrapper
    return Scaffold(
      // Set screen background color
      backgroundColor: context.rrBg,
      // Enables vertical scrolling
      body: SingleChildScrollView(
        // Add padding around content. Include safe area at the top to avoid phone notch/status bar
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 24, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Heading row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Main screen title
                  Text(tr('My trend', ref),
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600, color: context.rrT1)),
                  // A dropdown menu allowing users to change the selected period
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    dropdownColor: context.rrBgc,
                    borderRadius: BorderRadius.circular(16),
                    menuMaxHeight: 300, // Max height of dropdown list
                    underline: const SizedBox(), // Remove the default underline
                    icon: Icon(Icons.keyboard_arrow_down, color: context.rrT4),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.rrT3),
                    // Map the string periods to DropdownMenuItem widgets
                    items: _periods.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    // Callback when a new item is selected
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        // Call setState to trigger a UI rebuild with the new period
                        setState(() {
                          _selectedPeriod = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // ── Subtitle row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      // If the user has a streak > 0, display it. Otherwise, just say "Last 7 entries"
                      streak > 0
                          ? '${tr('Last 7 entries', ref)} · $streak-day streak'
                          : tr('Last 7 entries', ref),
                      style: TextStyle(fontSize: 13, color: context.rrT4),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Small indicator showing data is private
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
              
              // ── 30-day or Monthly Chart widget ──
              // Pass down the current target date and view mode
              _TrendChart(targetDate: _targetDate, isCalendarMonth: isCalendarMonth),
              const SizedBox(height: 12),
              
              // ── 7-day averages ──
              // A card displaying the calculated averages for each dimension
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
                    Column(
                      children: [
                        // First row for the first two dimensions
                        Row(
                          children: [
                            Expanded(child: _buildAvgCell(context, ref, dims[0])),
                            const SizedBox(width: 12),
                            Expanded(child: _buildAvgCell(context, ref, dims[1])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Second row for the next two dimensions
                        Row(
                          children: [
                            Expanded(child: _buildAvgCell(context, ref, dims[2])),
                            const SizedBox(width: 12),
                            Expanded(child: _buildAvgCell(context, ref, dims[3])),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // ── Biometrics (HRV) Card ──
              const _BiometricsCard(),
              const SizedBox(height: 12),
              
              // ── Device calendar events Card ──
              const _DeviceCalendarCard(),
              const SizedBox(height: 12),
              
              // ── Suggested resources List ──
              const _ResourceList(),
              const SizedBox(height: 12),
              
              // ── History list ──
              // Display each individual check-in entry for the selected time period
              ...filteredHistory.asMap().entries.map((e) {
                final entry = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  // A slightly smaller version of the standard card
                  child: RrCardSm(
                    child: Column(
                      children: [
                        // Row: Date on the left, Overall score label on the right
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
                                    // Color the text based on the score value
                                    color: scoreColor(entry.overall))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row showing dots and icons for each of the specific dimension scores in this entry
                        Row(
                          children: dims.map((d) => Expanded(
                            child: Column(
                              children: [
                                // Icon for the specific dimension colored based on score
                                dimIcon(d.key,
                                    size: 14,
                                    color: scoreColor(entry.score(d.key))),
                                const SizedBox(height: 6),
                                // A small colored dot below the icon
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
                        // If the user added a personal note for this entry, show it here
                        if (entry.note.isNotEmpty) ...[
                          // Separator line
                          Divider(color: context.rrDv, height: 24),
                          // The actual note text
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
              }), // End mapping over filtered history
            ],
          ),
        ),
    );
  }
}
