enum TrackTier { full }

extension TrackTierX on TrackTier {
  /// Paid users get 3 attempts per step (1 normal + 2 retries).
  /// Free users get 1 attempt on step 0 only — enforced in UsageService.
  int get maxAttempts => 3;

  String get displayName => 'Full Access';

  String get tagline => 'All 15 steps · 3 tries each';

  String get fallbackPrice => r'$6.99';

  String get revenueCatIdentifier => 'full';

  static TrackTier? fromString(String? value) => switch (value) {
        'full' => TrackTier.full,
        // Legacy identifiers — all map to full now
        'quick' => TrackTier.full,
        'power' => TrackTier.full,
        'basic' => TrackTier.full,
        'pro' => TrackTier.full,
        'ultra' => TrackTier.full,
        _ => null,
      };
}
