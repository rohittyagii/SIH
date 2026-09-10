import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../services/auth_service.dart';
import '../widgets/rr_card.dart';
import '../data/translations.dart';

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  final _currentPinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _currentPinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentPinCtrl.text.trim();
    final newPin = _newPinCtrl.text.trim();
    final confirm = _confirmPinCtrl.text.trim();

    if (current.length != 6 || newPin.length != 6 || confirm.length != 6) {
      setState(() => _errorMsg = tr('PINs must be exactly 6 digits.', ref));
      return;
    }
    if (newPin != confirm) {
      setState(() => _errorMsg = tr('New PINs do not match.', ref));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      await ref.read(authServiceProvider).changePin(current, newPin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('PIN successfully changed', ref)),
          backgroundColor: AppColors.score5,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = tr('Failed to change PIN. Check your current PIN.', ref);
      });
    }
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.rrT4)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: TextStyle(fontSize: 16, color: context.rrT1, letterSpacing: 4),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: context.rrIn,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.rrIb)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.rrIb)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.indigo.withValues(alpha: 0.35))),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.rrBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left, size: 18, color: context.rrT4),
                    Text(tr('Settings', ref), style: TextStyle(fontSize: 14, color: context.rrT4)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(tr('Change PIN', ref), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: context.rrT1)),
              const SizedBox(height: 8),
              Text(tr('Update your 6-digit device PIN.', ref), style: TextStyle(fontSize: 14, color: context.rrT4)),
              const SizedBox(height: 32),

              RrCard(
                child: Column(
                  children: [
                    _buildField(tr('Current PIN', ref), _currentPinCtrl),
                    const SizedBox(height: 20),
                    _buildField(tr('New PIN', ref), _newPinCtrl),
                    const SizedBox(height: 20),
                    _buildField(tr('Confirm New PIN', ref), _confirmPinCtrl),
                  ],
                ),
              ),

              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(_errorMsg!, style: const TextStyle(fontSize: 13, color: AppColors.score1)),
                ),

              const SizedBox(height: 32),
              GestureDetector(
                onTap: _isLoading ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.indigo,
                    boxShadow: [
                      BoxShadow(color: AppColors.indigo.withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF0C1220), strokeWidth: 2))
                        : Text(tr('Update PIN', ref), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0C1220))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
