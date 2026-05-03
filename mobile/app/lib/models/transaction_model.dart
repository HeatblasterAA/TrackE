class TransactionModel {
  final String id;

  final double amount;
  final String currency;

  final String type;
  final String mode;

  final String displayName;
  final String payeeName;
  final String provider;

  final String bank;
  final String category;

  final int timestamp;

  /// 0.0 – 1.0. Output of [ConfidenceEngine.combine].
  final double confidence;

  /// True when [confidence] is below the review threshold. Surfaced in
  /// the dashboard "Review (N)" pill so the user can correct merchant
  /// or category — corrections feed back into [UserRuleMemory].
  final bool needsReview;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.mode,
    required this.displayName,
    required this.payeeName,
    required this.provider,
    required this.bank,
    required this.category,
    required this.timestamp,
    this.confidence = 1.0,
    this.needsReview = false,
  });

  TransactionModel copyWith({
    String? category,
    String? displayName,
    double? confidence,
    bool? needsReview,
  }) {
    return TransactionModel(
      id: id,
      amount: amount,
      currency: currency,
      type: type,
      mode: mode,
      displayName: displayName ?? this.displayName,
      payeeName: payeeName,
      provider: provider,
      bank: bank,
      category: category ?? this.category,
      timestamp: timestamp,
      confidence: confidence ?? this.confidence,
      needsReview: needsReview ?? this.needsReview,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'type': type,
      'mode': mode,
      'displayName': displayName,
      'payeeName': payeeName,
      'provider': provider,
      'bank': bank,
      'category': category,
      'timestamp': timestamp,
      'confidence': confidence,
      'needsReview': needsReview,
    };
  }

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map) {
    return TransactionModel(
      id: (map['id'] ?? '').toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: (map['currency'] ?? 'INR').toString(),
      type: (map['type'] ?? 'debit').toString(),
      mode: (map['mode'] ?? 'BANK').toString(),
      displayName: (map['displayName'] ?? 'Bank Debit').toString(),
      payeeName: (map['payeeName'] ?? '').toString(),
      provider: (map['provider'] ?? '').toString(),
      bank: (map['bank'] ?? 'Unknown').toString(),
      category: (map['category'] ?? 'Other').toString(),
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      needsReview: (map['needsReview'] as bool?) ?? false,
    );
  }
}
