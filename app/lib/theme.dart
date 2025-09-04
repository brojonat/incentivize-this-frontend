import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Light Theme
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.transparent, // Example: Make AppBar transparent
    foregroundColor: Colors.black, // Example: Set text/icon color
  ),
  cardTheme: CardThemeData(
    elevation: 0, // Example: Flat cards
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade300, width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  textSelectionTheme: _platformAwareTextSelectionTheme(Brightness.light),
);

// Dark Theme
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade800, width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  textSelectionTheme: _platformAwareTextSelectionTheme(Brightness.dark),
);

TextSelectionThemeData _platformAwareTextSelectionTheme(Brightness brightness) {
  // Check if the platform is Apple-like (iOS, macOS, or a browser on an Apple device)
  final isApplePlatform = defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  final Color primaryColor =
      brightness == Brightness.light ? Colors.blue : Colors.lightBlue.shade300;

  if (isApplePlatform) {
    // For Apple platforms, use a very subtle, almost transparent selection color
    // to hide the Material shadow and let the native iOS handles dominate.
    return TextSelectionThemeData(
      cursorColor: primaryColor,
      selectionColor: primaryColor.withOpacity(0.1),
      selectionHandleColor: primaryColor,
    );
  } else {
    // For other platforms (Android, Web on non-Apple, etc.), use the standard Material style.
    return TextSelectionThemeData(
      cursorColor: primaryColor,
      selectionColor: primaryColor.withOpacity(0.4),
      selectionHandleColor: primaryColor,
    );
  }
}
