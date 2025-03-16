import 'package:flutter/material.dart';

/// App-wide text styles for consistent typography
class AppTextStyles {
  // Headline styles
  static const TextStyle headline1 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.15,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.15,
  );

  // Title styles
  static const TextStyle title = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  // Subtitle styles
  static const TextStyle subtitle1 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  // Body text styles
  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
  );

  // Caption and button styles
  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
  );

  // Overline style for small headers
  static const TextStyle overline = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.normal,
    letterSpacing: 1.5,
  );
}
