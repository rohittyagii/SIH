// Import the core Flutter material design library, which provides UI widgets like Scaffold, Text, and TextField.
import 'package:flutter/material.dart';
// Import Riverpod, which is a state management library used to manage global state and dependencies in the app.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import the secure storage package, which allows us to safely save sensitive data like service IDs on the device.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Import the custom color definitions used throughout the app for consistent styling.
import '../theme/colors.dart';
// Import custom icon widgets created for the app, such as IconShield.
import '../widgets/icon_widgets.dart';
// Import a custom card widget (RrCard) used for consistent container styling.
import '../widgets/rr_card.dart';
// Import the authentication service, which handles login and device activation API calls.
import '../services/auth_service.dart';
// Import the translations module, which provides the 'tr' function for multi-language support.
import '../data/translations.dart';

// ── ActivationScreen ────────────────────────────────────────────────────────
// Define the ActivationScreen class as a ConsumerStatefulWidget. 
// "Consumer" means it can read Riverpod state, and "Stateful" means it can manage its own internal changing data.
class ActivationScreen extends ConsumerStatefulWidget {
  // The constructor requires an 'onActivated' callback function which will be called when login/activation succeeds.
  const ActivationScreen({super.key, required this.onActivated});
  // This variable holds the callback function passed from the parent widget.
  final VoidCallback onActivated;

  // The createState method is required for all StatefulWidgets. It creates the mutable state object for this widget.
  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

// This is the state class for ActivationScreen, where all the logic and UI building happens.
class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  // A boolean flag to toggle between "Login" mode and "Activation" mode. Initially false (Activation mode).
  bool _isLoginMode = false;
  // A string to store the user's Service ID when in login mode.
  String _serviceId = '';
  // A string to store the raw 8-character activation code.
  String _raw = '';
  // A string to store the user's full name.
  String _name = '';
  // A string to store the 6-digit PIN entered by the user.
  String _pin = '';
  // A boolean flag to indicate if a network request is currently in progress (shows loading state).
  bool _loading = false;
  // A boolean flag to indicate if the server is taking a long time to respond (e.g., waking up from sleep).
  bool _slowRequest = false;
  // A nullable string to hold any error messages that need to be displayed to the user.
  String? _error;

  // A calculated getter that formats the raw 8-character code with a hyphen in the middle (e.g., "ABCD-EFGH").
  String get _formatted =>
      // If the raw code is longer than 4 characters, insert a hyphen after the 4th character. Otherwise, return the raw code.
      _raw.length > 4 ? '${_raw.substring(0, 4)}-${_raw.substring(4)}' : _raw;
      
  // A calculated getter to check if the user has filled out all necessary fields correctly.
  bool get _isReady => _isLoginMode
      // In Login mode: the Service ID must not be empty, and the PIN must be exactly 6 characters long.
      ? _serviceId.trim().isNotEmpty && _pin.length == 6
      // In Activation mode: the code must be 8 characters, name at least 2 characters, and PIN exactly 6 characters.
      : _raw.length == 8 && _name.trim().length >= 2 && _pin.length == 6;
      
  // A calculated getter to determine if the submit button should be clickable (active).
  // It is active if the form is ready AND we are not currently loading.
  bool get _active => _isReady && !_loading;

  // A function to handle changes when the user types in the activation code text field.
  void _handleCode(String text) {
    // Convert the entered text to uppercase and remove any characters that are not letters (A-Z) or numbers (0-9).
    final clean = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    // Update the state with the cleaned text, limiting it to a maximum of 8 characters.
    setState(() => _raw = clean.length > 8 ? clean.substring(0, 8) : clean);
  }

  // An asynchronous function that runs when the user taps the submit button.
  Future<void> _submit() async {
    // If the form is not ready or a request is already loading, exit the function immediately.
    if (!_isReady || _loading) return;
    
    // Update the UI state to show that loading has started, and clear any previous errors or slow request warnings.
    setState(() {
      _loading = true;
      _slowRequest = false;
      _error = null;
    });

    // Set a timer for 5 seconds. If the request hasn't finished by then, we assume the server is waking up (slow).
    // After 5 seconds, this inner function runs.
    Future.delayed(const Duration(seconds: 5), () {
      // Check if the widget is still on the screen (mounted) and still loading.
      // If so, update the state to show the slow request warning message.
      if (mounted && _loading) setState(() => _slowRequest = true);
    });

    // Start a try-catch block to handle any errors that occur during the network request.
    try {
      // Read the authentication service from Riverpod so we can make API calls.
      final auth = ref.read(authServiceProvider);
      // Declare a variable to hold the user data returned by the server.
      Map<String, dynamic> user;

      // Check if we are currently in Login mode.
      if (_isLoginMode) {
        // If in login mode, call the login API method with the trimmed Service ID and PIN.
        user = await auth.login(_serviceId.trim(), _pin);
      } else {
        // If in activation mode, call the activateDevice API method with the formatted code, PIN, and trimmed name.
        user = await auth.activateDevice(_formatted, _pin, _name.trim());
      }

      // Create an instance of FlutterSecureStorage to save data securely on the device.
      const storage = FlutterSecureStorage();
      // Write the 'service_id' returned by the server into secure storage.
      await storage.write(key: 'service_id', value: user['service_id']);
      // Write the 'username' returned by the server into secure storage.
      await storage.write(key: 'user_name', value: user['username']);

      // Check if the widget is still on the screen before triggering the callback.
      if (!mounted) return;
      // Call the onActivated callback passed from the parent to navigate away from this screen.
      widget.onActivated();
    } catch (e) {
      // This block runs if any error occurs during the try block (e.g., wrong password, network failure).
      // Check if the widget is still on the screen before updating the UI.
      if (!mounted) return;
      
      // Convert the error object to a string for checking what went wrong.
      final msg = e.toString();
      // Declare a variable to hold the user-friendly error message.
      String errorText;
      
      // Check if the error message contains '400' (Bad Request - usually meaning wrong input).
      if (msg.contains('400')) {
        // Set the error text based on whether it's login or activation mode, using the 'tr' function for translation.
        errorText = _isLoginMode
            ? tr('Invalid credentials.', ref)
            : tr('Invalid or already used code.', ref);
      // Check if the error message contains '401' (Unauthorized - wrong password/pin).
      } else if (msg.contains('401')) {
        // Set the error text for invalid credentials.
        errorText = tr('Invalid credentials.', ref);
      // Check if the error is related to network connection issues (timeout, socket error).
      } else if (msg.contains('timeout') ||
          msg.contains('SocketException') ||
          msg.contains('connection')) {
        // Show a message explaining that the server might be waking up (common for free cloud hosting).
        errorText =
            tr('Server is waking up. Please try again in 30 seconds.', ref);
      } else {
        // For any other unexpected errors, show a generic failure message based on the current mode.
        errorText = _isLoginMode
            ? tr('Login failed. Please try again.', ref)
            : tr('Activation failed. Please try again.', ref);
      }
      
      // Update the UI state to stop loading, clear the slow request flag, and display the error message.
      setState(() {
        _loading = false;
        _slowRequest = false;
        _error = errorText;
      });
    }
  }

  // The build method is called whenever the state changes. It describes the UI of the widget.
  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic visual structure of a screen (like background color).
    return Scaffold(
      // Set the background color of the screen using a custom extension on BuildContext (context.rrBg).
      backgroundColor: context.rrBg,
      // SafeArea ensures that the UI is not obscured by system UI elements like notches or status bars.
      body: SafeArea(
        // SingleChildScrollView allows the screen to be scrollable, preventing overflow issues on small screens or when the keyboard appears.
        child: SingleChildScrollView(
          // Add padding around the content: 24 pixels on left and right, 32 on bottom.
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          // Column arranges its children vertically from top to bottom.
          child: Column(
            // Align all children to the start (left side) of the column.
            crossAxisAlignment: CrossAxisAlignment.start,
            // The list of widgets inside the column.
            children: [
              // Center aligns its child horizontally in the middle.
              Center(
                // Padding adds space around the shield icon (32 pixels on top, 24 on bottom).
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 24),
                  // Container is like a div in HTML; here it creates a square box for the icon.
                  child: Container(
                    // Set the width of the box to 64 pixels.
                    width: 64,
                    // Set the height of the box to 64 pixels.
                    height: 64,
                    // BoxDecoration allows us to style the Container (colors, borders, rounded corners).
                    decoration: BoxDecoration(
                      // Make the corners rounded with an 18-pixel radius.
                      borderRadius: BorderRadius.circular(18),
                      // Set the background color to a very transparent indigo.
                      color: AppColors.indigo.withValues(alpha: 0.10),
                      // Add a thin border around the box using a slightly less transparent indigo.
                      border: Border.all(
                          color: AppColors.indigo.withValues(alpha: 0.24)),
                    ),
                    // Place the custom IconShield widget in the center of the box.
                    child: const Center(
                        child: IconShield(size: 28, color: AppColors.indigo)),
                  ),
                ),
              ),
              // Text widget displays the main title of the screen based on the current mode (Login vs Activation).
              Text(
                // If in login mode, show "Login to your account", else show "Activate this device". Both are translated.
                _isLoginMode
                    ? tr('Login to your account', ref)
                    : tr('Activate this device', ref),
                // Style the title text.
                style: TextStyle(
                    fontSize: 27, // Set font size to 27 pixels.
                    fontWeight: FontWeight.w600, // Make the text semi-bold.
                    color: context.rrT1, // Use the primary text color from the theme.
                    height: 1.25), // Set the line height.
              ),
              // SizedBox adds 14 pixels of vertical space.
              const SizedBox(height: 14),
              // Text widget displays the subtitle instructions based on the current mode.
              Text(
                // Determine the subtitle text based on mode and translate it.
                _isLoginMode
                    ? tr('Enter your Service ID and 6-digit PIN.', ref)
                    : tr(
                        'Enter your code, full name, and create a 6-digit PIN.',
                        ref),
                // Style the subtitle text.
                style:
                    TextStyle(fontSize: 14, color: context.rrT3, height: 1.65), // Font size 14, secondary text color.
              ),
              // Check if there is an error message to display. The '...' is the spread operator to add multiple widgets if true.
              if (_error != null) ...[
                // Add 16 pixels of vertical space before the error message.
                const SizedBox(height: 16),
                // A container to hold the error message and give it a colored background.
                Container(
                  // Add 12 pixels of padding inside the container.
                  padding: const EdgeInsets.all(12),
                  // Style the error container.
                  decoration: BoxDecoration(
                    // Give it a transparent red-ish background (score1 is likely a red color).
                    color: AppColors.score1.withValues(alpha: 0.08),
                    // Round the corners of the error box.
                    borderRadius: BorderRadius.circular(10),
                    // Add a border with the error color.
                    border: Border.all(
                        color: AppColors.score1.withValues(alpha: 0.25)),
                  ),
                  // Row arranges its children horizontally.
                  child: Row(
                    children: [
                      // Display an error icon.
                      const Icon(Icons.error_outline,
                          color: AppColors.score1, size: 16),
                      // Add 8 pixels of horizontal space between icon and text.
                      const SizedBox(width: 8),
                      // Expanded makes the Text widget take up all remaining horizontal space, allowing it to wrap if long.
                      Expanded(
                          // Display the actual error message string.
                          child: Text(_error!,
                              // Style the error text to match the error color.
                              style: const TextStyle(
                                  color: AppColors.score1, fontSize: 13))),
                    ],
                  ),
                ),
              // If there's no error, but we are loading and it's a slow request, show a warning.
              ] else if (_loading && _slowRequest) ...[
                // Add 16 pixels of vertical space.
                const SizedBox(height: 16),
                // A container to hold the slow request warning.
                Container(
                  // Add 12 pixels of padding.
                  padding: const EdgeInsets.all(12),
                  // Style the warning container.
                  decoration: BoxDecoration(
                    // Give it a transparent indigo background.
                    color: AppColors.indigo.withValues(alpha: 0.08),
                    // Round the corners.
                    borderRadius: BorderRadius.circular(10),
                    // Add an indigo border.
                    border: Border.all(
                        color: AppColors.indigo.withValues(alpha: 0.20)),
                  ),
                  // Arrange children horizontally.
                  child: Row(
                    children: [
                      // A small box with fixed width and height for the loading spinner.
                      const SizedBox(
                        width: 14,
                        height: 14,
                        // The actual loading spinner widget.
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.indigo),
                      ),
                      // Add 8 pixels of horizontal space.
                      const SizedBox(width: 8),
                      // Expanded to take up remaining space for the text.
                      Expanded(
                        // Display the translated warning message.
                        child: Text(
                          tr('Server is starting up, please wait…', ref),
                          // Style the warning text.
                          style: const TextStyle(
                              color: AppColors.indigo, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Add 24 pixels of vertical space.
              const SizedBox(height: 24),
              // Opacity widget makes its child partially transparent if loading, providing visual feedback.
              Opacity(
                // Set opacity to 55% if loading, otherwise 100% (fully visible).
                opacity: _loading ? 0.55 : 1.0,
                // RrCard is a custom widget for displaying a styled card with a shadow/border.
                child: RrCard(
                  // Column arranges the text fields vertically inside the card.
                  child: Column(
                    children: [
                      // If we are in Login mode, show the login fields.
                      if (_isLoginMode) ...[
                        // Label for the Service ID field.
                        Text(tr('Service ID', ref),
                            // Style the label text.
                            style:
                                TextStyle(fontSize: 12, color: context.rrT4)),
                        // Add 8 pixels of vertical space.
                        const SizedBox(height: 8),
                        // Text input field for the user to type their Service ID.
                        TextField(
                          // Disable the text field if a network request is loading.
                          enabled: !_loading,
                          // Center the text inside the input field.
                          textAlign: TextAlign.center,
                          // Automatically capitalize all characters the user types.
                          textCapitalization: TextCapitalization.characters,
                          // When the text changes, update the _serviceId state variable.
                          onChanged: (v) => setState(() => _serviceId = v),
                          // Style the text entered by the user.
                          style: TextStyle(fontSize: 18, color: context.rrT1),
                          // Define how the input field looks (hint text, borders).
                          decoration: InputDecoration(
                              // Placeholder text shown when the field is empty.
                              hintText: 'e.g. SRV-1234',
                              // Style the placeholder text.
                              hintStyle: TextStyle(color: context.rrT7),
                              // Remove the default underline border from the text field.
                              border: InputBorder.none),
                        ),
                        // Add 16 pixels of vertical space.
                        const SizedBox(height: 16),
                        // Label for the 6-digit PIN field (which is defined after the if/else block).
                        Text(tr('6-digit PIN', ref),
                            style:
                                TextStyle(fontSize: 12, color: context.rrT4)),
                      // If we are NOT in Login mode (so we are in Activation mode), show activation fields.
                      ] else ...[
                        // Label for the Activation code field.
                        Text(tr('Activation code', ref),
                            style:
                                TextStyle(fontSize: 12, color: context.rrT4)),
                        // Add 8 pixels of vertical space.
                        const SizedBox(height: 8),
                        // Text input field for the activation code.
                        TextField(
                          // Disable if loading.
                          enabled: !_loading,
                          // Center the text.
                          textAlign: TextAlign.center,
                          // Capitalize all characters automatically.
                          textCapitalization: TextCapitalization.characters,
                          // Call the _handleCode function whenever the text changes to format and limit it.
                          onChanged: _handleCode,
                          // Style the entered text to look like code (monospace font, large spacing).
                          style: TextStyle(
                              fontFamily: 'JetBrains Mono', // Use a monospace font for codes.
                              fontSize: 24,
                              letterSpacing: 6, // Add space between letters for readability.
                              color: context.rrT1),
                          // Define the input field decoration.
                          decoration: InputDecoration(
                              // Placeholder format.
                              hintText: 'XXXX-XXXX',
                              // Style placeholder to match the input text styling.
                              hintStyle: TextStyle(
                                  color: context.rrT7, letterSpacing: 6),
                              // Remove border.
                              border: InputBorder.none),
                          // Provide a controller to manually control the text field's content.
                          // This is used to display the _formatted code (with the hyphen).
                          controller: TextEditingController(text: _formatted)
                            // Keep the cursor at the end of the text after formatting.
                            ..selection = TextSelection.collapsed(
                                offset: _formatted.length),
                        ),
                        // Add 16 pixels of vertical space.
                        const SizedBox(height: 16),
                        // Label for the Full Name field.
                        Text(tr('Full Name', ref),
                            style:
                                TextStyle(fontSize: 12, color: context.rrT4)),
                        // Text input field for the user's full name.
                        TextField(
                          // Disable if loading.
                          enabled: !_loading,
                          // Center the text.
                          textAlign: TextAlign.center,
                          // Update the _name state variable when text changes.
                          onChanged: (v) => setState(() => _name = v),
                          // Style the text.
                          style: TextStyle(fontSize: 18, color: context.rrT1),
                          // Define the input field decoration.
                          decoration: InputDecoration(
                              // Placeholder example name.
                              hintText: 'e.g. Constable Ravi',
                              // Style placeholder.
                              hintStyle: TextStyle(color: context.rrT7),
                              // Remove border.
                              border: InputBorder.none),
                        ),
                        // Add 16 pixels of vertical space.
                        const SizedBox(height: 16),
                        // Label for creating the PIN.
                        Text(tr('Create 6-digit PIN', ref),
                            style:
                                TextStyle(fontSize: 12, color: context.rrT4)),
                      ],
                      // This PIN field is shared by both Login and Activation modes.
                      TextField(
                        // Disable if loading.
                        enabled: !_loading,
                        // Center the text.
                        textAlign: TextAlign.center,
                        // Set the keyboard to show a number pad.
                        keyboardType: TextInputType.number,
                        // Limit the input to exactly 6 characters.
                        maxLength: 6,
                        // Hide the entered text (show dots) because it's a secret PIN.
                        obscureText: true,
                        // Update the _pin state variable when text changes.
                        onChanged: (v) => setState(() => _pin = v),
                        // Style the PIN input to use monospace font and wide spacing.
                        style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 24,
                            letterSpacing: 8,
                            color: context.rrT1),
                        // Define the input field decoration.
                        decoration: InputDecoration(
                            // Placeholder showing 6 asterisks.
                            hintText: '******',
                            // Style placeholder to match the input.
                            hintStyle: TextStyle(
                                color: context.rrT7, letterSpacing: 8),
                            // Remove border.
                            border: InputBorder.none,
                            // Hide the character counter (e.g., "6/6") that maxLength adds by default.
                            counterText: ''),
                      ),
                    ],
                  ),
                ),
              ),
              // Add 32 pixels of vertical space before the submit button.
              const SizedBox(height: 32),
              // GestureDetector allows us to detect when the user taps on the button area.
              GestureDetector(
                // If the form is _active (ready and not loading), assign the _submit function to onTap. Otherwise, assign null (disabled).
                onTap: _active ? _submit : null,
                // AnimatedContainer creates a box that smoothly animates changes to its styling (like color).
                child: AnimatedContainer(
                  // The animation takes 200 milliseconds to complete.
                  duration: const Duration(milliseconds: 200),
                  // Make the button as wide as possible.
                  width: double.infinity,
                  // Add 16 pixels of vertical padding inside the button.
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  // Style the button.
                  decoration: BoxDecoration(
                    // Round the corners.
                    borderRadius: BorderRadius.circular(14),
                    // If active, use solid indigo color. If not active, use transparent indigo to look disabled.
                    color: _active
                        ? AppColors.indigo
                        : AppColors.indigo.withValues(alpha: 0.14),
                  ),
                  // Center the text inside the button.
                  child: Center(
                    // The text inside the button.
                    child: Text(
                      // Determine what text to show on the button.
                      _loading
                          // If loading, show "Logging in..." or "Activating..." based on mode.
                          ? (_isLoginMode
                              ? tr('Logging in…', ref)
                              : tr('Activating…', ref))
                          // If not loading, show "Login" or "Activate" based on mode.
                          : (_isLoginMode
                              ? tr('Login', ref)
                              : tr('Activate', ref)),
                      // Style the button text.
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600, // Semi-bold text.
                          // If active, use dark color. If not active, use transparent indigo.
                          color: _active
                              ? const Color(0xFF0C1220)
                              : AppColors.indigo.withValues(alpha: 0.45)),
                    ),
                  ),
                ),
              ),
              // Add 24 pixels of vertical space.
              const SizedBox(height: 24),
              // Center aligns the mode-switching text button.
              Center(
                // GestureDetector detects taps on the text.
                child: GestureDetector(
                  // If loading, disable the tap (null). Otherwise, provide a function to switch modes.
                  onTap: _loading
                      ? null
                      : () {
                          // Call setState to rebuild the UI with the new mode.
                          setState(() {
                            // Toggle the boolean mode flag (true becomes false, false becomes true).
                            _isLoginMode = !_isLoginMode;
                            // Clear any displayed errors.
                            _error = null;
                            // Clear the entered PIN.
                            _pin = '';
                          });
                        },
                  // Add 8 pixels of padding all around the text to make the tap target larger.
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    // Display the text for the button.
                    child: Text(
                      // If in Login mode, prompt them to switch to Activation mode. If in Activation mode, prompt them to switch to Login mode.
                      _isLoginMode
                          ? tr('New device? Activate with a code', ref)
                          : tr('Already have credentials? Login instead', ref),
                      // Style the text link.
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
