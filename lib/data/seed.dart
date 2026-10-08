// Importing the flutter material package to get access to UI components and colors like 'Color'.
import 'package:flutter/material.dart';
// Importing a custom file that holds the application's specific color themes.
import '../theme/colors.dart';

// ── Score helper functions ─────────────────────────────────────────────────

// A helper function that takes an integer 'n' (representing a score) and returns a specific Color.
// It clamps 'n' to be within the range of 1 to 5. Then it subtracts 1 to use as a 0-based index for the 'scoreColors' list.
Color scoreColor(int n) => AppColors.scoreColors[(n.clamp(1, 5) - 1)];

// A helper function similar to 'scoreColor', but this one returns a 'glow' color (usually partially transparent).
// It also ensures 'n' is between 1 and 5, then converts it to a 0-based index.
Color scoreGlow(int n) => AppColors.scoreGlows[(n.clamp(1, 5) - 1)];

// A helper function that returns a descriptive string label based on a numerical score 'n'.
String scoreLabel(int n) {
  // A constant list of text labels describing different readiness levels, from lowest to highest.
  const labels = ['Not ready', 'Low', 'Moderate', 'Good', 'Fully ready'];
  // We clamp 'n' to ensure it's between 1 and 5, then subtract 1 to get an index from 0 to 4.
  final i = n.clamp(1, 5) - 1;
  // Return the label at the calculated index.
  return labels[i];
}

// ── Models ─────────────────────────────────────────────────────────────────

// An enumeration (enum) representing different dimensions or categories of wellness/readiness.
enum DimKey { 
  // Represents overall readiness or well-being.
  overall, 
  // Represents the quality or duration of sleep.
  sleep, 
  // Represents physical health or limitations.
  physical, 
  // Represents mental focus, alertness, or concentration.
  focus 
}

// A class representing a specific wellness dimension (like sleep or focus).
class Dim {
  // A constant constructor that requires a key, a label, and a hint to create a 'Dim' object.
  const Dim({required this.key, required this.label, required this.hint});
  
  // The unique identifier for this dimension, using the DimKey enum we defined above.
  final DimKey key;
  // A user-friendly name for this dimension (e.g., "Sleep quality").
  final String label;
  // A descriptive prompt or question related to this dimension (e.g., "How well did you rest?").
  final String hint;
}

// A class representing a single journal or tracking entry for a particular date.
class Entry {
  // A constant constructor that requires the date and scores for all 4 dimensions.
  // The 'note' is optional and defaults to an empty string.
  const Entry({
    required this.date,
    required this.overall,
    required this.sleep,
    required this.physical,
    required this.focus,
    this.note = '',
  });
  
  // A string representing the date of this entry (e.g., "Mon, Aug 24").
  final String date;
  // The score given for overall readiness (typically 1 to 5).
  final int overall;
  // The score given for sleep quality.
  final int sleep;
  // The score given for physical status.
  final int physical;
  // The score given for focus and alertness.
  final int focus;
  // An optional text note or comment written by the user for this entry.
  final String note;

  // A method that returns the specific score for a given dimension key.
  int score(DimKey k) {
    // Switch statement to check which dimension key is requested.
    switch (k) {
      // If the key is 'overall', return the 'overall' score.
      case DimKey.overall:
        return overall;
      // If the key is 'sleep', return the 'sleep' score.
      case DimKey.sleep:
        return sleep;
      // If the key is 'physical', return the 'physical' score.
      case DimKey.physical:
        return physical;
      // If the key is 'focus', return the 'focus' score.
      case DimKey.focus:
        return focus;
    }
  }
}

// A class representing a single data point on a chart, mapped to a specific day.
class ChartPoint {
  // A constant constructor that requires the day and scores for all 4 dimensions.
  const ChartPoint({
    required this.day,
    required this.overall,
    required this.sleep,
    required this.physical,
    required this.focus,
  });
  
  // An integer representing the day (like day 1, day 2, etc. of a period).
  final int day;
  // The score given for overall readiness on this day.
  final int overall;
  // The score given for sleep on this day.
  final int sleep;
  // The score given for physical status on this day.
  final int physical;
  // The score given for focus on this day.
  final int focus;

  // A method that returns the score for a given dimension key as a decimal (double),
  // which is often required by chart libraries for plotting values on axes.
  double forKey(DimKey k) {
    // Switch statement to check which dimension key is requested.
    switch (k) {
      // If 'overall', convert the integer 'overall' to a double and return it.
      case DimKey.overall:
        return overall.toDouble();
      // If 'sleep', convert to double and return.
      case DimKey.sleep:
        return sleep.toDouble();
      // If 'physical', convert to double and return.
      case DimKey.physical:
        return physical.toDouble();
      // If 'focus', convert to double and return.
      case DimKey.focus:
        return focus.toDouble();
    }
  }
}

// A class representing a selectable UI button or "pill" used for choosing a score step (1 to 5).
class StepPill {
  // A constant constructor that requires a value, label, and colors.
  const StepPill(
      {required this.value,
      required this.label,
      required this.color,
      required this.glow});
      
  // The numerical value this pill represents (e.g., 1 for "Very hard").
  final int value;
  // The text label shown on the pill.
  final String label;
  // The solid background color of the pill.
  final Color color;
  // A softer, glowing color used for styling or highlighting the pill.
  final Color glow;
}

// A class representing a helpful resource or article that can be shown to the user.
class ResourceItem {
  // A constant constructor requiring a title, body text, and a color theme. The URL is optional.
  const ResourceItem(
      {required this.title, required this.body, required this.color, this.url});
      
  // The title of the resource.
  final String title;
  // A short description or summary of what the resource contains.
  final String body;
  // An accent color used to visually style the resource item.
  final Color color;
  // An optional web link that opens when the resource is tapped.
  final String? url;
}

// A class representing a privacy or security promise shown to the user (e.g., during consent).
class Assurance {
  // A constant constructor requiring a title, body, and color.
  const Assurance(
      {required this.title, required this.body, required this.color});
      
  // The headline or main point of the assurance (e.g., "Private by design").
  final String title;
  // The detailed explanation of the assurance.
  final String body;
  // An accent color associated with this assurance visually.
  final Color color;
}

// A class representing a spoken language the app supports.
class Language {
  // A constant constructor requiring a language code, an English label, and a native label.
  const Language(
      {required this.code, required this.label, required this.native});
      
  // The standard language/locale code (e.g., 'en-US' or 'hi').
  final String code;
  // The name of the language written in English (e.g., 'Hindi').
  final String label;
  // The name of the language written in its own script (e.g., 'हिन्दी').
  final String native;
}

// ── Dimension definitions ──────────────────────────────────────────────────

// A constant list of the 4 wellness dimensions, containing their keys, titles, and prompts.
const dims = [
  // The first dimension: Overall readiness.
  Dim(
      key: DimKey.overall,
      label: 'Overall readiness',
      hint: 'How ready do you feel for duty today?'),
  // The second dimension: Sleep quality.
  Dim(
      key: DimKey.sleep,
      label: 'Sleep quality',
      hint: 'How well did you rest last night?'),
  // The third dimension: Physical status.
  Dim(
      key: DimKey.physical,
      label: 'Physical status',
      hint: 'Any physical limitations right now?'),
  // The fourth dimension: Focus and alertness.
  Dim(
      key: DimKey.focus,
      label: 'Focus and alertness',
      hint: 'How sharp and attentive do you feel?'),
];

// A constant map that assigns a specific theme color to each dimension key.
// These colors are pulled from the imported 'AppColors' file.
const Map<DimKey, Color> dimColors = {
  // The color for overall readiness.
  DimKey.overall: AppColors.dimOverall,
  // The color for sleep.
  DimKey.sleep: AppColors.dimSleep,
  // The color for physical status.
  DimKey.physical: AppColors.dimPhysical,
  // The color for focus.
  DimKey.focus: AppColors.dimFocus,
};

// ── Step screen pills ──────────────────────────────────────────────────────

// A constant list of exactly 5 'StepPill' objects, representing the 5 choices a user can make.
const stepPills = [
  // Choice 1: Very hard (colored in a dark orange/red).
  StepPill(
      value: 1,
      label: 'Very hard',
      color: Color(0xFFD55E00), // Solid hex color
      glow: Color(0x2ED55E00)), // Semi-transparent glow
  // Choice 2: Hard (colored in a lighter orange).
  StepPill(
      value: 2,
      label: 'Hard',
      color: Color(0xFFC07830),
      glow: Color(0x2EC07830)),
  // Choice 3: Neutral (colored in blue).
  StepPill(
      value: 3,
      label: 'Neutral',
      color: Color(0xFF56B4E9),
      glow: Color(0x2E56B4E9)),
  // Choice 4: Easy (colored in a teal/mint).
  StepPill(
      value: 4,
      label: 'Easy',
      color: Color(0xFF3EC4A0),
      glow: Color(0x2E3EC4A0)),
  // Choice 5: Very easy (colored in bright green).
  StepPill(
      value: 5,
      label: 'Very easy',
      color: Color(0xFF34D399),
      glow: Color(0x2E34D399)),
];

// A constant list of 5 text strings that provide extra context or feedback (an "echo")
// after the user selects a score from 1 to 5 for their focus level.
const stepEcho = [
  // Feedback for a score of 1.
  'Struggled to stay on task',
  // Feedback for a score of 2.
  'Often pulled off focus',
  // Feedback for a score of 3.
  'Mixed — some good, some not',
  // Feedback for a score of 4.
  'Mostly stayed on track',
  // Feedback for a score of 5.
  'Locked in throughout',
];

// ── Resources ──────────────────────────────────────────────────────────────

// A constant list of helpful resources that the app can suggest to the user based on their scores.
const resources = [
  // A resource focused on providing sleep tips.
  ResourceItem(
      title: 'Sleep tips',
      body: 'Strategies for better rest before long shifts',
      color: Color(0xFF56B4E9), // A calming blue color.
      url: 'https://nimhans.ac.in/'), // Link to an external website.
  // A resource focused on focus techniques.
  ResourceItem(
      title: 'Focus techniques',
      body: 'Short exercises to stay sharp on shift',
      color: Color(0xFFC4A870), // A warm brownish-gold color.
      url: 'https://ayush.gov.in/'), // Link to an external website.
];

// ── Consent screen data ────────────────────────────────────────────────────

// A constant list of privacy assurances to make the user feel secure about entering data.
const assurances = [
  // Assurance about data being stored locally and privately.
  Assurance(
      title: 'Private by design',
      body:
          'Your entries live only on this device — no server, no database, no one but you.',
      color: Color(0xFF818CF8)), // Light indigo color.
  // Assurance about data not being shared with superiors.
  Assurance(
      title: 'Never shared with command',
      body:
          "Nothing you log is reported to your chain of command, HR, or any disciplinary process. Ever.",
      color: Color(0xFF56B4E9)), // Light blue color.
  // Assurance that tracking is voluntary.
  Assurance(
      title: 'Entirely your choice',
      body:
          'Skip any day or any question. No record is kept of what you choose not to log.',
      color: Color(0xFF34D399)), // Emerald green color.
];

// A constant list of bullet points giving more technical or specific details on the app's privacy.
const learnMoreItems = [
  // Point 1: explains local encryption.
  'Check-ins are stored locally on your device using encrypted storage.',
  // Point 2: clarifies there are no automated alarms.
  'No automatic alerts or flags are generated from your responses.',
  // Point 3: promises no system integration.
  'There is no integration with personnel, medical, or command systems.',
  // Point 4: guarantees user control over data.
  'You can review or delete all your data at any time through Settings.',
  // Point 5: gives a contact option for questions.
  "Questions? Reach out to your unit's wellness program coordinator.",
];

// ── Languages ──────────────────────────────────────────────────────────────

// A constant list of all supported languages in the app.
const languages = [
  // English UK
  Language(code: 'en-GB', label: 'English (UK)', native: 'English'),
  // English US
  Language(code: 'en-US', label: 'English (US)', native: 'English'),
  // Hindi
  Language(code: 'hi', label: 'Hindi', native: 'हिन्दी'),
  // Marathi
  Language(code: 'mr', label: 'Marathi', native: 'मराठी'),
  // Bengali
  Language(code: 'bn', label: 'Bengali', native: 'বাংলা'),
  // Telugu
  Language(code: 'te', label: 'Telugu', native: 'తెలుగు'),
  // Tamil
  Language(code: 'ta', label: 'Tamil', native: 'தமிழ்'),
  // Gujarati
  Language(code: 'gu', label: 'Gujarati', native: 'ગુજરાતી'),
];

// ── Seed history entries ───────────────────────────────────────────────────

// A dynamic getter (a function that calculates a value every time it's called) 
// that returns a list of dummy 'Entry' objects for the history view.
List<Entry> get seedHistory {
  return [];
}

// ── Offline demo scores ────────────────────────────────────────────────────

// A constant map providing default scores when the app is in offline or demo mode.
const offlineScores = {
  // Default overall score is 4.
  DimKey.overall: 4,
  // Default sleep score is 3.
  DimKey.sleep: 3,
  // Default physical score is 4.
  DimKey.physical: 4,
  // Default focus score is 4.
  DimKey.focus: 4,
};

// ── 30-day chart data ──────────────────────────────────────────────────────

// A private helper function (starts with '_') that generates a realistic-looking fake score 
// based on a sine-like wave math formula. Used to populate fake chart data.
int _waveVal(int day, double phase) {
  // Calculate a base value using some math on the 'day' and 'phase' inputs.
  // The 'abs()' makes sure values are positive, and we add constants to shift the wave up.
  final v = 3 +
      (day * 0.29 + phase).abs() * 1.3 +
      (day * 0.08 + phase * 0.3).abs() * 0.6;
  // Round the calculated decimal to the nearest whole number, then clamp it to be strictly between 1 and 5.
  return v.round().clamp(1, 5);
}

// A private constant map representing a set of fixed, hardcoded daily scores overlayed on top of the fake wave data.
// The key is the day number, and the value is a list of exactly 4 scores [overall, sleep, physical, focus].
// Seed overlay: actual known data at correct day offsets (Day 1 = Aug 5 2026)
const _seedOverlay = {
  // Scores for day 22.
  22: [3, 3, 4, 3],
  // Scores for day 23.
  23: [4, 4, 4, 4],
  // Scores for day 24.
  24: [2, 2, 3, 2],
  // Scores for day 25.
  25: [4, 4, 4, 4],
  // Scores for day 28.
  28: [5, 5, 5, 5],
  // Scores for day 29.
  29: [3, 2, 4, 3],
  // Scores for day 30.
  30: [4, 3, 5, 4],
};

// A function that creates and returns a list of 30 'ChartPoint' objects to display a full month's chart.
List<ChartPoint> buildThirtyDayData() {
  return [];
}

// A constant map that maps specific day numbers on the chart to text labels for the X-axis.
// Axis labels for the chart
const chartXLabels = {
  // Label for day 1.
  1: 'Aug 5',
  // Label for day 8.
  8: 'Aug 12',
  // Label for day 15.
  15: 'Aug 19',
  // Label for day 22.
  22: 'Aug 26',
  // Label for day 30.
  30: 'Sep 3'
};
