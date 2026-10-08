// We import the standard Material design library from Flutter.
// This library provides us with fundamental UI building blocks, including 'TextStyle', 'Color', and 'FontWeight' classes used below.
import 'package:flutter/material.dart';

// We import the 'google_fonts' package.
// This external package allows us to easily use hundreds of free, open-source fonts from Google Fonts directly in our Flutter app without having to download font files manually.
import 'package:google_fonts/google_fonts.dart';

// ── Outfit text style helpers ──────────────────────────────────────────────
// This is a comment section header just to organize our code visually.

// Here we provide an example of how a developer might use the function below:
// Usage: AppText.outfit(size: 14, weight: FontWeight.w500, color: ctx.rrT2)

// We define an 'abstract final class' named 'AppText'.
// 'abstract' means we cannot create an instance (object) of this class using 'AppText()'.
// 'final' means no other class can inherit from (extend) this class.
// Essentially, this class acts as a pure utility container—just a namespace to group related text style functions together.
abstract final class AppText {

  // This is a 'static' method, meaning it belongs to the class itself, not to an instance.
  // This allows us to call it directly like 'AppText.outfit(...)'.
  // It returns a 'TextStyle' object which we can apply to Text widgets.
  static TextStyle outfit({
    // We require the developer to provide a 'size' for the font, using the 'required' keyword.
    // It's a 'double', meaning it can be a decimal number.
    required double size,
    
    // We allow an optional 'weight' (how bold the text is), defaulting it to 'FontWeight.w400' (normal text weight).
    FontWeight weight = FontWeight.w400,
    
    // We allow an optional 'color'. The '?' means it is nullable (it can be null).
    // If not provided, it will fall back to whatever default text color the app uses.
    Color? color,
    
    // We allow an optional 'height'. This controls line-spacing or line-height.
    double? height,
    
    // We allow an optional 'letterSpacing', which controls the horizontal space between individual letters.
    double? letterSpacing,
    
  // The '=>' arrow syntax is a shorthand in Dart for a function that returns exactly one expression.
  }) =>
      // We are calling the 'outfit' method from the 'GoogleFonts' class.
      // This retrieves the 'Outfit' font family.
      GoogleFonts.outfit(
        // We pass the size provided by our helper to GoogleFonts.
        fontSize: size,
        
        // We pass the weight provided by our helper to GoogleFonts.
        fontWeight: weight,
        
        // We pass the color provided by our helper to GoogleFonts.
        color: color,
        
        // We pass the line height to GoogleFonts.
        height: height,
        
        // We pass the letter spacing to GoogleFonts.
        letterSpacing: letterSpacing,
      );

  // ── Commonly used composites ─────────────────────────────────────────────
  // These are pre-configured text styles. Instead of passing 'size' and 'weight' every time, 
  // we can just call these quick functions for consistent design across our app.

  // The 'label' style is meant for very small, bold text, typically used for small tags or badges.
  // It takes a 'Color' as an argument and returns our 'outfit' text style configured precisely for labels.
  static TextStyle label(Color color) =>
      // Calls our helper method above with predefined values: size 10, semi-bold weight (w600), and a slight letter spacing.
      outfit(size: 10, weight: FontWeight.w600, color: color, letterSpacing: 0.10);

  // The 'caption' style is used for secondary, smaller informational text (like image captions or timestamps).
  static TextStyle caption(Color color) =>
      // Uses a small font size of 11, with normal (default w400) weight.
      outfit(size: 11, color: color);

  // The 'body' style is used for standard, regular-sized paragraphs or general readable text.
  static TextStyle body(Color color) =>
      // Uses a standard reading size of 14, normal weight.
      outfit(size: 14, color: color);

  // The 'bodyMed' (Body Medium) style is similar to 'body', but slightly bolder for emphasis.
  static TextStyle bodyMed(Color color) =>
      // Uses size 14, but bumps the font weight to 'w500' (Medium weight).
      outfit(size: 14, weight: FontWeight.w500, color: color);

  // The 'title' style is larger and bolder, usually used for section headers or app bar titles.
  static TextStyle title(Color color) =>
      // Uses size 20, and semi-bold weight (w600) to make it stand out.
      outfit(size: 20, weight: FontWeight.w600, color: color);

  // The 'display' style is for very large headers, such as the main heading on a splash screen or hero section.
  static TextStyle display(Color color) =>
      // Uses a large size 27, semi-bold weight (w600), and sets a custom line height of 1.25 to make multi-line display text look nicely spaced.
      outfit(size: 27, weight: FontWeight.w600, color: color, height: 1.25);

  // The 'mono' style stands for "Monospace", where every character takes up the exact same width.
  // This is typically used for code snippets, numbers, or a technical look.
  // Instead of using 'outfit', this function specifies a different font.
  static TextStyle mono({
    // It accepts an optional 'size' parameter defaulting to 30.
    double size = 30, 
    // It also accepts an optional nullable 'color'.
    Color? color
  }) =>
      // Here, we call 'jetBrainsMono' from the GoogleFonts package instead of 'outfit'.
      // JetBrains Mono is a popular, highly readable font often used for writing code.
      GoogleFonts.jetBrainsMono(
        // Pass the provided size (or default 30).
        fontSize: size,
        
        // Pass a normal weight (w400).
        fontWeight: FontWeight.w400,
        
        // Pass the provided color.
        color: color,
        
        // Adds slightly more space between letters for readability.
        letterSpacing: 0.22,
      );
}
