import '../../shared/constants/merchant_categories.dart';

/// Result of merchant canonicalization.
class CanonicalMerchant {
  /// Cleaned, canonical name (e.g. "ALBAIK"). Empty if nothing usable.
  final String name;

  /// 0.0–1.0. 1.0 = exact alias hit, 0.7 = fuzzy hit against known
  /// merchant, 0.4 = only generic cleanup.
  final double confidence;

  const CanonicalMerchant({required this.name, required this.confidence});

  static const empty = CanonicalMerchant(name: '', confidence: 0.0);
}

/// Layer 2 of the parser pipeline. Takes the raw "display name" the
/// regex layer pulled out of the message and normalizes it so the
/// category lookup and user-rule memory have a stable key to work with.
class MerchantCanonicalizer {
  static final RegExp _digits = RegExp(r'\d+');
  static final RegExp _nonAlphaNum = RegExp(r'[^A-Za-z\s]');
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Common city/area suffixes that show up in card-swipe merchant
  /// strings (e.g. "ALBAIK DAMMAM", "DOMINOS BANGALORE").
  static const Set<String> _cityNoise = {
    'DAMMAM', 'RIYADH', 'JEDDAH', 'KHOBAR', 'MAKKAH', 'MEDINA',
    'BANGALORE', 'BENGALURU', 'MUMBAI', 'DELHI', 'NCR', 'CHENNAI',
    'HYDERABAD', 'PUNE', 'KOLKATA', 'NOIDA', 'GURGAON', 'GURUGRAM',
    'INDIA', 'IN', 'KSA', 'SA', 'UAE', 'DUBAI', 'ABU', 'DHABI',
    'BRANCH', 'STORE', 'OUTLET', 'MALL',
  };

  /// Hand-curated alias map. Cheap, high-precision, and easy to grow.
  /// Keys MUST be already-uppercase + collapsed-whitespace.
  static const Map<String, String> _aliases = {
    'AL BAIK': 'ALBAIK',
    'ALBK': 'ALBAIK',
    'ALBK FOOD': 'ALBAIK',
    'AMZN': 'AMAZON',
    'AMAZON SELLER SERVICES': 'AMAZON',
    'AMAZON IN': 'AMAZON',
    'FLIPKART INTERNET': 'FLIPKART',
    'SWIGGY INSTAMART': 'INSTAMART',
    'ZOMATO ONLINE': 'ZOMATO',
    'UBER INDIA': 'UBER',
    'UBER BV': 'UBER',
    'OLA CABS': 'OLA',
    'BUNDL TECHNOLOGIES': 'SWIGGY',
    'SPOTIFY INDIA': 'SPOTIFY',
    'NETFLIX COM': 'NETFLIX',
    'GOOGLE PLAY': 'GOOGLE PLAY',
    'STARBUCKS COFFEE': 'STARBUCKS',
    '7 ELEVEN': '7ELEVEN',
    'SEVEN ELEVEN': '7ELEVEN',
    'JIO MOBILITY': 'JIO',
    'PAYTM JIO': 'JIO',
    'CARREFOUR HYPER': 'CARREFOUR',
    'PANDA RETAIL': 'PANDA',
  };

  /// Set of "known" canonical merchants used as fuzzy-match targets.
  /// We seed it from the category dictionary so anything we already
  /// classify is automatically a fuzzy candidate.
  static final List<String> _knownMerchants = () {
    final out = <String>{...merchantCategories.keys, ..._aliases.values};
    return out.toList();
  }();

  static CanonicalMerchant canonicalize(String raw) {
    if (raw.trim().isEmpty) return CanonicalMerchant.empty;

    final cleaned = _basicClean(raw);
    if (cleaned.isEmpty) return CanonicalMerchant.empty;

    if (_aliases.containsKey(cleaned)) {
      return CanonicalMerchant(name: _aliases[cleaned]!, confidence: 1.0);
    }

    if (merchantCategories.containsKey(cleaned)) {
      return CanonicalMerchant(name: cleaned, confidence: 1.0);
    }

    final tokens = cleaned.split(' ');
    for (final t in tokens) {
      if (t.length < 3) continue;
      if (_aliases.containsKey(t)) {
        return CanonicalMerchant(name: _aliases[t]!, confidence: 0.85);
      }
      if (merchantCategories.containsKey(t)) {
        return CanonicalMerchant(name: t, confidence: 0.85);
      }
    }

    final fuzzy = _bestFuzzyMatch(cleaned);
    if (fuzzy != null) {
      return CanonicalMerchant(name: fuzzy, confidence: 0.7);
    }

    return CanonicalMerchant(name: cleaned, confidence: 0.4);
  }

  static String _basicClean(String raw) {
    var out = raw.toUpperCase();
    out = out.replaceAll(_digits, ' ');
    out = out.replaceAll(_nonAlphaNum, ' ');
    out = out.replaceAll(_whitespace, ' ').trim();

    if (out.isEmpty) return '';

    final parts = out.split(' ').where((t) {
      if (t.isEmpty) return false;
      if (_cityNoise.contains(t)) return false;
      return true;
    }).toList();

    return parts.join(' ').trim();
  }

  static String? _bestFuzzyMatch(String cleaned) {
    String? best;
    int bestDistance = 1 << 30;
    for (final candidate in _knownMerchants) {
      if ((candidate.length - cleaned.length).abs() > 3) continue;
      final d = _levenshtein(cleaned, candidate);
      final maxLen = cleaned.length > candidate.length
          ? cleaned.length
          : candidate.length;
      if (maxLen == 0) continue;
      final ratio = d / maxLen;
      if (ratio <= 0.25 && d < bestDistance) {
        best = candidate;
        bestDistance = d;
      }
    }
    return best;
  }

  /// Iterative Levenshtein. Capped at MAX = 4 to keep cost trivial.
  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final m = a.length;
    final n = b.length;
    var prev = List<int>.generate(n + 1, (i) => i);
    var curr = List<int>.filled(n + 1, 0);

    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[n];
  }
}
