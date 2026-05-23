enum TrackTier { basic, pro, ultra }

extension TrackTierX on TrackTier {
  int get sessionCount => switch (this) {
        TrackTier.basic => 8,
        TrackTier.pro => 12,
        TrackTier.ultra => 15,
      };

  int get maxAttempts => switch (this) {
        TrackTier.basic => 1,
        TrackTier.pro => 2,
        TrackTier.ultra => 3,
      };

  String get displayName => switch (this) {
        TrackTier.basic => 'Basic',
        TrackTier.pro => 'Pro',
        TrackTier.ultra => 'Ultra',
      };

  String get fallbackPrice => switch (this) {
        TrackTier.basic => r'$2.99',
        TrackTier.pro => r'$4.99',
        TrackTier.ultra => r'$7.99',
      };

  String get revenueCatIdentifier => switch (this) {
        TrackTier.basic => 'basic',
        TrackTier.pro => 'pro',
        TrackTier.ultra => 'ultra',
      };

  static TrackTier? fromString(String? value) => switch (value) {
        'basic' => TrackTier.basic,
        'pro' => TrackTier.pro,
        'ultra' => TrackTier.ultra,
        _ => null,
      };
}
