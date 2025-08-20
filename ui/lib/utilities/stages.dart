import 'dart:math';
import 'package:flutter/painting.dart';

/// Generates a stable, bland color based on the stage name
///
/// The color is deterministic for a given stage name and will always
/// return the same color for the same input
Color randomStageColor(String stage) {
  // Use the string hash as a seed for stability
  final seed = stage.hashCode;

  // Create a seeded random generator
  final random = Random(seed);

  // Generate HSL values for a pleasant, bland color
  // Hue: 0-360 (full color wheel)
  // Saturation: 35-55% (not too vibrant, not too gray)
  // Lightness: 55-75% (medium-light, visible but not too bright)
  final hue = random.nextDouble() * 360;
  final saturation = 0.35 + (random.nextDouble() * 0.2); // 35-55%
  final lightness = 0.55 + (random.nextDouble() * 0.2); // 55-75%

  // Convert HSL to RGB
  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}
