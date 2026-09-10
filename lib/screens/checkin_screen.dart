import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../data/seed.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';
import '../widgets/scale_picker.dart';
import '../data/translations.dart';

// ── DimCard ──────────────────────────────────────────────────────────────────
class _DimCard extends ConsumerWidget {
  const _DimCard({required this.dim, required this.value, required this.onChanged});
  final Dim dim;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = value > 0 ? scoreColor(value) : context.rrT4;
    return RrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: dimIcon(dim.key, size: 15, color: col),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(dim.label, ref),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.rrT1, height: 1.2)),
                    const SizedBox(height: 2),
                    Text(tr(dim.hint, ref), style: TextStyle(fontSize: 12, color: context.rrT3)),
                  ],
                ),
              ),
              if (value > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(tr(scoreLabel(value), ref),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: col)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ScalePicker(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── CheckinScreen ────────────────────────────────────────────────────────────
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({
    super.key,
    required this.scores,
    required this.note,
    required this.onScoreChanged,
    required this.onNoteChanged,
    required this.onSubmit,
    required this.onBack,
  });
  final Map<DimKey, int> scores;
  final String note;
  final void Function(DimKey, int) onScoreChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.note)
      ..addListener(() => widget.onNoteChanged(_noteCtrl.text));
  }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final filled   = dims.where((d) => widget.scores[d.key]! > 0).length;
    final allDone  = filled == 4;
    final remaining = 200 - widget.note.length;

    return Scaffold(
      backgroundColor: context.rrBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              GestureDetector(
                onTap: widget.onBack,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left, size: 16, color: context.rrT4),
                    Text(tr('Home', ref), style: TextStyle(fontSize: 13, color: context.rrT4)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Heading
              Text('Thursday, 4 Sep 2026', style: TextStyle(fontSize: 13, color: context.rrT4)),
              const SizedBox(height: 4),
              Text(tr('Daily readiness check-in', ref),
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: context.rrT1, height: 1.2)),
              const SizedBox(height: 6),
              Text(tr('Private to you and your unit lead. Takes about a minute.', ref),
                style: TextStyle(fontSize: 13, color: context.rrT3)),
              const SizedBox(height: 12),
              // Dim cards
              ...dims.map((dim) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DimCard(
                  dim: dim,
                  value: widget.scores[dim.key]!,
                  onChanged: (n) => widget.onScoreChanged(dim.key, n),
                ),
              )),
              // Optional note
              RrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(text: TextSpan(
                      text: tr('Anything to add? ', ref),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.rrT2),
                      children: [
                        TextSpan(text: tr('(optional)', ref), style: TextStyle(fontWeight: FontWeight.w400, color: context.rrT4)),
                      ],
                    )),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: tr('Brief note for your record...', ref),
                        hintStyle: TextStyle(color: context.rrT6, fontSize: 14),
                        counterText: '',
                        filled: true,
                        fillColor: context.rrIn,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.rrIb),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.indigo.withValues(alpha: 0.35)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.rrIb),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: TextStyle(fontSize: 14, color: context.rrT1, height: 1.6),
                    ),
                    if (widget.note.length > 160)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('$remaining remaining',
                            style: TextStyle(fontSize: 11, color: context.rrT4)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Submit
              GestureDetector(
                onTap: allDone ? widget.onSubmit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: allDone ? AppColors.indigo : AppColors.indigo.withValues(alpha: 0.14),
                    boxShadow: allDone
                        ? [BoxShadow(color: AppColors.indigo.withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      allDone ? tr("Log today's readiness", ref) : "$filled of 4 ${tr('complete', ref)}",
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: allDone ? const Color(0xFF0C1220) : AppColors.indigo.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
