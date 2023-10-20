import 'package:flutter/material.dart';

/// Visual representation of an individual stage
class StageAndColor {
  /// The name of the stage
  final String stage;

  /// The color of the stage
  final Color color;

  /// The stroke width of the stage
  final int stroke;

  /// Whether the stage is checked by default
  final bool isCheckedByDefault;

  StageAndColor(this.stage, this.color, {this.stroke = 4, this.isCheckedByDefault = true});
}
