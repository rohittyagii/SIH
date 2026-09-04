import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';

// ── ActivationScreen ────────────────────────────────────────────────────────
class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key, required this.onActivated});
  final VoidCallback onActivated;

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  String _raw = '';
  bool _loading = false;

  String get _formatted => _raw.length > 4 ? '${_raw.substring(0, 4)}-${_raw.substring(4)}' : _raw;
  bool get _isReady => _raw.length == 8;
  bool get _active  => _isReady && !_loading;

  void _handleChanged(String text) {
    // Strip non-alphanumeric, uppercase, cap at 8 raw chars
    final clean = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    setState(() => _raw = clean.length > 8 ? clean.substring(0, 8) : clean);
  }

  Future<void> _activate() async {
    if (!_isReady || _loading) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    widget.onActivated();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _raw.length / 8;
    return Scaffold(
      backgroundColor: context.rrBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 64, bottom: 32),
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.indigo.withValues(alpha: 0.10),
                      border: Border.all(color: AppColors.indigo.withValues(alpha: 0.24)),
                      boxShadow: [BoxShadow(color: AppColors.indigo.withValues(alpha: 0.10), blurRadius: 48)],
                    ),
                    child: const Center(child: IconShield(size: 28, color: AppColors.indigo)),
                  ),
                ),
              ),
              // Heading
              Text('READINESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: context.rrT6, letterSpacing: 0.10)),
              const SizedBox(height: 10),
              Text('Activate this device',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600, color: context.rrT1, height: 1.25)),
              const SizedBox(height: 14),
              Text('Your unit welfare office issued you a one-time activation code. Enter it here to link your personal readiness tracker.',
                style: TextStyle(fontSize: 14, color: context.rrT3, height: 1.65)),
              const SizedBox(height: 32),
              // Code input card
              Opacity(
                opacity: _loading ? 0.55 : 1.0,
                child: RrCard(
                  child: Column(
                    children: [
                      Text('Activation code', style: TextStyle(fontSize: 12, color: context.rrT4)),
                      const SizedBox(height: 20),
                      TextField(
                        enabled: !_loading,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        maxLength: 9,
                        onChanged: _handleChanged,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 30,
                          letterSpacing: 8,
                          color: context.rrT1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'XXXX-XXXX',
                          hintStyle: TextStyle(color: context.rrT7, letterSpacing: 8),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        controller: TextEditingController(text: _formatted)
                          ..selection = TextSelection.collapsed(offset: _formatted.length),
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        height: 1.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          color: context.rrDv2,
                        ),
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              color: _isReady ? AppColors.indigo : AppColors.indigo.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          text: 'Printed on the letter from your welfare office. ',
                          style: TextStyle(fontSize: 12, color: context.rrT5),
                          children: [
                            TextSpan(text: 'Single-use. Not connected to your service record.',
                              style: TextStyle(color: context.rrT4)),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Activate button
              GestureDetector(
                onTap: _active ? _activate : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _active
                        ? AppColors.indigo
                        : _loading
                            ? AppColors.indigo.withValues(alpha: 0.22)
                            : AppColors.indigo.withValues(alpha: 0.14),
                    boxShadow: _active
                        ? [BoxShadow(color: AppColors.indigo.withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_loading) ...[
                        SizedBox(
                          width: 15, height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.indigo.withValues(alpha: 0.7)),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        _loading ? 'Verifying…' : 'Activate device',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: _active ? const Color(0xFF0C1220) : AppColors.indigo.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('Need a code? Contact your welfare office',
                  style: TextStyle(fontSize: 14, color: context.rrT4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
