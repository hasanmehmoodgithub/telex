import 'package:flutter/material.dart';

extension MediaQueryValues on BuildContext {
  // Get the screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  // Get the screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  // Get the device pixel ratio
  double get devicePixelRatio => MediaQuery.of(this).devicePixelRatio;

  // Get the orientation (landscape or portrait)
  Orientation get orientation => MediaQuery.of(this).orientation;

  // Check if the device is in portrait mode
  bool get isPortrait => MediaQuery.of(this).orientation == Orientation.portrait;

  // Check if the device is in landscape mode
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;

  // Get the text scaling factor
  double get textScaleFactor => MediaQuery.of(this).textScaleFactor;

  // Get the top padding (useful for notches)
  double get topPadding => MediaQuery.of(this).padding.top;

  // Get the bottom padding (useful for devices with gesture navigation bars)
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
}