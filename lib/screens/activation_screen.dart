import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/colors.dart';
import '../widgets/icon_widgets.dart';
import '../widgets/rr_card.dart';
import '../services/auth_service.dart';
import '../data/translations.dart';

// ── ActivationScreen ────────────────────────────────────────────────────────
class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key, required this.onActivated});
  final VoidCallback onActivated;

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  bool _isLoginMode = false;
  String _serviceId = '';
  String _raw = '';
  String _name = '';
  String _pin = '';
  bool _loading = false;
  bool _slowRequest = false;
  String? _error;

  String get _formatted =>
      _raw.length > 4 ? '${_raw.substring(0, 4)}-${_raw.substring(4)}' : _raw;
  bool get _isReady => _isLoginMode
      ? _serviceId.trim().isNotEmpty && _pin.length == 6
      : _raw.length == 8 && _name.trim().length >= 2 && _pin.length == 6;
  bool get _active => _isReady && !_loading;

  void _handleCode(String text) {
    final clean = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    setState(() => _raw = clean.length > 8 ? clean.substring(0, 8) : clean);
  }

  Future<void> _submit() async {
    if (!_isReady || _loading) return;
    setState(() {
      _loading = true;
      _slowRequest = false;
      _error = null;
    });

    // After 5 s, show a hint that the server may be waking up
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _loading) setState(() => _slowRequest = true);
    });

    try {
      final auth = ref.read(authServiceProvider);
      Map<String, dynamic> user;

      if (_isLoginMode) {
        user = await auth.login(_serviceId.trim(), _pin);
      } else {
        user = await auth.activateDevice(_formatted, _pin, _name.trim());
      }

      // Save service_id and name for login screen
      const storage = FlutterSecureStorage();
      await storage.write(key: 'service_id', value: user['service_id']);
      await storage.write(key: 'user_name', value: user['username']);

      if (!mounted) return;
      widget.onActivated();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      String errorText;
      if (msg.contains('400')) {
        errorText = _isLoginMode
            ? tr('Invalid credentials.', ref)
            : tr('Invalid or already used code.', ref);
      } else if (msg.contains('401')) {
        errorText = tr('Invalid credentials.', ref);
      } else if (msg.contains('timeout') ||
          msg.contains('SocketException') ||
          msg.contains('connection')) {
        errorText =
            tr('Server is waking up. Please try again in 30 seconds.', ref);
      } else {
        errorText = _isLoginMode
            ? tr('Login failed. Please try again.', ref)
            : tr('Activation failed. Please try again.', ref);
      }
      setState(() {
        _loading = false;
        _slowRequest = false;
        _error = errorText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.indigo.withValues(alpha: 0.10),
                      border: Border.all(
                          color: AppColors.indigo.withValues(alpha: 0.24)),
                    ),
                    child: const Center(
                        child: IconShield(size: 28, color: AppColors.indigo)),
                  ),
                ),
              ),
              Text(
                _isLoginMode
                    ? tr('Login to your account', ref)
                    : tr('Activate this device', ref),
                style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    color: context.rrT1,
                    height: 1.25),
              ),
              const SizedBox(height: 14),
              Text(
                _isLoginMode
                    ? tr('Enter your Service ID and 6-digit PIN.', ref)
                    : tr(
                        'Enter your code, full name, and create a 6-digit PIN.',
                        ref),
                style:
                    TextStyle(fontSize: 14, color: context.rrT3, height: 1.65),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.score1.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.score1.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.score1, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.score1, fontSize: 13))),
                    ],
                  ),
                ),
              ] else if (_loading && _slowRequest) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.indigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.indigo.withValues(alpha: 0.20)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.indigo),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('Server is starting up, please wait…', ref),
                          style: const TextStyle(
                              color: AppColors.indigo, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Opacity(
                opacity: _loading ? 0.55 : 1.0,
                child: RrCard(
                  child: Column(
                    children: [
                      if (_isLoginMode) ...[
                        Text(tr('Service ID', ref),
                            style:
                                TextStyle(fontSize: 12, color: context.rrT4)),
                        const SizedBox(height: 8),
                        TextField(
                          enabled: !_loading,
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (v) => setState(() => _serviceId = v),
                          style: TextStyle(fontSize: 18, color: context.rrT1),
                          decoration: InputDecoration(
                              hintText: 'e.g. SRV-1234',
                              hintStyle: TextStyle(color: context.rrT7),
                              border: InputBorder.none),
                        ),
                        const SizedBox(height: 16),
                        Text(tr('6-digit PIN', ref),
                            style:
                                TextStyle(fontSize: 12, color: context.rrT4)),
                      ] else ...[
                        Text(tr('Activation code', ref),
                            style:
                                TextStyle(fontSize: 12, color: context.rrT4)),
                        const SizedBox(height: 8),
                        TextField(
                          enabled: !_loading,
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: _handleCode,
                          style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 24,
                              letterSpacing: 6,
                              color: context.rrT1),
                          decoration: InputDecoration(
                              hintText: 'XXXX-XXXX',
                              hintStyle: TextStyle(
                                  color: context.rrT7, letterSpacing: 6),
                              border: InputBorder.none),
                          controller: TextEditingController(text: _formatted)
                            ..selection = TextSelection.collapsed(
                                offset: _formatted.length),
                        ),
                        const SizedBox(height: 16),
                        Text(tr('Full Name', ref),
                            style:
                                TextStyle(fontSize: 12, color: context.rrT4)),
                        TextField(
                          enabled: !_loading,
                          textAlign: TextAlign.center,
                          onChanged: (v) => setState(() => _name = v),
                          style: TextStyle(fontSize: 18, color: context.rrT1),
                          decoration: InputDecoration(
                              hintText: 'e.g. Constable Ravi',
                              hintStyle: TextStyle(color: context.rrT7),
                              border: InputBorder.none),
                        ),
                        const SizedBox(height: 16),
                        Text(tr('Create 6-digit PIN', ref),
                            style:
                                TextStyle(fontSize: 12, color: context.rrT4)),
                      ],
                      TextField(
                        enabled: !_loading,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        onChanged: (v) => setState(() => _pin = v),
                        style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 24,
                            letterSpacing: 8,
                            color: context.rrT1),
                        decoration: InputDecoration(
                            hintText: '******',
                            hintStyle: TextStyle(
                                color: context.rrT7, letterSpacing: 8),
                            border: InputBorder.none,
                            counterText: ''),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _active ? _submit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _active
                        ? AppColors.indigo
                        : AppColors.indigo.withValues(alpha: 0.14),
                  ),
                  child: Center(
                    child: Text(
                      _loading
                          ? (_isLoginMode
                              ? tr('Logging in…', ref)
                              : tr('Activating…', ref))
                          : (_isLoginMode
                              ? tr('Login', ref)
                              : tr('Activate', ref)),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _active
                              ? const Color(0xFF0C1220)
                              : AppColors.indigo.withValues(alpha: 0.45)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _loading
                      ? null
                      : () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                            _error = null;
                            _pin = '';
                          });
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _isLoginMode
                          ? tr('New device? Activate with a code', ref)
                          : tr('Already have credentials? Login instead', ref),
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.indigo,
                          fontWeight: FontWeight.w500),
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
