// Import the Riverpod package, which is a state management library used to handle application state.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import the seed data file which contains some dummy data to populate the history initially.
import '../data/seed.dart';
// Import the bottom navigation widget to get access to the AppTab enum.
import '../widgets/bottom_nav.dart';

// ── App screens (top-level navigation) ────────────────────────────────────
// Define an enumeration (enum) called AppScreen to list all the top-level screens in the app.
// - pin: The PIN entry screen.
// - activation: The account activation screen.
// - consent: The user consent/agreement screen.
// - app: The main app screen.
enum AppScreen { pin, activation, consent, app }

// ── Theme provider ─────────────────────────────────────────────────────────
// Create a StateProvider for managing the app's theme.
// StateProvider allows us to read and update a simple value.
// Here, a boolean is used where 'false' means light mode and 'true' means dark mode.
final themeProvider = StateProvider<bool>((ref) => false); // false = light

// ── Active screen provider ─────────────────────────────────────────────────
// Create a StateProvider to keep track of which top-level screen is currently active.
// It initializes with AppScreen.pin, meaning the app starts on the PIN screen.
final screenProvider = StateProvider<AppScreen>((ref) => AppScreen.pin);

// ── Active bottom-tab provider ─────────────────────────────────────────────
// Create a StateProvider to track the currently selected tab in the bottom navigation bar.
// It defaults to the 'home' tab from the AppTab enum.
final tabProvider = StateProvider<AppTab>((ref) => AppTab.home);

// ── Check-in state ─────────────────────────────────────────────────────────
// Create a StateProvider to track if the user is currently in the middle of a daily check-in process.
final inCheckinProvider = StateProvider<bool>((ref) => false);
// Create a StateProvider to track if the check-in has been submitted successfully.
final submittedProvider = StateProvider<bool>((ref) => false);
// Create a StateProvider to track if the user has already completed their check-in for today.
final todayDoneProvider = StateProvider<bool>((ref) => false);
// Create a StateProvider to store the text note added by the user during the check-in.
final noteProvider = StateProvider<String>((ref) => '');
// Create a StateProvider to store the user's name. It can be null initially.
final userNameProvider = StateProvider<String?>((ref) => null);
// Create a StateProvider to store the user's preferred language. Defaults to British English ('en-GB').
final languagePrefProvider = StateProvider<String>((ref) => 'en-GB');

// Create a StateProvider to store a map of scores for different dimensions (like sleep, focus, etc.).
// It initializes all dimensions with a score of 0.
final scoresProvider = StateProvider<Map<DimKey, int>>((ref) => {
      // The overall well-being score.
      DimKey.overall: 0,
      // The score representing sleep quality.
      DimKey.sleep: 0,
      // The score representing physical activity/feeling.
      DimKey.physical: 0,
      // The score representing focus and mental clarity.
      DimKey.focus: 0,
    });

// ── History provider ────────────────────────────────────────────────────────
// Create a StateProvider to manage the list of historical check-in entries.
// It initializes the list with the dummy data from 'seedHistory'.
final historyProvider =
    StateProvider<List<Entry>>((ref) => List.from(seedHistory));

// ── Streak provider — consecutive daily check-ins counting back from today ──
// Create a Provider to calculate the user's current check-in streak.
// A regular Provider is used instead of StateProvider because its value is derived from other providers (historyProvider),
// meaning it automatically updates whenever the history changes.
final streakProvider = Provider<int>((ref) {
  // Watch the historyProvider so that streak is recalculated when history updates.
  final history = ref.watch(historyProvider);
  // If there are no entries in the history, the streak is 0.
  if (history.isEmpty) return 0;

  // Initialize the streak count to 0.
  int streak = 0;
  // Get the current date and time.
  var cursor = DateTime.now();
  // Strip the time portion to only keep the date (year, month, day) for accurate comparison.
  cursor = DateTime(cursor.year, cursor.month, cursor.day);

  // Loop through each entry in the history list.
  // The list is assumed to be ordered from newest to oldest.
  for (final entry in history) {
    // Attempt to parse the date string from the entry into a DateTime object.
    final entryDate = _parseEntryDate(entry.date);
    // If parsing fails, stop the streak calculation.
    if (entryDate == null) break;
    // Calculate the difference in days between the expected date (cursor) and the entry's date.
    final diff = cursor.difference(entryDate).inDays;
    
    // If the difference is 0 (the entry matches the expected date) or equals the current streak,
    // it means the streak continues.
    if (diff == 0 || diff == streak) {
      // Increment the streak count.
      streak++;
      // Move the expected date (cursor) back by one day for the next iteration.
      cursor = entryDate.subtract(const Duration(days: 1));
    } else {
      // If there is a gap in the dates, the consecutive streak is broken.
      break;
    }
  }
  // Return the calculated streak.
  return streak;
});

/// A helper function that tries to parse entry date strings which might come in multiple formats.
/// Returns a DateTime object if successful, or null if it cannot parse the date.
DateTime? _parseEntryDate(String raw) {
  // First, try parsing the ISO format like "2026-09-04".
  try {
    // Split the date string by hyphens.
    final parts = raw.split('-');
    // If we have exactly 3 parts (year, month, day), try to create a DateTime.
    if (parts.length == 3) {
      return DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }
  } catch (_) {} // Ignore any errors and fall through to the next format.
  
  // Next, try parsing a friendly format like "Wed, Sep 3".
  // Define a map that converts month abbreviations to their numeric values.
  const months = {
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };
  try {
    // Remove commas from the string and trim whitespace from the ends.
    final stripped = raw.replaceAll(',', '').trim();
    // Split the cleaned string by spaces.
    final parts = stripped.split(' ');
    // If the string included the weekday (e.g., "Wed Sep 3"), grab just the month and day.
    // Otherwise, assume it just has month and day (e.g., "Sep 3").
    final dateParts = parts.length == 3 ? parts.sublist(1) : parts;
    // Look up the month number from our map.
    final month = months[dateParts[0]];
    // Parse the day number.
    final day = int.parse(dateParts[1]);
    // If the month wasn't found in our map, return null.
    if (month == null) return null;
    // Return the new DateTime using the current year (assuming entries belong to the current year).
    return DateTime(DateTime.now().year, month, day);
  } catch (_) {
    // If both parsing attempts fail, return null indicating the date couldn't be parsed.
    return null;
  }
}

// ── Actions ─────────────────────────────────────────────────────────────────

/// A helper function to create and return a map of empty/initial scores.
/// This is useful when resetting the check-in form.
Map<DimKey, int> emptyScores() => {
      // Set the overall score back to 0.
      DimKey.overall: 0,
      // Set the sleep score back to 0.
      DimKey.sleep: 0,
      // Set the physical score back to 0.
      DimKey.physical: 0,
      // Set the focus score back to 0.
      DimKey.focus: 0,
    };

/// A function to build a new check-in `Entry` stamped with today's real date.
/// Takes the recorded scores and any written note as arguments.
Entry buildEntry(Map<DimKey, int> scores, String note) {
  // Get the current exact date and time.
  final now = DateTime.now();
  // A list of weekday abbreviations to format the date string.
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  // A list of month abbreviations to format the date string.
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
  
  // Format the label as "DayOfWeek, Month Day" (e.g., "Wed, Sep 3").
  // We use `- 1` because DateTime weekday and month are 1-indexed (1-7 and 1-12),
  // but Dart lists are 0-indexed.
  final label = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  
  // Return a new Entry object populated with the formatted date, scores, and note.
  return Entry(
    // The formatted date string.
    date: label,
    // Extract the overall score. The `!` asserts that the key exists in the map.
    overall: scores[DimKey.overall]!,
    // Extract the sleep score.
    sleep: scores[DimKey.sleep]!,
    // Extract the physical score.
    physical: scores[DimKey.physical]!,
    // Extract the focus score.
    focus: scores[DimKey.focus]!,
    // Include the note written by the user.
    note: note,
  );
}
