// Import the core Flutter material design library, which provides UI components like Scaffold, Text, and TextField.
import 'package:flutter/material.dart';
// Import Riverpod, a state management library for Flutter, which helps manage and share state across the app.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import custom color definitions for the app to maintain a consistent theme.
import '../theme/colors.dart';
// Import the authentication service, which handles user actions like logging in and changing the PIN.
import '../services/auth_service.dart';
// Import a custom card widget used to display content with a specific design.
import '../widgets/rr_card.dart';
// Import the translations file to support multiple languages in the app.
import '../data/translations.dart';
// Import a custom button widget that provides a bouncing animation when tapped.
import '../widgets/bouncy_button.dart';

// Define the ChangePinScreen as a ConsumerStatefulWidget, which means it has mutable state and can interact with Riverpod providers.
class ChangePinScreen extends ConsumerStatefulWidget {
  // Constructor for the ChangePinScreen, accepting an optional key for widget identification.
  const ChangePinScreen({super.key});

  // Create the mutable state for this widget.
  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

// The state class for ChangePinScreen where the logic and UI are implemented.
class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  // Controller for the text field where the user enters their current PIN.
  final _currentPinCtrl = TextEditingController();
  // Controller for the text field where the user enters their new PIN.
  final _newPinCtrl = TextEditingController();
  // Controller for the text field where the user confirms their new PIN.
  final _confirmPinCtrl = TextEditingController();

  // Boolean variable to track if a network request is currently loading.
  bool _isLoading = false;
  // String variable to store and display any error messages that occur during the PIN change process.
  String? _errorMsg;

  // The dispose method is called when the widget is permanently removed from the screen.
  @override
  void dispose() {
    // Clean up the controllers to free up memory resources.
    _currentPinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    // Always call super.dispose() at the end.
    super.dispose();
  }

  // An asynchronous method to handle the submission of the PIN change form.
  Future<void> _submit() async {
    // Read and trim the text from all three input controllers to remove any accidental leading/trailing spaces.
    final current = _currentPinCtrl.text.trim();
    final newPin = _newPinCtrl.text.trim();
    final confirm = _confirmPinCtrl.text.trim();

    // Check if any of the entered PINs are not exactly 6 digits long.
    if (current.length != 6 || newPin.length != 6 || confirm.length != 6) {
      // If validation fails, update the UI to show an error message.
      setState(() => _errorMsg = tr('PINs must be exactly 6 digits.', ref));
      // Stop further execution of the method.
      return;
    }
    // Check if the new PIN and the confirm PIN do not match.
    if (newPin != confirm) {
      // If they don't match, show a specific error message.
      setState(() => _errorMsg = tr('New PINs do not match.', ref));
      // Stop further execution.
      return;
    }

    // If validation passes, update the state to show the loading indicator and clear any previous errors.
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    // Start a try-catch block to handle potential errors during the network request.
    try {
      // Read the authServiceProvider to access auth logic, and call the changePin method.
      await ref.read(authServiceProvider).changePin(current, newPin);
      // Ensure the widget is still in the tree before proceeding (avoids errors if the user left the screen).
      if (!mounted) return;
      // Show a success dialog to inform the user that the PIN was changed successfully.
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          // Set the background color using the current theme context extension.
          backgroundColor: context.rrBgc,
          // Round the corners of the dialog box.
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          // Set the title of the dialog, translating 'Success' to the active language.
          title: Text(tr('Success', ref), style: TextStyle(color: context.rrT1, fontWeight: FontWeight.w600)),
          // Set the content message of the dialog.
          content: Text(tr('PIN successfully changed.', ref), style: TextStyle(color: context.rrT3)),
          // Provide an 'OK' button to dismiss the dialog.
          actions: [
            TextButton(
              // When pressed, pop the dialog off the screen.
              onPressed: () => Navigator.of(context).pop(),
              // Style the 'OK' button text.
              child: Text(tr('OK', ref), style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      // Check mounted status again after the dialog is closed.
      if (!mounted) return;
      // Pop the change PIN screen itself to return to the previous screen.
      Navigator.of(context).pop();
    } catch (e) {
      // If the API call fails, update the state to stop loading and show an error message.
      setState(() {
        _isLoading = false;
        _errorMsg = tr('Failed to change PIN. Check your current PIN.', ref);
      });
    }
  }

  // A helper method to build the input fields consistently for current, new, and confirm PINs.
  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      // Align children to the start (left) of the column.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display the label above the text field.
        Text(label, style: TextStyle(fontSize: 12, color: context.rrT4)),
        // Add a small vertical space.
        const SizedBox(height: 8),
        // The actual text input field.
        TextField(
          // Attach the specific controller passed to this helper method.
          controller: controller,
          // Hide the typed characters, replacing them with dots since this is a password/PIN field.
          obscureText: true,
          // Show a number pad keyboard instead of a standard text keyboard.
          keyboardType: TextInputType.number,
          // Restrict input to exactly 6 characters.
          maxLength: 6,
          // Style the input text, adding letter spacing so the dots are spaced out.
          style: TextStyle(fontSize: 16, color: context.rrT1, letterSpacing: 4),
          decoration: InputDecoration(
            // Hide the default character counter that appears below the field.
            counterText: '',
            // Enable a background fill color for the text field.
            filled: true,
            // Set the fill color using the theme context.
            fillColor: context.rrIn,
            // Add padding inside the text field so the text isn't cramped.
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            // Define the border style when the field is not focused.
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.rrIb)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.rrIb)),
            // Define a highlighted border style when the user is actively typing in the field.
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.indigo.withValues(alpha: 0.35))),
          ),
        ),
      ],
    );
  }

  // The build method is called every time the widget needs to be drawn on the screen.
  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic visual structure for a screen.
    return Scaffold(
      // Set the background color of the entire screen using the theme.
      backgroundColor: context.rrBg,
      // SafeArea ensures the UI isn't hidden behind the device's notch or status bar.
      body: SafeArea(
        // SingleChildScrollView allows the screen to scroll if the content is taller than the display, preventing overflow errors.
        child: SingleChildScrollView(
          // Add padding around the edges of the scrollable content.
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            // Align all content in the column to the start (left side).
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A custom bouncy button serving as a back button.
              BouncyButton(
                // When tapped, return to the previous screen.
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  // Make the row only as wide as its children (icon + text).
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A left-pointing chevron icon.
                    Icon(Icons.chevron_left, size: 18, color: context.rrT4),
                    // Text indicating this button goes back to the Settings screen.
                    Text(tr('Settings', ref), style: TextStyle(fontSize: 14, color: context.rrT4)),
                  ],
                ),
              ),
              // Vertical spacing after the back button.
              const SizedBox(height: 24),
              // The main title of the screen.
              Text(tr('Change PIN', ref), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: context.rrT1)),
              // Small vertical spacing.
              const SizedBox(height: 8),
              // Subtitle providing instructions to the user.
              Text(tr('Update your 6-digit device PIN.', ref), style: TextStyle(fontSize: 14, color: context.rrT4)),
              // Vertical spacing before the input fields.
              const SizedBox(height: 32),

              // A custom card widget that visually groups the input fields.
              RrCard(
                child: Column(
                  children: [
                    // Generate the current PIN input field.
                    _buildField(tr('Current PIN', ref), _currentPinCtrl),
                    // Vertical spacing.
                    const SizedBox(height: 20),
                    // Generate the new PIN input field.
                    _buildField(tr('New PIN', ref), _newPinCtrl),
                    // Vertical spacing.
                    const SizedBox(height: 20),
                    // Generate the confirm new PIN input field.
                    _buildField(tr('Confirm New PIN', ref), _confirmPinCtrl),
                  ],
                ),
              ),

              // Conditionally display the error message only if it is not null.
              if (_errorMsg != null)
                Padding(
                  // Add padding above the error message.
                  padding: const EdgeInsets.only(top: 20),
                  // Display the error message text in a specific error color (score1).
                  child: Text(_errorMsg!, style: const TextStyle(fontSize: 13, color: AppColors.score1)),
                ),

              // Vertical spacing before the submit button.
              const SizedBox(height: 32),
              // Custom bouncy button for submitting the form.
              BouncyButton(
                // If currently loading, disable the button (null); otherwise, call _submit.
                onTap: _isLoading ? null : _submit,
                // A container that animates its properties (like size or color) when changed.
                child: AnimatedContainer(
                  // The animation takes 200 milliseconds to complete.
                  duration: const Duration(milliseconds: 200),
                  // Make the button as wide as possible.
                  width: double.infinity,
                  // Add vertical padding inside the button.
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    // Round the corners of the button.
                    borderRadius: BorderRadius.circular(14),
                    // Set the button color to indigo.
                    color: AppColors.indigo,
                    // Add a soft shadow below the button to make it pop out.
                    boxShadow: [
                      BoxShadow(color: AppColors.indigo.withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Center(
                    // If loading, show a small circular progress indicator; otherwise, show the button text.
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
