class TransactionModel {
  final double amount;
  final String type;
  final String mode;
  final String id;

  final String displayName;
  final String payeeName;
  final String provider;

  final String bank;
  final String category;

  final int timestamp;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.mode,
    required this.displayName,
    required this.payeeName,
    required this.provider,
    required this.bank,
    required this.category,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'mode': mode,
      'displayName': displayName,
      'payeeName': payeeName,
      'provider': provider,
      'bank': bank,
      'category': category,
      'timestamp': timestamp,
    };
  }
}