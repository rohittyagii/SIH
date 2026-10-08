// We import the main Flutter material design library, which gives us access to UI widgets like Container, Row, Column, etc.
import 'package:flutter/material.dart';

// We import the flutter_riverpod library. Riverpod is a state management tool that helps us manage the app's state easily.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// We import our custom colors defined in the theme folder to keep our app's styling consistent.
import '../theme/colors.dart';

// We import our custom icon widgets so we can use specifically designed icons in our navigation bar.
import '../widgets/icon_widgets.dart';

// We import translations which allows us to translate text into different languages.
import '../data/translations.dart';

// We import the app's state providers. Providers act as global variables that can be accessed and updated from anywhere in the app.
import '../providers/app_state.dart';

// We import a custom button widget called BouncyButton that gives a bouncing animation when tapped.
import '../widgets/bouncy_button.dart';

// ── Tab definition ─────────────────────────────────────────────────────────

// We define an 'enum' (enumeration) called AppTab. 
// Enums are a way to group related, named constants. Here it represents the 4 different tabs in our app.
// By using an enum, we prevent typos and ensure we only use these specific tab names.
enum AppTab { home, trend, support, settings }

// ── BottomNav ───────────────────────────────────────────────────────────────

// We define our BottomNav widget as a ConsumerWidget. 
// ConsumerWidget comes from Riverpod and allows this widget to "listen" to state changes (providers).
class BottomNav extends ConsumerWidget {
  // The constructor initializes our widget. 
  // We use 'super.key' to pass the key to the parent widget.
  // 'required this.active' means we must pass the currently active tab when creating this widget.
  // 'required this.onTab' is a function that will be called when a tab is selected.
  const BottomNav({super.key, required this.active, required this.onTab});
  
  // This variable holds the currently active tab (e.g., AppTab.home).
  final AppTab active;
  
  // This is a callback function that takes an AppTab as an argument. 
  // We call this function when the user taps on a tab to tell the parent widget to switch tabs.
  final ValueChanged<AppTab> onTab;

  // We define a static constant list called '_tabs' (the underscore makes it private to this file).
  // It contains tuples (records in Dart) with the tab enum, the label text, and the icon to use.
  // We use 'IconHome.new' which refers to the constructor of the IconHome widget.
  static const _tabs = [
    (tab: AppTab.home,     label: 'Home',     icon: IconHome.new),
    (tab: AppTab.trend,    label: 'Trend',    icon: IconTrend.new),
    (tab: AppTab.support,  label: 'Support',  icon: IconMessageCircle.new),
    (tab: AppTab.settings, label: 'Settings', icon: IconSliders.new),
  ];

  // The build method is called every time the widget needs to be drawn on the screen.
  // Because this is a ConsumerWidget, it also gives us a 'WidgetRef' (ref) which we use to read providers.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We check if the app is currently in dark mode by asking the device's theme.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // We get the background color from our context using an extension property (like rrBgd).
    // Use the deepest background color so it stands out against the lighter cards
    final bgColor = context.rrBgd; 

    // We calculate the padding at the bottom of the screen.
    // Some phones have a notch or a home indicator at the bottom (safe area).
    // If the safe area padding is greater than 0, we subtract 12 to bring the nav bar slightly lower,
    // otherwise we just use a default padding of 16.0 pixels.
    final bottomPadding = MediaQuery.of(context).padding.bottom > 0
        ? MediaQuery.of(context).padding.bottom - 12 // Drop it lower than safe area
        : 16.0;

    // We return a Padding widget to create space around our navigation bar.
    return Padding(
      // We apply padding to the left, right, and bottom.
      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomPadding),
      
      // Inside the Padding, we have a Container which will act as the physical bar itself.
      child: Container(
          // Set a fixed height of 64 pixels for the bottom navigation bar.
          height: 64,
          
          // We use BoxDecoration to style the container (colors, rounded corners, borders, shadows).
          decoration: BoxDecoration(
            // Apply the background color we determined earlier.
            color: bgColor,
            
            // Make the corners fully rounded (circular) with a radius of 32.
            borderRadius: BorderRadius.circular(32),
            
            // Add a border around the container.
            border: Border.all(
              // If it's dark mode, we use a specific divider color (rrDv), else it's transparent (invisible).
              color: isDark ? context.rrDv : Colors.transparent,
              // The border will be 1 pixel thick.
              width: 1,
            ),
            
            // Add a list of shadows behind the container to make it look elevated.
            boxShadow: [
              BoxShadow(
                // The shadow is black with 25% opacity (alpha: 0.25).
                color: Colors.black.withValues(alpha: 0.25),
                // The blur radius is 24, making the shadow soft and spread out.
                blurRadius: 24,
                // The shadow is offset by 8 pixels directly downwards (x: 0, y: 8).
                offset: const Offset(0, 8),
              )
            ],
          ),
          
          // LayoutBuilder gives us information about the size (constraints) available for the widget.
          child: LayoutBuilder(
            builder: (context, constraints) {
              
              // This is a helper function that handles drag interactions across the navigation bar.
              // It takes the horizontal 'x' position of the user's finger.
              void handleDrag(double x) {
                // Get the total width available for the navigation bar.
                final width = constraints.maxWidth;
                
                // Divide the total width into 5 equal segments (4 tabs + 1 center button).
                final segment = width / 5;
                
                // Calculate which index (0 to 4) the user's finger is currently over.
                // We divide x by the segment width, round down using floor(), and keep it between 0 and 4 using clamp().
                final index = (x / segment).floor().clamp(0, 4);
                
                // If the finger is over the first segment, trigger the home tab callback.
                if (index == 0) onTab(AppTab.home);
                // If the finger is over the second segment, trigger the trend tab callback.
                if (index == 1) onTab(AppTab.trend);
                // index 2 is the check-in button, skip triggering during drag
                // If the finger is over the fourth segment, trigger the support tab callback.
                if (index == 3) onTab(AppTab.support);
                // If the finger is over the fifth segment, trigger the settings tab callback.
                if (index == 4) onTab(AppTab.settings);
              }

              // GestureDetector lets us listen to touch events like taps, drags, and pans.
              return GestureDetector(
                // When the user starts pressing down, call handleDrag with the horizontal position.
                onPanDown: (d) => handleDrag(d.localPosition.dx),
                // As the user drags their finger across the bar, call handleDrag to update the active tab.
                onPanUpdate: (d) => handleDrag(d.localPosition.dx),
                // Make sure the entire area of the container is touchable, not just the children.
                behavior: HitTestBehavior.opaque,
                
                // A Row widget arranges its children horizontally.
                child: Row(
                  // Space the children evenly across the entire width of the Row.
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Build the first tab (Home) using the _buildTab method.
                    _buildTab(context, ref, _tabs[0]),
                    // Build the second tab (Trend).
                    _buildTab(context, ref, _tabs[1]),
                    // Build the prominent Check-in button in the center.
                    _buildCheckinButton(context, ref),
                    // Build the third tab (Support).
                    _buildTab(context, ref, _tabs[2]),
                    // Build the fourth tab (Settings).
                    _buildTab(context, ref, _tabs[3]),
                  ],
                ),
              );
            },
          ),
        ),
    );
  }

  // This method builds the big "+" button in the center of the navigation bar.
  Widget _buildCheckinButton(BuildContext context, WidgetRef ref) {
    // We wrap it in a BouncyButton to give it a nice pop animation when tapped.
    return BouncyButton(
      // The onTap function defines what happens when the button is pressed.
      onTap: () {
        // We read a provider called 'todayDoneProvider' to check if the user has already checked in today.
        final todayDone = ref.read(todayDoneProvider);
        
        // If they have already done it today...
        if (todayDone) {
          // ...we update the 'submittedProvider' to true (maybe showing a success screen).
          ref.read(submittedProvider.notifier).state = true;
        } else {
          // If they haven't checked in yet, we reset their scores to empty.
          ref.read(scoresProvider.notifier).state = emptyScores();
          // We clear any existing note.
          ref.read(noteProvider.notifier).state = '';
          // We set 'inCheckinProvider' to true, which likely opens the check-in screen.
          ref.read(inCheckinProvider.notifier).state = true;
        }
      },
      
      // The visual part of the button is a Container.
      child: Container(
        // Set fixed width and height of 48 pixels to make it a perfect square.
        width: 48,
        height: 48,
        
        // We style the container to make it a circle with a color and a shadow.
        decoration: BoxDecoration(
          // Use our app's primary indigo color.
          color: AppColors.indigo,
          // Change the shape of the container to a circle.
          shape: BoxShape.circle,
          
          // Add a shadow to make the button look like it's floating.
          boxShadow: [
            BoxShadow(
              // The shadow color is indigo with 40% opacity.
              color: AppColors.indigo.withValues(alpha: 0.4),
              // Blur radius of 12 makes it a soft shadow.
              blurRadius: 12,
              // Move the shadow 4 pixels down.
              offset: const Offset(0, 4),
            )
          ],
        ),
        
        // Inside the circular container, we center an icon.
        child: const Center(
          // The icon is a simple plus ('+') symbol, colored white, with a size of 28 pixels.
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // This method builds the individual tab icons and text (Home, Trend, etc.).
  // 't' is the dynamic record (tuple) that holds the tab's enum, label, and icon function.
  Widget _buildTab(BuildContext context, WidgetRef ref, dynamic t) {
    // We check if this specific tab is the currently active one.
    final isActive = active == t.tab;
    
    // If it's active, we use the indigo color, otherwise we use a muted text color from the context (rrT6).
    final color = isActive ? AppColors.indigo : context.rrT6;
    
    // We use a GestureDetector so the user can tap on the tab to switch to it.
    return GestureDetector(
      // When tapped, call the onTab callback with the enum of this tab.
      onTap: () => onTab(t.tab),
      // Make the entire box area tapable.
      behavior: HitTestBehavior.opaque,
      
      // Use a SizedBox with a fixed width of 56 to make sure every tab takes up the same amount of space.
      child: SizedBox(
        width: 56, // Fixed width for consistent spacing
        
        // Use a Column to stack the icon on top of the text label.
        child: Column(
          // Center the contents of the column vertically.
          mainAxisAlignment: MainAxisAlignment.center,
          // Shrink the column's height to tightly fit its children.
          mainAxisSize: MainAxisSize.min,
          children: [
            
            // AnimatedContainer automatically animates any changes to its properties (like scale or position).
            AnimatedContainer(
              // The animation will take 350 milliseconds to complete.
              duration: const Duration(milliseconds: 350),
              // Use an easeOutBack curve which creates a 'bouncy' spring effect when stopping.
              curve: Curves.easeOutBack, // Smoother, fluid bounce
              
              // Transform applies visual changes like moving or scaling the widget.
              transform: Matrix4.identity()
                // If the tab is active, move it up by 4 pixels (-4.0 on Y axis), otherwise don't move it.
                ..translateByDouble(0.0, isActive ? -4.0 : 0.0, 0.0, 1.0) // Move up slightly
                // If the tab is active, scale it up by 1.35x (make it 35% larger), otherwise keep its normal size.
                ..scaleByDouble(isActive ? 1.35 : 1.0, isActive ? 1.35 : 1.0, isActive ? 1.35 : 1.0, 1.0), // Large scale
              
              // Apply the transformations from the center of the widget.
              transformAlignment: Alignment.center,
              
              // The child is the icon widget itself, created by calling the icon function stored in 't'.
              child: t.icon(size: 24.0, color: color),
            ),
            
            // Add a small 4-pixel vertical space between the icon and the text.
            const SizedBox(height: 4),
            
            // AnimatedOpacity automatically fades the text in or out when the opacity changes.
            AnimatedOpacity(
              // The fade animation takes 200 milliseconds.
              duration: const Duration(milliseconds: 200),
              // If active, the text is fully opaque (1.0). If inactive, it's faded to 40% opacity (0.4).
              opacity: isActive ? 1.0 : 0.4,
              
              // AnimatedDefaultTextStyle smoothly transitions the text style (like font size or color).
              child: AnimatedDefaultTextStyle(
                // The text style animation takes 300 milliseconds.
                duration: const Duration(milliseconds: 300),
                // Use a smooth easeOut curve for the text style change.
                curve: Curves.easeOut,
                
                // Define the style for the text based on whether it is active or not.
                style: TextStyle(
                  // The font size increases to 11 if active, otherwise it stays at 9.
                  fontSize: isActive ? 11 : 9, 
                  // Make the text bold (w700) if active, otherwise medium (w500).
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, 
                  // Use the calculated color (indigo if active, muted if not).
                  color: color,
                  // Use a custom font family called 'Outfit'.
                  fontFamily: 'Outfit',
                ),
                
                // The actual text widget.
                // We use 'tr()' which translates the label text based on the user's language using Riverpod (ref).
                child: Text(tr(t.label, ref), maxLines: 1, overflow: TextOverflow.visible),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
