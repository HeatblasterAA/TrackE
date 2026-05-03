import '../../core/ingestion/raw_txn_signal.dart';
import '../../models/transaction_model.dart';
import '../../shared/constants/merchant_categories.dart';
import 'confidence_engine.dart';
import 'merchant_canonicalizer.dart';
import 'user_rule_memory.dart';

/// Five-layer deterministic parser:
///   1. Template match           — regex for amount, currency, debit/credit
///   2. Merchant canonicalizer   — alias + fuzzy → canonical name
///   3. Category lookup          — static dictionary
///   4. User rule memory         — user corrections override the dictionary
///   5. Confidence engine        — combine scores, set needsReview
class TransactionParser {
  /// New entry point. The whole app calls this.
  static TransactionModel? parseSignal(RawTxnSignal signal) {
    final combinedText = '${signal.title} ${signal.body}'.trim();
    if (combinedText.isEmpty) return null;

    // -------- Layer 1: template match --------
    final templateScore = _templateScore(combinedText.toLowerCase());
    if (templateScore == 0.0) return null;

    final amount = _extractAmountAndCurrency(combinedText);
    if (amount == null) return null;

    // -------- Layer 2: merchant canonicalization --------
    final rawDisplay = _extractDisplayCandidate(signal.body, signal.title);
    final canonical = MerchantCanonicalizer.canonicalize(rawDisplay);

    final displayName =
        canonical.name.isNotEmpty ? _titleCase(canonical.name) : 'Bank Debit';

    // -------- Layer 3 + 4: category (user rule wins) --------
    final userRule = UserRuleMemory.lookup(canonical.name);
    String category;
    double categoryScore;
    if (userRule != null) {
      category = userRule;
      categoryScore = 1.0;
    } else {
      final dictHit = _categorize(canonical.name);
      category = dictHit;
      categoryScore =
          (dictHit == 'Other' || dictHit == 'Transfer') ? 0.3 : 0.8;
    }

    // -------- Layer 5: confidence --------
    final confidence = ConfidenceEngine.combine(
      templateScore: templateScore,
      merchantScore: canonical.confidence,
      categoryScore: categoryScore,
    );
    final needsReview = ConfidenceEngine.needsReview(confidence);

    final mode = _extractMode(combinedText.toLowerCase());
    final bank = _extractBank(signal.sender);
    final payee = _extractPayee(signal.body);
    final provider = _extractProvider(signal.body);

    return TransactionModel(
      id: signal.id,
      amount: amount.amount,
      currency: amount.currency,
      type: 'debit',
      mode: mode,
      displayName: displayName,
      payeeName: payee,
      provider: provider,
      bank: bank,
      category: category,
      timestamp: signal.timestamp,
      confidence: confidence,
      needsReview: needsReview,
    );
  }

  /// Backwards-compatible entry point used by [parser_test.dart]. Wraps
  /// the legacy SMS map shape into a [RawTxnSignal] and dispatches.
  static TransactionModel? parse(Map<String, dynamic> sms) {
    final signal = RawTxnSignal(
      source: 'notification',
      sender: (sms['sender'] ?? '').toString(),
      title: (sms['title'] ?? '').toString(),
      body: (sms['body'] ?? '').toString(),
      timestamp: (sms['timestamp'] as num?)?.toInt() ?? 0,
      matchedBy: (sms['matchedBy'] ?? 'allowlist').toString(),
    );
    return parseSignal(signal);
  }

  // ---------------------------------------------------------------------
  // Layer 1 helpers
  // ---------------------------------------------------------------------

  static double _templateScore(String lower) {
    const negative = [
      'otp',
      'credited with',
      'a/c credited',
      'login',
      'failed login',
      'verification code',
      'sign-in',
      'eligible',
      'apply now',
      'will be debited',
      'on approval',
      'do not share',
    ];
    for (final n in negative) {
      if (lower.contains(n)) return 0.0;
    }

    const strong = [
      'debit of',
      ' debited',
      ' spent',
      ' paid',
      ' purchase',
      ' used for',
      ' used at',
      ' withdrawn',
      'card used',
      ' charged',
    ];
    for (final s in strong) {
      if (lower.contains(s)) return 1.0;
    }

    const weak = [' dr.', ' txn ', ' upi ', ' atm ', ' pos '];
    for (final w in weak) {
      if (lower.contains(w)) return 0.6;
    }
    return 0.0;
  }

  static ({double amount, String currency})? _extractAmountAndCurrency(
      String text) {
    final regex = RegExp(
      r'(rs\.?|inr|sar|aed|usd|eur|gbp|₹|﷼|\$)\s*([\d,]+(\.\d+)?)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match == null) return null;
    final token = (match.group(1) ?? '').toLowerCase();
    final raw = match.group(2)!.replaceAll(',', '');
    final amount = double.tryParse(raw);
    if (amount == null) return null;
    final currency = _currencyFromToken(token);
    return (amount: amount, currency: currency);
  }

  static String _currencyFromToken(String t) {
    if (t.contains('sar') || t.contains('﷼')) return 'SAR';
    if (t.contains('aed')) return 'AED';
    if (t.contains('usd') || t.contains(r'$')) return 'USD';
    if (t.contains('eur')) return 'EUR';
    if (t.contains('gbp')) return 'GBP';
    return 'INR';
  }

  // ---------------------------------------------------------------------
  // Layer 2 helpers (raw display candidate, before canonicalization)
  // ---------------------------------------------------------------------

  static String _extractDisplayCandidate(String body, String title) {
    final upi = RegExp(r'([a-zA-Z0-9._\-]+)@([a-zA-Z0-9._\-]+)',
            caseSensitive: false)
        .firstMatch(body);
    if (upi != null) return upi.group(1) ?? '';

    final at = RegExp(r'\b(?:at|to)\s+([A-Za-z0-9 &._\-]+?)(?:\.| for | on |$)',
            caseSensitive: false)
        .firstMatch(body);
    if (at != null) return at.group(1)?.trim() ?? '';

    final info = RegExp(r'Info[:\s]([A-Za-z0-9*._\-]+)', caseSensitive: false)
        .firstMatch(body);
    if (info != null) return info.group(1) ?? '';

    final lowerBody = body.toLowerCase();
    if (lowerBody.contains('atm')) return 'ATM Withdrawal';
    if (lowerBody.contains('transfer')) return 'Bank Transfer';

    if (title.trim().isNotEmpty && title.length < 40) return title.trim();
    return '';
  }

  static String _extractPayee(String text) {
    final upi = RegExp(r'([a-zA-Z0-9._\-]+)@([a-zA-Z0-9._\-]+)',
            caseSensitive: false)
        .firstMatch(text);
    return upi?.group(1) ?? '';
  }

  static String _extractProvider(String text) {
    final m = RegExp(r'@([a-zA-Z0-9._\-]+)', caseSensitive: false)
        .firstMatch(text);
    if (m == null) return '';
    return (m.group(1) ?? '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
  }

  static String _extractBank(String sender) {
    final s = sender.toUpperCase();
    if (s.contains('HDFC')) return 'HDFC';
    if (s.contains('ICICI')) return 'ICICI';
    if (s.contains('SBI')) return 'SBI';
    if (s.contains('AXIS')) return 'AXIS';
    if (s.contains('KOTAK')) return 'KOTAK';
    if (s.contains('BOB')) return 'BOB';
    if (s.contains('PHONEPE') || s.contains('phonepe')) return 'PhonePe';
    if (s.contains('PAYTM') || s.contains('paytm')) return 'Paytm';
    if (s.contains('GPAY') || s.contains('paisa.user')) return 'GPay';
    if (s.contains('ALRAJHI') || s.contains('ARB')) return 'Al Rajhi';
    if (s.contains('SNB') || s.contains('alahli')) return 'SNB';
    if (s.contains('RIYAD')) return 'Riyad';
    return 'Unknown';
  }

  static String _extractMode(String lower) {
    if (lower.contains('@') || lower.contains('upi')) return 'UPI';
    if (lower.contains('card')) return 'CARD';
    if (lower.contains('atm')) return 'ATM';
    return 'BANK';
  }

  // ---------------------------------------------------------------------
  // Layer 3 helper
  // ---------------------------------------------------------------------

  static String _categorize(String canonical) {
    if (canonical.isEmpty) return 'Other';
    final upper = canonical.toUpperCase();
    final direct = merchantCategories[upper];
    if (direct != null) return direct;
    for (final entry in merchantCategories.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    return 'Transfer';
  }

  static String _titleCase(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .split(' ')
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
