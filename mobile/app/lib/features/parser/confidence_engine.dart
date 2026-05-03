/// Layer 5: turn per-layer scores into a single confidence value and a
/// `needsReview` boolean.
///
/// We weight the three components so that the merchant signal dominates
/// (a wrong merchant is what makes a row look "off" to the user), but a
/// user-rule hit on the category bumps confidence regardless.
class ConfidenceEngine {
  static const double reviewThreshold = 0.6;

  /// All inputs are 0.0 – 1.0.
  ///
  /// - `templateScore`: how cleanly the regex layer matched the
  ///   debit/credit + amount pattern.
  /// - `merchantScore`: from [MerchantCanonicalizer.canonicalize]
  ///   (1.0 alias / 0.85 token / 0.7 fuzzy / 0.4 fallback).
  /// - `categoryScore`: 1.0 if the user rule memory hit, 0.8 if the
  ///   static dictionary hit, 0.3 otherwise (we still classified it
  ///   as "Transfer" or "Other").
  static double combine({
    required double templateScore,
    required double merchantScore,
    required double categoryScore,
  }) {
    final raw = (templateScore * 0.30) +
        (merchantScore * 0.45) +
        (categoryScore * 0.25);
    return raw.clamp(0.0, 1.0);
  }

  static bool needsReview(double confidence) => confidence < reviewThreshold;
}
