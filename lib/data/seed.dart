import 'package:flutter/material.dart';
import '../theme/colors.dart';

// ── Score helper functions ─────────────────────────────────────────────────
Color scoreColor(int n) => AppColors.scoreColors[(n.clamp(1, 5) - 1)];
Color scoreGlow(int n) => AppColors.scoreGlows[(n.clamp(1, 5) - 1)];
String scoreLabel(int n) {
  const labels = ['Not ready', 'Low', 'Moderate', 'Good', 'Fully ready'];
  final i = n.clamp(1, 5) - 1;
  return labels[i];
}

// ── Models ─────────────────────────────────────────────────────────────────
enum DimKey { overall, sleep, physical, focus }

class Dim {
  const Dim({required this.key, required this.label, required this.hint});
  final DimKey key;
  final String label;
  final String hint;
}

class Entry {
  const Entry({
    required this.date,
    required this.overall,
    required this.sleep,
    required this.physical,
    required this.focus,
    this.note = '',
  });
  final String date;
  final int overall;
  final int sleep;
  final int physical;
  final int focus;
  final String note;

  int score(DimKey k) {
    switch (k) {
      case DimKey.overall:
        return overall;
      case DimKey.sleep:
        return sleep;
      case DimKey.physical:
        return physical;
      case DimKey.focus:
        return focus;
    }
  }
}

class ChartPoint {
  const ChartPoint({
    required this.day,
    required this.overall,
    required this.sleep,
    required this.physical,
    required this.focus,
  });
  final int day;
  final int overall;
  final int sleep;
  final int physical;
  final int focus;

  double forKey(DimKey k) {
    switch (k) {
      case DimKey.overall:
        return overall.toDouble();
      case DimKey.sleep:
        return sleep.toDouble();
      case DimKey.physical:
        return physical.toDouble();
      case DimKey.focus:
        return focus.toDouble();
    }
  }
}

class StepPill {
  const StepPill(
      {required this.value,
      required this.label,
      required this.color,
      required this.glow});
  final int value;
  final String label;
  final Color color;
  final Color glow;
}

class ResourceItem {
  const ResourceItem(
      {required this.title, required this.body, required this.color});
  final String title;
  final String body;
  final Color color;
}

class Assurance {
  const Assurance(
      {required this.title, required this.body, required this.color});
  final String title;
  final String body;
  final Color color;
}

class Language {
  const Language(
      {required this.code, required this.label, required this.native});
  final String code;
  final String label;
  final String native;
}

// ── Dimension definitions ──────────────────────────────────────────────────
const dims = [
  Dim(
      key: DimKey.overall,
      label: 'Overall readiness',
      hint: 'How ready do you feel for duty today?'),
  Dim(
      key: DimKey.sleep,
      label: 'Sleep quality',
      hint: 'How well did you rest last night?'),
  Dim(
      key: DimKey.physical,
      label: 'Physical status',
      hint: 'Any physical limitations right now?'),
  Dim(
      key: DimKey.focus,
      label: 'Focus and alertness',
      hint: 'How sharp and attentive do you feel?'),
];

const Map<DimKey, Color> dimColors = {
  DimKey.overall: AppColors.dimOverall,
  DimKey.sleep: AppColors.dimSleep,
  DimKey.physical: AppColors.dimPhysical,
  DimKey.focus: AppColors.dimFocus,
};

// ── Step screen pills ──────────────────────────────────────────────────────
const stepPills = [
  StepPill(
      value: 1,
      label: 'Very hard',
      color: Color(0xFFD55E00),
      glow: Color(0x2ED55E00)),
  StepPill(
      value: 2,
      label: 'Hard',
      color: Color(0xFFC07830),
      glow: Color(0x2EC07830)),
  StepPill(
      value: 3,
      label: 'Neutral',
      color: Color(0xFF56B4E9),
      glow: Color(0x2E56B4E9)),
  StepPill(
      value: 4,
      label: 'Easy',
      color: Color(0xFF3EC4A0),
      glow: Color(0x2E3EC4A0)),
  StepPill(
      value: 5,
      label: 'Very easy',
      color: Color(0xFF34D399),
      glow: Color(0x2E34D399)),
];

const stepEcho = [
  'Struggled to stay on task',
  'Often pulled off focus',
  'Mixed — some good, some not',
  'Mostly stayed on track',
  'Locked in throughout',
];

// ── Resources ──────────────────────────────────────────────────────────────
const resources = [
  ResourceItem(
      title: 'Sleep tips',
      body: 'Strategies for better rest before long shifts',
      color: Color(0xFF56B4E9)),
  ResourceItem(
      title: 'Talk to peer support',
      body: 'Speak with a trained colleague, any time',
      color: Color(0xFF818CF8)),
  ResourceItem(
      title: 'Focus techniques',
      body: 'Short exercises to stay sharp on shift',
      color: Color(0xFFC4A870)),
];

// ── Consent screen data ────────────────────────────────────────────────────
const assurances = [
  Assurance(
      title: 'Private by design',
      body:
          'Your entries live only on this device — no server, no database, no one but you.',
      color: Color(0xFF818CF8)),
  Assurance(
      title: 'Never shared with command',
      body:
          "Nothing you log is reported to your chain of command, HR, or any disciplinary process. Ever.",
      color: Color(0xFF56B4E9)),
  Assurance(
      title: 'Entirely your choice',
      body:
          'Skip any day or any question. No record is kept of what you choose not to log.',
      color: Color(0xFF34D399)),
];

const learnMoreItems = [
  'Check-ins are stored locally on your device using encrypted storage.',
  'No automatic alerts or flags are generated from your responses.',
  'There is no integration with personnel, medical, or command systems.',
  'You can review or delete all your data at any time through Settings.',
  "Questions? Reach out to your unit's wellness program coordinator.",
];

// ── Languages ──────────────────────────────────────────────────────────────
const languages = [
  Language(code: 'en-GB', label: 'English (UK)', native: 'English'),
  Language(code: 'en-US', label: 'English (US)', native: 'English'),
  Language(code: 'hi', label: 'Hindi', native: 'हिन्दी'),
  Language(code: 'mr', label: 'Marathi', native: 'मराठी'),
  Language(code: 'bn', label: 'Bengali', native: 'বাংলা'),
  Language(code: 'te', label: 'Telugu', native: 'తెలుగు'),
  Language(code: 'ta', label: 'Tamil', native: 'தமிழ்'),
  Language(code: 'gu', label: 'Gujarati', native: 'ગુજરાતી'),
];

// ── Seed history entries ───────────────────────────────────────────────────
const seedHistory = [
  Entry(date: 'Wed, Sep 3', overall: 4, sleep: 3, physical: 5, focus: 4),
  Entry(
      date: 'Tue, Sep 2',
      overall: 3,
      sleep: 2,
      physical: 4,
      focus: 3,
      note: 'Long shift yesterday'),
  Entry(date: 'Mon, Sep 1', overall: 5, sleep: 5, physical: 5, focus: 5),
  Entry(date: 'Fri, Aug 29', overall: 4, sleep: 4, physical: 4, focus: 4),
  Entry(
      date: 'Thu, Aug 28',
      overall: 2,
      sleep: 2,
      physical: 3,
      focus: 2,
      note: 'Poor night — headache through the morning'),
  Entry(date: 'Wed, Aug 27', overall: 4, sleep: 4, physical: 4, focus: 4),
  Entry(date: 'Tue, Aug 26', overall: 3, sleep: 3, physical: 4, focus: 3),
];

// ── Offline demo scores ────────────────────────────────────────────────────
const offlineScores = {
  DimKey.overall: 4,
  DimKey.sleep: 3,
  DimKey.physical: 4,
  DimKey.focus: 4,
};

// ── 30-day chart data ──────────────────────────────────────────────────────
int _waveVal(int day, double phase) {
  final v = 3 +
      (day * 0.29 + phase).abs() * 1.3 +
      (day * 0.08 + phase * 0.3).abs() * 0.6;
  return v.round().clamp(1, 5);
}

// Seed overlay: actual known data at correct day offsets (Day 1 = Aug 5 2026)
const _seedOverlay = {
  22: [3, 3, 4, 3],
  23: [4, 4, 4, 4],
  24: [2, 2, 3, 2],
  25: [4, 4, 4, 4],
  28: [5, 5, 5, 5],
  29: [3, 2, 4, 3],
  30: [4, 3, 5, 4],
};

List<ChartPoint> buildThirtyDayData() {
  return List.generate(30, (i) {
    final day = i + 1;
    final ov = _seedOverlay[day];
    return ChartPoint(
      day: day,
      overall: ov != null ? ov[0] : _waveVal(day, 0),
      sleep: ov != null ? ov[1] : _waveVal(day, 1.6),
      physical: ov != null ? ov[2] : _waveVal(day, 2.9),
      focus: ov != null ? ov[3] : _waveVal(day, 4.2),
    );
  });
}

// Axis labels for the chart
const chartXLabels = {
  1: 'Aug 5',
  8: 'Aug 12',
  15: 'Aug 19',
  22: 'Aug 26',
  30: 'Sep 3'
};
