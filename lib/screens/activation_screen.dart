import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/colors.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

// ── ActivationScreen ────────────────────────────────────────────────────────
class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key, required this.onActivated});
  final VoidCallback onActivated;

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  String _raw = '';
  String _name = '';
  String _pin = '';
  bool _loading = false;
  String? _error;

  String get _formatted => _raw.length > 4 ? '${_raw.substring(0, 4)}-${_raw.substring(4)}' : _raw;
  bool get _isReady => _raw.length == 8 && _name.trim().length >= 2 && _pin.length == 6;
  bool get _active  => _isReady && !_loading;

  void _handleCode(String text) {
    final clean = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    setState(() => _raw = clean.length > 8 ? clean.substring(0, 8) : clean);
  }

  Future<void> _activate() async {
    if (!_isReady || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final user = await auth.activateDevice(_formatted, _pin, _name.trim());
      
      // Save service_id and name for login screen
      const storage = FlutterSecureStorage();
      await storage.write(key: 'service_id', value: user['service_id']);
      await storage.write(key: 'user_name', value: user['username']);
      
      if (!mounted) return;
      widget.onActivated();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().contains('400') ? 'Invalid or already used code.' : 'Activation failed. Check network.';
      });
    }
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 24),
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.indigo.withValues(alpha: 0.10),
                      border: Border.all(color: AppColors.indigo.withValues(alpha: 0.24)),
                    ),
                    child: const Center(child: IconShield(size: 28, color: AppColors.indigo)),
                  ),
                ),
              ),
              Text('Activate this device',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600, color: context.rrT1, height: 1.25)),
              const SizedBox(height: 14),
              Text('Enter your code, full name, and create a 6-digit PIN.',
                style: TextStyle(fontSize: 14, color: context.rrT3, height: 1.65)),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppColors.score1, fontSize: 14)),
              ],
              const SizedBox(height: 24),
              Opacity(
                opacity: _loading ? 0.55 : 1.0,
                child: RrCard(
                  child: Column(
                    children: [
                      Text('Activation code', style: TextStyle(fontSize: 12, color: context.rrT4)),
                      const SizedBox(height: 8),
                      TextField(
                        enabled: !_loading,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: _handleCode,
                        style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 24, letterSpacing: 6, color: context.rrT1),
                        decoration: InputDecoration(hintText: 'XXXX-XXXX', hintStyle: TextStyle(color: context.rrT7, letterSpacing: 6), border: InputBorder.none),
                        controller: TextEditingController(text: _formatted)..selection = TextSelection.collapsed(offset: _formatted.length),
                      ),
                      const SizedBox(height: 16),
                      Text('Full Name', style: TextStyle(fontSize: 12, color: context.rrT4)),
                      TextField(
                        enabled: !_loading,
                        textAlign: TextAlign.center,
                        onChanged: (v) => setState(() => _name = v),
                        style: TextStyle(fontSize: 18, color: context.rrT1),
                        decoration: InputDecoration(hintText: 'e.g. Constable Ravi', hintStyle: TextStyle(color: context.rrT7), border: InputBorder.none),
                      ),
                      const SizedBox(height: 16),
                      Text('Create 6-digit PIN', style: TextStyle(fontSize: 12, color: context.rrT4)),
                      TextField(
                        enabled: !_loading,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        onChanged: (v) => setState(() => _pin = v),
                        style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 24, letterSpacing: 8, color: context.rrT1),
                        decoration: InputDecoration(hintText: '******', hintStyle: TextStyle(color: context.rrT7, letterSpacing: 8), border: InputBorder.none, counterText: ''),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _active ? _activate : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _active ? AppColors.indigo : AppColors.indigo.withValues(alpha: 0.14),
                  ),
                  child: Center(
                    child: Text(
                      _loading ? 'Activating…' : 'Activate',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _active ? const Color(0xFF0C1220) : AppColors.indigo.withValues(alpha: 0.45)),
                    ),
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
