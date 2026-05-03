import 'package:hive_flutter/hive_flutter.dart';

/// Layer 4: persistent, user-specific overrides for merchant→category.
///
/// When the user corrects a transaction in the review queue (or in the
/// detail sheet), we write the canonical merchant name → category mapping
/// here. The lookup is checked BEFORE the static [merchantCategories]
/// dictionary so user edits always win.
class UserRuleMemory {
  UserRuleMemory._();

  static const String _boxName = 'user_merchant_rules';

  static Box<String>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<String>(_boxName);
  }

  static Box<String> get _b {
    final b = _box;
    if (b == null) {
      throw StateError(
          'UserRuleMemory not initialized — call UserRuleMemory.init() first');
    }
    return b;
  }

  /// Returns the user-defined category for this canonical merchant,
  /// or `null` if there isn't one.
  static String? lookup(String canonicalMerchant) {
    if (canonicalMerchant.isEmpty) return null;
    return _b.get(canonicalMerchant.toUpperCase());
  }

  /// Persist a user correction.
  static Future<void> remember(
    String canonicalMerchant,
    String category,
  ) async {
    if (canonicalMerchant.isEmpty) return;
    await _b.put(canonicalMerchant.toUpperCase(), category);
  }

  /// Forget a single rule.
  static Future<void> forget(String canonicalMerchant) async {
    if (canonicalMerchant.isEmpty) return;
    await _b.delete(canonicalMerchant.toUpperCase());
  }

  static Map<String, String> all() {
    return Map<String, String>.from(_b.toMap().map(
          (k, v) => MapEntry(k.toString(), v),
        ));
  }

  static int get count => _box?.length ?? 0;

  static Future<void> clear() => _b.clear();
}
