import '../../models/transaction_model.dart';
import '../../core/utils/hash_util.dart';

class TransactionParser {
  static TransactionModel? parse(
    Map<String, dynamic> sms,
  ) {
    final sender =
        (sms['sender'] ?? '').toString().toUpperCase();

    final body =
        (sms['body'] ?? '').toString();

    final lower = body.toLowerCase();

    if (!_isValidDebit(lower)) return null;

    final amount = _extractAmount(body);
    if (amount == null) return null;

    final payee = _extractPayee(body);
    final provider = _extractProvider(body);

    final displayName =
        _extractDisplayName(body, payee, provider);

    final bank = _extractBank(sender);
    final mode = _extractMode(lower);
    final category = _categorize(displayName);
    final id = HashUtil.smsHash(sms);

    return TransactionModel(
      id: id,
      amount: amount,
      type: 'debit',
      mode: mode,
      displayName: displayName,
      payeeName: payee,
      provider: provider,
      bank: bank,
      category: category,
      timestamp: sms['timestamp'] ?? 0,
    );
  }

  static bool _isValidDebit(String text) {
    final positive = [
      'debit of',
      ' dr.',
      ' debited',
      ' spent',
      ' paid',
      ' purchase',
      ' used for',
      ' used at',
      ' debit of',
    ];

    final negative = [
      'otp',
      'credited with',
      'a/c credited',
      'login',
      'failed login',
      'verification code',
      'sign-in',
      'eligible',
      'apply now',
      'loan',
      'will be debited',
      'on approval',
    ];

    if (negative.any(text.contains)) return false;

    return positive.any(text.contains);
  }

  static double? _extractAmount(String text) {
    final regex = RegExp(
      r'(rs\.?|inr|sar)\s*([\d,]+(\.\d+)?)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);
    if (match == null) return null;

    final raw =
        match.group(2)!.replaceAll(',', '');

    return double.tryParse(raw);
  }

  static String _extractPayee(String text) {
    final upiRegex = RegExp(
      r'([a-zA-Z0-9._\-]+)@([a-zA-Z0-9._\-]+)',
      caseSensitive: false,
    );

    final match = upiRegex.firstMatch(text);

    if (match != null) {
      return match.group(1) ?? '';
    }

    return '';
  }

  static String _extractProvider(String text) {
    final providerRegex = RegExp(
      r'@([a-zA-Z0-9._\-]+)',
      caseSensitive: false,
    );

    final match = providerRegex.firstMatch(text);

    if (match != null) {
      return (match.group(1) ?? '')
          .replaceAll(
            RegExp(r'[^a-zA-Z0-9]'),
            '',
          )
          .toLowerCase();
    }

    return '';
  }

  static String _extractDisplayName(
    String body,
    String payee,
    String provider,
  ) {
    if (payee.isNotEmpty) {
      return _formatName(payee);
    }

    final cardRegex = RegExp(
      r'at\s+([A-Za-z0-9 &._\-]+?)(?:\.| for |$)',
      caseSensitive: false,
    );

    final cardMatch = cardRegex.firstMatch(body);

    if (cardMatch != null) {
      return _formatName(
        cardMatch.group(1) ?? '',
      );
    }

    if (provider.isNotEmpty) {
      return _formatName(provider);
    }

    return 'Unknown';
  }

  static String _extractBank(String sender) {
    if (sender.contains('BOB')) return 'BOB';
    if (sender.contains('HDFC')) return 'HDFC';
    if (sender.contains('SBI')) return 'SBI';
    if (sender.contains('ICICI')) return 'ICICI';
    if (sender.contains('AXIS')) return 'AXIS';
    if (sender.contains('ALRAJHI')) return 'ALRAJHI';
    if (sender.contains('SNB')) return 'SNB';

    return 'Unknown';
  }

  static String _extractMode(String text) {
    if (text.contains('@')) return 'UPI';
    if (text.contains('card')) return 'CARD';

    return 'BANK';
  }

  static String _formatName(String raw) {
    if (raw.isEmpty) return 'Unknown';

    return raw
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .trim()
        .toUpperCase();
  }

  static String _categorize(String name) {
    final n = name.toUpperCase();

    if (n.contains('PAYTM')) return 'Bills';
    if (n.contains('JIO')) return 'Recharge';
    if (n.contains('SWIGGY') ||
        n.contains('ZOMATO') ||
        n.contains('DOMINOS') ||
        n.contains('STARBUCKS')) {
      return 'Food';
    }

    return 'Other';
  }
}