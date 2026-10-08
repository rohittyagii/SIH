// Import standard Flutter Material UI components
import 'package:flutter/material.dart';
// Import Riverpod for state management
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import Flutter Secure Storage to securely save/read local data (like service ID)
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import local files for custom colors, icons, services, translations, and reusable widgets
import '../theme/colors.dart';
import '../widgets/icon_widgets.dart';
import '../services/auth_service.dart';
import '../data/translations.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/animated_orbs.dart';

// The expected length of the PIN code is 6 digits
const _pinLength = 6;

// Defines the various states the PIN entry can be in
enum _PinState {
  idle,       // User is typing or hasn't started yet
  checking,   // App is currently verifying the entered PIN
  error,      // The entered PIN was incorrect
  success     // The entered PIN was correct
}

// ── PinDots ─────────────────────────────────────────────────────────────────
// This widget displays the row of dots representing the PIN.
// It animates (shakes) when there is an error.
class _PinDots extends StatefulWidget {
  // Requires the number of currently filled dots and the current PIN state
  const _PinDots({required this.filled, required this.state});
  
  final int filled;       // How many digits have been entered so far
  final _PinState state;  // The current state (idle, error, etc.)

  @override
  State<_PinDots> createState() => _PinDotsState();
}

// State class for _PinDots. Uses SingleTickerProviderStateMixin for animations.
class _PinDotsState extends State<_PinDots> with SingleTickerProviderStateMixin {
  late final AnimationController _shake; // Controls the shaking animation
  late final Animation<double> _offset;  // Defines the left-right movement values during the shake

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller with a total duration of 520 milliseconds
    _shake = AnimationController(duration: const Duration(milliseconds: 520), vsync: this);
    
    // Create a sequence of movements for the shake effect (left, right, left, right, etc.)
    _offset = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -5.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -2.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -2.0, end: 2.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0), weight: 10),
    ]).animate(_shake); // Attach the sequence to our controller
  }

  @override
  void didUpdateWidget(_PinDots old) {
    super.didUpdateWidget(old);
    // If the state just changed to 'error' from something else, trigger the shake animation
    if (widget.state == _PinState.error && old.state != _PinState.error) {
      _shake.forward(from: 0); // Start shaking from the beginning
    }
  }

  @override
  void dispose() {
    // Always dispose animation controllers when the widget is removed to prevent memory leaks
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Helper booleans to check the current state
    final isError = widget.state == _PinState.error;
    final isSuccess = widget.state == _PinState.success;
    
    // Choose the dot color based on the state: green for success, red for error, indigo otherwise
    final col = isSuccess ? AppColors.score5 : isError ? AppColors.score1 : AppColors.indigo;
    
    // Choose the glow effect color based on the state
    final glow = isSuccess ? const Color(0x8D34D399) : isError ? Colors.transparent : const Color(0x8D818CF8);

    // AnimatedBuilder reconstructs its child every time the animation changes
    return AnimatedBuilder(
      animation: _offset,
      // Transform.translate moves the row left/right based on the animation offset
      builder: (_, child) => Transform.translate(offset: Offset(_offset.value, 0), child: child),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Keep the row as small as possible
        // Generate a list of widgets, one for each PIN digit
        children: List.generate(_pinLength, (i) {
          // A dot is "on" (filled) if its index is less than the number of filled digits
          final on = i < widget.filled;
          return Container(
            width: 12, height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 9), // Space between dots
            decoration: BoxDecoration(
              shape: BoxShape.circle, // Make the container a circle
              color: on ? col : Colors.transparent, // Fill with color if "on", else transparent
              // Draw a border only if the dot is NOT filled
              border: on ? null : Border.all(color: context.rrB7, width: 1.5),
              // Add a glowing shadow if the dot is filled and there's no error
              boxShadow: on && !isError ? [BoxShadow(color: glow, blurRadius: 10)] : [],
            ),
          );
        }),
      ),
    );
  }
}

// ── KeypadBtn ──────────────────────────────────────────────────────────────
// This represents a single button on the numeric keypad (e.g., '1', '2', or 'del').
class _KeypadBtn extends StatefulWidget {
  // Requires child widget (text or icon), tap callback, and optional disabled state
  const _KeypadBtn({required this.child, required this.onTap, this.disabled = false});
  
  final Widget child;
  final VoidCallback onTap;
  final bool disabled;

  @override
  State<_KeypadBtn> createState() => _KeypadBtnState();
}

class _KeypadBtnState extends State<_KeypadBtn> {
  bool _pressed = false; // Tracks if the button is currently being held down

  @override
  Widget build(BuildContext context) {
    // Expanded makes the button take up available horizontal space evenly
    return Expanded(
      child: Opacity(
        // Dim the button if it's disabled
        opacity: widget.disabled ? 0.45 : 1.0,
        child: BouncyButton(
          // Triggered when the user presses their finger down
          onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
          // Triggered when the user lifts their finger up
          onTapUp: widget.disabled ? null : (_) {
            setState(() => _pressed = false);
            widget.onTap(); // Execute the actual tap action
          },
          // Triggered if the user presses down but drags their finger away
          onTapCancel: () => setState(() => _pressed = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Center(
              // AnimatedContainer smoothly transitions between styles
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 75), // Very quick animation
                width: 74, height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Show a faint white circle when pressed
                  color: _pressed ? Colors.white.withValues(alpha: 0.07) : Colors.transparent,
                ),
                child: Center(child: widget.child), // Display the actual number or icon
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Keypad ─────────────────────────────────────────────────────────────────
// This widget builds the entire 4-row numeric keypad.
class _Keypad extends StatelessWidget {
  // Callbacks for when a digit is pressed or the delete button is pressed
  const _Keypad({required this.onDigit, required this.onDelete, required this.disabled});
  
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool disabled;

  // The layout of the keypad, row by row
  static const _rows = [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', 'del']];

  @override
  Widget build(BuildContext context) {
    return Column(
      // Iterate through each row in _rows
      children: _rows.map((row) => Row(
        // Iterate through each key in the current row
        children: row.map((key) {
          // If the key is empty (bottom left corner), just leave a blank space
          if (key == '') return const Expanded(child: SizedBox());
          
          // If the key is 'del', display the custom delete button
          if (key == 'del') {
            return _KeypadBtn(
              onTap: onDelete, 
              disabled: disabled, 
              child: IconDelete(size: 21, color: context.rrT5)
            );
          }
          
          // Otherwise, it's a normal digit button. Display the digit as text.
          return _KeypadBtn(
            onTap: () => onDigit(key), 
            disabled: disabled, 
            child: Text(
              key, 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: context.rrT1, height: 1)
            )
          );
        }).toList(),
      )).toList(), // Convert the mapped items back to a list
    );
  }
}

// ── PinScreen ──────────────────────────────────────────────────────────────
// The main screen that ties everything together. 
// Uses ConsumerStatefulWidget to access Riverpod providers.
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key, required this.onUnlocked, required this.onSetupNew});
  
  final VoidCallback onUnlocked; // Called when login is successful
  final VoidCallback onSetupNew; // Called if user wants to set up a new device

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = ''; // Holds the current PIN entered by the user
  _PinState _state = _PinState.idle; // The current screen state
  
  String? _serviceId; // The ID of the user's service (retrieved from secure storage)
  String? _userName;  // The user's name (retrieved from secure storage)

  @override
  void initState() {
    super.initState();
    _loadIdentity(); // Load saved user info as soon as the screen initializes
  }

  // Helper method to read from secure storage asynchronously
  Future<void> _loadIdentity() async {
    const storage = FlutterSecureStorage();
    // Read the saved service ID and user name
    final sId = await storage.read(key: 'service_id');
    final uName = await storage.read(key: 'user_name');
    
    // Check if the widget is still on screen before updating state
    if (mounted) {
      if (sId == null) {
        // If there's no service ID, the app hasn't been set up yet. Go to setup.
        widget.onSetupNew();
      } else {
        // Otherwise, update the state with the user's info
        setState(() {
          _serviceId = sId;
          _userName = uName ?? sId; // Fallback to service ID if name is missing
        });
      }
    }
  }

  // Method called when the user has entered all 6 digits
  Future<void> _verify() async {
    if (_serviceId == null) return; // Safeguard if service ID is missing
    
    setState(() => _state = _PinState.checking); // Show verification state
    
    try {
      // Get the authentication service from Riverpod
      final auth = ref.read(authServiceProvider);
      // Attempt to log in with the given ID and PIN
      await auth.login(_serviceId!, _pin);
      
      if (!mounted) return;
      setState(() => _state = _PinState.success); // Update state on success
      
      // Wait a short moment to let the user see the success animation
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      
      // Proceed to the unlocked app
      widget.onUnlocked();
    } catch (e) {
      // If login fails (throws an exception)
      if (!mounted) return;
      setState(() => _state = _PinState.error); // Show error state (triggers shake)
      
      // Wait a short moment before clearing the PIN and resetting
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      
      setState(() {
        _pin = ''; // Clear the incorrect PIN
        _state = _PinState.idle; // Go back to normal state
      });
    }
  }

  // Called whenever a keypad digit is pressed
  void _handleDigit(String d) {
    // Ignore input if we are currently checking or if 6 digits are already entered
    if (_state != _PinState.idle || _pin.length >= _pinLength) return;
    
    // Append the new digit to the existing PIN
    final next = _pin + d;
    setState(() => _pin = next);
    
    // If the PIN has reached the required length, verify it immediately
    if (next.length == _pinLength) _verify();
  }

  // Called when the delete button is pressed
  void _handleDelete() {
    // Ignore delete if not in idle state
    if (_state != _PinState.idle) return;
    
    // Remove the last character of the PIN string
    setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    // Disable the keypad if it's currently verifying/error or if we don't have user info yet
    final disabled = _state != _PinState.idle || _serviceId == null;
    
    return Scaffold(
      backgroundColor: context.rrBg, // Set background color from theme
      body: Stack(
        children: [
          const AnimatedOrbsBackground(), // Animated background widget
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false, // Ensures the layout isn't scrollable if it fits
                  child: Column(
                    children: [
                      // Expanded section for the top part (avatar, title, PIN dots)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 32),
                            // User avatar circle
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.indigo.withValues(alpha: 0.08),
                                border: Border.all(color: AppColors.indigo.withValues(alpha: 0.20), width: 1.5),
                              ),
                              child: Center(
                                // Show first letter of user name, or '-' if loading
                                child: Text(
                                  _userName?.substring(0, 1).toUpperCase() ?? '-', 
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.indigo)
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Welcome text (localized)
                            Text(
                              tr('Welcome back', ref), 
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: context.rrT2)
                            ),
                            const SizedBox(height: 4),
                            // User name or loading indicator
                            Text(
                              _userName ?? tr('Loading...', ref), 
                              style: TextStyle(fontSize: 14, color: context.rrT5)
                            ),
                            const SizedBox(height: 32),
                            // Display the animated PIN dots
                            _PinDots(filled: _pin.length, state: _state),
                            const SizedBox(height: 16),
                            // Small label showing current status (verifying, error, etc.)
                            SizedBox(height: 32, child: Center(child: _stateLabel(context))),
                          ],
                        ),
                      ),
                      // The numeric keypad
                      _Keypad(onDigit: _handleDigit, onDelete: _handleDelete, disabled: disabled),
                      const SizedBox(height: 16),
                      // Button to reset/setup new device
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: BouncyButton(
                          onTap: widget.onSetupNew,
                          child: Text(
                            tr('New device? Set up this device', ref), 
                            style: TextStyle(fontSize: 11, color: context.rrT7)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to return different text widgets based on current state
  Widget _stateLabel(BuildContext context) {
    switch (_state) {
      case _PinState.error: 
        return Text(tr('Incorrect PIN — try again', ref), style: const TextStyle(fontSize: 13, color: AppColors.score1));
      case _PinState.checking: 
        return Text(tr('Verifying…', ref), style: TextStyle(fontSize: 13, color: context.rrT6));
      case _PinState.success: 
        return Text(tr('Unlocked', ref), style: const TextStyle(fontSize: 13, color: AppColors.score5));
      case _PinState.idle: 
        return const SizedBox.shrink(); // Show nothing when idle
    }
  }
}
