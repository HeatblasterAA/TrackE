import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Canonical input shape consumed by the parser.
///
/// Every ingestion source (notification listener, manual entry,
/// future companion APK, future CSV import) MUST normalize into this.
/// The parser only ever sees [RawTxnSignal] — never raw notifications,
/// SMS, etc.
class RawTxnSignal {
  /// Where the signal came from. One of: `notification`, `manual`.
  final String source;

  /// Identifier for the upstream sender (Android package name for
  /// notifications, `manual` for manual entries).
  final String sender;

  final String title;
  final String body;

  /// Epoch milliseconds.
  final int timestamp;

  /// How the listener decided to forward this signal:
  /// `allowlist`, `heuristic`, or `manual`.
  final String matchedBy;

  RawTxnSignal({
    required this.source,
    required this.sender,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.matchedBy,
  });

  /// Stable id derived from sender + body + timestamp. Used as the
  /// dedup key in the raw signal log AND fed into [TransactionModel.id].
  String get id {
    final raw = '$sender|$body|$timestamp';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  factory RawTxnSignal.fromMap(Map<dynamic, dynamic> map) {
    return RawTxnSignal(
      source: (map['source'] ?? 'notification').toString(),
      sender: (map['sender'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      timestamp: (map['timestamp'] is int)
          ? map['timestamp'] as int
          : int.tryParse(map['timestamp']?.toString() ?? '') ?? 0,
      matchedBy: (map['matchedBy'] ?? 'allowlist').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'source': source,
        'sender': sender,
        'title': title,
        'body': body,
        'timestamp': timestamp,
        'matchedBy': matchedBy,
      };

  /// Convenience for parsers that historically used the SMS shape
  /// (`sender + body + timestamp`).
  Map<String, dynamic> toLegacySmsMap() => {
        'sender': sender,
        'body': '$title $body'.trim(),
        'timestamp': timestamp,
      };
}
