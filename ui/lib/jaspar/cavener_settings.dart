// cavener_settings.dart
//
// Bundles the threshold/toggle values that used to be separate
// `double _t1`, `bool _icEnabled`... fields on the screen's State class.
// Grouping related values into one small immutable class -- instead of
// passing them around individually -- is a pattern worth knowing well;
// it's the same idea as a "config object" in JS/Python.
//
// `copyWith` is the standard Dart way to "change" an immutable object:
// you don't mutate it, you build a new one that's mostly a copy of the
// old one with a couple of fields swapped out.

class CavenerSettings {
  const CavenerSettings({
    this.t1 = 0.5,
    this.t2 = 0.75,
    this.trim = false,
    this.icEnabled = false,
    this.icThreshold = 0.5,
  });

  final double t1;
  final double t2;
  final bool trim;
  final bool icEnabled;
  final double icThreshold;

  CavenerSettings copyWith({
    double? t1,
    double? t2,
    bool? trim,
    bool? icEnabled,
    double? icThreshold,
  }) {
    return CavenerSettings(
      t1: t1 ?? this.t1,
      t2: t2 ?? this.t2,
      trim: trim ?? this.trim,
      icEnabled: icEnabled ?? this.icEnabled,
      icThreshold: icThreshold ?? this.icThreshold,
    );
  }
}
