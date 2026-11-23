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
