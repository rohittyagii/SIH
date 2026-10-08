// Import the core Flutter material design library. This gives us access to pre-built UI components like Scaffold, Text, Column, etc.
import 'package:flutter/material.dart';

// Import the Riverpod package. Riverpod is used for state management, helping us manage the flow of data across the app.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the url_launcher package. This helps us launch phone calls or SMS messages when a user taps a button.
import 'package:url_launcher/url_launcher.dart';

// Import our custom color theme file to maintain consistent colors throughout the app.
import '../theme/colors.dart';

// Import custom icon widgets that we use in our UI, such as the shield icon.
import '../widgets/icon_widgets.dart';

// Import our custom card widget, which provides a consistent styling for the content blocks.
import '../widgets/rr_card.dart';

// Import the support service which handles backend communication, like sending a callback request.
import '../services/support_service.dart';

// Import our translation helper to make sure our text can be displayed in multiple languages.
import '../data/translations.dart';

// ── SupportScreen ─────────────────────────────────────────────────────────────
// This is the SupportScreen class. It is a ConsumerStatefulWidget, meaning it can hold its own state (data that changes) and can also interact with Riverpod to read external data.
class SupportScreen extends ConsumerStatefulWidget {
  // A standard constructor for the widget, passing the optional key to the superclass.
  const SupportScreen({super.key});

  // This method creates the associated state class where the logic and UI building happen.
  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

// This is the state class for SupportScreen. It holds variables and the build method to display the screen.
class _SupportScreenState extends ConsumerState<SupportScreen> {
  // A boolean variable to track if a callback request is currently being processed by the server.
  bool _requesting = false;
  
  // A boolean variable to track if a callback request has already been successfully sent.
  bool _requested = false;
  
  // This asynchronous method handles the logic when the user taps the "Contact welfare office" button.
  Future<void> _handleCallback(WidgetRef ref) async {
    // If we are already requesting or have already requested a callback, do nothing to prevent multiple requests.
    if (_requesting || _requested) return;
    
    // Update the UI state to show that we are currently requesting.
    setState(() => _requesting = true);
    
    try {
      // Use Riverpod to read the support service provider and call the 'requestCallback' method to notify the backend.
      await ref.read(supportServiceProvider).requestCallback();
      
      // Check if the widget is still in the widget tree before updating the UI after the async gap.
      if (!mounted) return;
      
      // Update the state to indicate the request has finished and was successful.
      setState(() {
        _requesting = false;
        _requested = true;
      });
      
      // Show a success message (SnackBar) at the bottom of the screen.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Text widget displaying a translated success message.
          content: Text(tr('Callback requested. Your welfare officer will contact you shortly.', ref)), 
          // Background color of the snackbar indicating a successful action.
          backgroundColor: AppColors.score5
        )
      );
    } catch (e) {
      // If an error occurs during the backend request, this catch block runs.
      // Check if the widget is still mounted before proceeding.
      if (!mounted) return;
      
      // Reset the requesting state back to false since the request failed.
      setState(() => _requesting = false);
      
      // Show an error message (SnackBar) to inform the user that the request failed.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Text widget displaying a translated error message.
          content: Text(tr('Failed to request callback. Please try again.', ref)), 
          // Background color of the snackbar indicating an error or warning.
          backgroundColor: AppColors.score1
        )
      );
    }
  }

  // The build method is called every time the widget needs to be drawn on the screen.
  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic structural layout for a material design app screen.
    return Scaffold(
      // Set the background color of the screen using an extension property from the theme.
      backgroundColor: context.rrBg,
      // A SingleChildScrollView allows the user to scroll vertically if the content exceeds screen height.
      body: SingleChildScrollView(
        // Add padding around the entire scrollable area. The top padding dynamically adjusts based on the device's status bar (notch).
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 24, 16, 120),
          // Column stacks its child widgets vertically.
          child: Column(
            // Align all children inside the column to the left (start of the cross axis).
            crossAxisAlignment: CrossAxisAlignment.start,
            // A list of widgets that form the layout.
            children: [
              // Display a translated heading text.
              Text(tr('Resources & support', ref),
                  // Style the text with specific size, font weight, and color.
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.rrT1)),
              // A SizedBox is used here to add a fixed 4-pixel vertical space between widgets.
              const SizedBox(height: 4),
              // Display a smaller, translated subtitle text.
              Text(tr('Confidential support, available any time', ref),
                  style: TextStyle(fontSize: 13, color: context.rrT4)),
              // Add a larger 24-pixel vertical space before the first card.
              const SizedBox(height: 24),
              // Welfare officer card: Uses our custom RrCard widget for a consistent container style.
              RrCard(
                // Stack items vertically inside the card.
                child: Column(
                  children: [
                    // A Row widget to place the icon and the text side-by-side horizontally.
                    Row(
                      // Align items in the row to the top.
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A container holding the shield icon.
                        Container(
                          // Fixed width and height for the icon container.
                          width: 32,
                          height: 32,
                          // Add decoration like rounded corners and a background color with some transparency.
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: AppColors.indigo.withValues(alpha: 0.12),
                          ),
                          // Center the shield icon inside the container.
                          child: const Center(
                              child: IconShield(
                                  size: 14, color: AppColors.indigo)),
                        ),
                        // Add horizontal space between the icon and the text.
                        const SizedBox(width: 12),
                        // Expanded widget forces the column inside it to fill all remaining horizontal space.
                        Expanded(
                          // Another Column to stack title and description text vertically.
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // The title text for talking to a welfare officer.
                              Text(tr('Talk to your welfare officer', ref),
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: context.rrT1)),
                              // A small vertical gap.
                              const SizedBox(height: 4),
                              // The description text explaining confidentiality.
                              Text(
                                  tr('Conversations are confidential unless you decide otherwise. No formal record is created.', ref),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: context.rrT3,
                                      height: 1.6)), // Line height is increased for readability.
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Add vertical space before the button.
                    const SizedBox(height: 16),
                    // GestureDetector makes its child interactive, responding to taps.
                    GestureDetector(
                      // Call the _handleCallback function when the user taps this area.
                      onTap: () => _handleCallback(ref),
                      // Container used as a button UI.
                      child: Container(
                        // Make the button stretch to full available width.
                        width: double.infinity,
                        // Add vertical padding inside the button.
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        // Decorate the button to change appearance depending on whether the callback was requested.
                        decoration: BoxDecoration(
                          // Rounded corners for the button.
                          borderRadius: BorderRadius.circular(10),
                          // Dynamic background color: green if requested, indigo if not.
                          color: _requested 
                              ? AppColors.score5.withValues(alpha: 0.12)
                              : AppColors.indigo.withValues(alpha: 0.12),
                          // Dynamic border color based on the request state.
                          border: Border.all(
                              color: _requested 
                                  ? AppColors.score5.withValues(alpha: 0.20)
                                  : AppColors.indigo.withValues(alpha: 0.20)),
                        ),
                        // Center the text inside the button.
                        child: Center(
                          // Display dynamic text depending on the request state (Requesting..., Callback Requested, or Contact welfare office).
                          child: Text(
                              _requesting ? tr('Requesting...', ref) : _requested ? tr('Callback Requested', ref) : tr('Contact welfare office', ref),
                              // Dynamic text color depending on the request state.
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _requested ? AppColors.score5 : AppColors.indigo)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Add a small 12-pixel gap between the cards.
              const SizedBox(height: 12),
              // 24-hour line card: Another custom RrCard for emergency contact options.
              RrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title text for the 24-hour support line.
                    Text(tr('24-hour support line', ref),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.rrT1)),
                    // Small vertical gap.
                    const SizedBox(height: 4),
                    // Description text explaining the service.
                    Text(tr('Free and confidential — any time, any day.', ref),
                        style: TextStyle(
                            fontSize: 13, color: context.rrT3, height: 1.6)),
                    // Vertical gap before the action buttons.
                    const SizedBox(height: 16),
                    // A Row to place two action buttons side by side horizontally.
                    Row(
                      children: [
                        // Expanded makes the phone call button take up half the available horizontal space.
                        Expanded(
                          // GestureDetector to make the container tappable.
                          child: GestureDetector(
                            // When tapped, use the url_launcher package to open the phone's dialer with a specific number.
                            onTap: () => launchUrl(Uri.parse('tel:08003234444')),
                            // Container to style the phone call button.
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                // Set a greenish background and border.
                                color: AppColors.score5.withValues(alpha: 0.10),
                                border: Border.all(
                                    color:
                                        AppColors.score5.withValues(alpha: 0.20)),
                              ),
                              // Center the text inside the button.
                              child: const Center(
                                child: Text('0800 323 4444',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.score5)),
                              ),
                            ),
                          ),
                        ),
                        // An 8-pixel horizontal gap between the two buttons.
                        const SizedBox(width: 8),
                        // Expanded makes the SMS button take up the remaining half of horizontal space.
                        Expanded(
                          // GestureDetector to make the container tappable.
                          child: GestureDetector(
                            // When tapped, use url_launcher to open the messaging app prefilled with a recipient and a message body.
                            onTap: () => launchUrl(Uri.parse('sms:85258?body=BLUE')),
                            // Container to style the SMS button.
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                // Set a dim sleep (bluish/greyish) background and border.
                                color: AppColors.dimSleep.withValues(alpha: 0.10),
                                border: Border.all(
                                    color: AppColors.dimSleep
                                        .withValues(alpha: 0.20)),
                              ),
                              // Center the text inside the button.
                              child: const Center(
                                child: Text('Text BLUE to 85258',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.dimSleep)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Add a small 12-pixel gap between the 24-hour line card and the about card.
              const SizedBox(height: 12),
              // About card: The final custom RrCard for informational text.
              RrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title text.
                    Text(tr('About this service', ref),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.rrT2)),
                    // Small vertical gap.
                    const SizedBox(height: 8),
                    // Detailed paragraph text explaining data policy.
                    Text(
                        tr('Your check-ins are synchronized with your unit welfare dashboard to monitor overall readiness. Personal data is managed in accordance with policy.', ref),
                        style: TextStyle(
                            fontSize: 13, color: context.rrT3, height: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
