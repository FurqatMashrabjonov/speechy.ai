enum TrackTier { quick, full, power }

extension TrackTierX on TrackTier {
  // Coins included with track unlock
  int get coins => switch (this) {
        TrackTier.quick => 15,
        TrackTier.full => 75,
        TrackTier.power => 175,
      };

  // Sessions = coins / 5 (1 session = 5 min = 5 coins)
  int get sessions => coins ~/ 5;

  // Legacy: kept for step-count gating until coin model ships
  int get sessionCount => switch (this) {
        TrackTier.quick => 3,
        TrackTier.full => 15,
        TrackTier.power => 35,
      };

  int get maxAttempts => switch (this) {
        TrackTier.quick => 1,
        TrackTier.full => 2,
        TrackTier.power => 3,
      };

  String get displayName => switch (this) {
        TrackTier.quick => 'Quick Prep',
        TrackTier.full => 'Full Access',
        TrackTier.power => 'Power Pack',
      };

  String get tagline => switch (this) {
        TrackTier.quick => 'Try it out',
        TrackTier.full => 'Complete the track',
        TrackTier.power => 'Best value',
      };

  String get fallbackPrice => switch (this) {
        TrackTier.quick => r'$1.99',
        TrackTier.full => r'$4.99',
        TrackTier.power => r'$7.99',
      };

  // Dual-label: always show coins + sessions together
  String get coinsLabel => '$coins Practice Coins — $sessions sessions';

  bool get isBestValue => this == TrackTier.power;

  String get revenueCatIdentifier => switch (this) {
        TrackTier.quick => 'quick',
        TrackTier.full => 'full',
        TrackTier.power => 'power',
      };

  static TrackTier? fromString(String? value) => switch (value) {
        'quick' => TrackTier.quick,
        'full' => TrackTier.full,
        'power' => TrackTier.power,
        // Legacy identifiers
        'basic' => TrackTier.quick,
        'pro' => TrackTier.full,
        'ultra' => TrackTier.power,
        _ => null,
      };
}
