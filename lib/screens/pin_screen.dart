import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../widgets/icon_widgets.dart';

// ── PIN constants ──────────────────────────────────────────────────────────
const _pinLength = 6;

enum _PinState { idle, checking, error, success }

// ── PinDots ─────────────────────────────────────────────────────────────────
class _PinDots extends StatefulWidget {
  const _PinDots({required this.filled, required this.state});
  final int filled;
  final _PinState state;

  @override
  State<_PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<_PinDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        duration: const Duration(milliseconds: 520), vsync: this);
    _offset = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -5.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -2.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -2.0, end: 2.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0), weight: 10),
    ]).animate(_shake);
  }

  @override
  void didUpdateWidget(_PinDots old) {
    super.didUpdateWidget(old);
    if (widget.state == _PinState.error && old.state != _PinState.error) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.state == _PinState.error;
    final isSuccess = widget.state == _PinState.success;
    final col = isSuccess
        ? AppColors.score5
        : isError
            ? AppColors.score1
            : AppColors.indigo;
    final glow = isSuccess
        ? const Color(0x8D34D399)
        : isError
            ? Colors.transparent
            : const Color(0x8D818CF8);

    return AnimatedBuilder(
      animation: _offset,
      builder: (_, child) => Transform.translate(
        offset: Offset(_offset.value, 0),
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_pinLength, (i) {
          final on = i < widget.filled;
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? col : Colors.transparent,
              border: on ? null : Border.all(color: context.rrB7, width: 1.5),
              boxShadow: on && !isError
                  ? [BoxShadow(color: glow, blurRadius: 10)]
                  : [],
            ),
          );
        }),
      ),
    );
  }
}

// ── KeypadBtn ──────────────────────────────────────────────────────────────
class _KeypadBtn extends StatefulWidget {
  const _KeypadBtn(
      {required this.child, required this.onTap, this.disabled = false});
  final Widget child;
  final VoidCallback onTap;
  final bool disabled;

  @override
  State<_KeypadBtn> createState() => _KeypadBtnState();
}

class _KeypadBtnState extends State<_KeypadBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: widget.disabled ? 0.45 : 1.0,
        child: GestureDetector(
          onTapDown:
              widget.disabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: widget.disabled
              ? null
              : (_) {
                  setState(() => _pressed = false);
                  widget.onTap();
                },
          onTapCancel: () => setState(() => _pressed = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 75),
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pressed
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.transparent,
                ),
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Keypad ─────────────────────────────────────────────────────────────────
class _Keypad extends StatelessWidget {
  const _Keypad(
      {required this.onDigit, required this.onDelete, required this.disabled});
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool disabled;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows
          .map((row) => Row(
                children: row.map((key) {
                  if (key == '') return const Expanded(child: SizedBox());
                  if (key == 'del') {
                    return _KeypadBtn(
                      onTap: onDelete,
                      disabled: disabled,
                      child: IconDelete(size: 21, color: context.rrT5),
                    );
                  }
                  return _KeypadBtn(
                    onTap: () => onDigit(key),
                    disabled: disabled,
                    child: Text(key,
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: context.rrT1,
                            height: 1)),
                  );
                }).toList(),
              ))
          .toList(),
    );
  }
}

// ── PinScreen ──────────────────────────────────────────────────────────────
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen(
      {super.key, required this.onUnlocked, required this.onSetupNew});
  final VoidCallback onUnlocked;
  final VoidCallback onSetupNew;

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  _PinState _state = _PinState.idle;
  int _attempt = 0;

  void _verify() {
    setState(() => _state = _PinState.checking);
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      if (_attempt == 0) {
        setState(() => _state = _PinState.error);
        Future.delayed(const Duration(milliseconds: 750), () {
          if (!mounted) return;
          setState(() {
            _pin = '';
            _state = _PinState.idle;
            _attempt = 1;
          });
        });
      } else {
        setState(() => _state = _PinState.success);
        Future.delayed(const Duration(milliseconds: 650), () {
          if (!mounted) return;
          widget.onUnlocked();
        });
      }
    });
  }

  void _handleDigit(String d) {
    if (_state != _PinState.idle || _pin.length >= _pinLength) return;
    final next = _pin + d;
    setState(() => _pin = next);
    if (next.length == _pinLength) _verify();
  }

  void _handleDelete() {
    if (_state != _PinState.idle) return;
    setState(
        () => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1));
  }

  void _useBiometrics() {
    if (_state != _PinState.idle) return;
    setState(() => _state = _PinState.success);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      widget.onUnlocked();
    });
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _state != _PinState.idle;
    return Scaffold(
      backgroundColor: context.rrBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  // Top identity section
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        Text('READINESS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: context.rrT7,
                                letterSpacing: 0.12)),
                        const SizedBox(height: 24),
                        // Avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.indigo.withValues(alpha: 0.08),
                            border: Border.all(
                                color: AppColors.indigo.withValues(alpha: 0.20),
                                width: 1.5),
                          ),
                          child: const Center(
                            child: Text('F',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.indigo)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Welcome back',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: context.rrT2)),
                        const SizedBox(height: 4),
                        Text('Foxtrot-42',
                            style:
                                TextStyle(fontSize: 14, color: context.rrT5)),
                        const SizedBox(height: 32),
                        _PinDots(filled: _pin.length, state: _state),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 32,
                          child: Center(child: _stateLabel(context)),
                        ),
                      ],
                    ),
                  ),
                  // Keypad
                  _Keypad(
                      onDigit: _handleDigit,
                      onDelete: _handleDelete,
                      disabled: disabled),
                  // Biometrics + setup
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: GestureDetector(
                      onTap: disabled ? null : _useBiometrics,
                      child: Opacity(
                        opacity: disabled ? 0.4 : 1.0,
                        child: Column(
                          children: [
                            IconFingerprint(size: 28, color: context.rrT6),
                            const SizedBox(height: 6),
                            Text('Use biometrics',
                                style: TextStyle(
                                    fontSize: 12, color: context.rrT5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: GestureDetector(
                      onTap: widget.onSetupNew,
                      child: Text('New device? Set up this device',
                          style: TextStyle(fontSize: 11, color: context.rrT7)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stateLabel(BuildContext context) {
    switch (_state) {
      case _PinState.error:
        return const Text('Incorrect PIN — try again',
            style: TextStyle(fontSize: 13, color: AppColors.score1));
      case _PinState.checking:
        return Text('Verifying…',
            style: TextStyle(fontSize: 13, color: context.rrT6));
      case _PinState.success:
        return const Text('Unlocked',
            style: TextStyle(fontSize: 13, color: AppColors.score5));
      case _PinState.idle:
        return const SizedBox.shrink();
    }
  }
}
