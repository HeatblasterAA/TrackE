import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../ingestion/raw_txn_signal.dart';

/// Encrypted, **local-only** log of recently captured raw notification
/// signals. NEVER uploaded to Firestore.
///
/// Used for:
///   - reprocessing existing signals after a parser upgrade,
///   - the capture-log debug screen,
///   - feeding the review-queue with original context.
///
/// Retention: at most [_maxEntries] entries OR entries younger than
/// [_maxAge], whichever is smaller. Pruned on every append.
class RawSignalLog {
  RawSignalLog._();

  static const String _boxName = 'raw_signals_box';
  static const String _keyAlias = 'raw_signals_aes_key_v1';
  static const int _maxEntries = 200;
  static const Duration _maxAge = Duration(days: 7);

  static const _secure = FlutterSecureStorage();

  static Box<Map>? _box;

  /// Must be called once during app boot, after Hive.initFlutter.
  static Future<void> init() async {
    final cipher = HiveAesCipher(await _loadOrCreateKey());
    _box = await Hive.openBox<Map>(_boxName, encryptionCipher: cipher);
    await _prune();
  }

  static Box<Map> get _b {
    final b = _box;
    if (b == null) {
      throw StateError(
          'RawSignalLog not initialized — call RawSignalLog.init() first');
    }
    return b;
  }

  /// Append a signal. Records the same id the parser will use, so callers
  /// can later [markOutcome] without juggling separate ids.
  static Future<void> append(
    RawTxnSignal signal, {
    String parseOutcome = 'pending',
    String? parsedTxnId,
  }) async {
    final entry = <String, dynamic>{
      'id': signal.id,
      'sender': signal.sender,
      'title': signal.title,
      'body': signal.body,
      'timestamp': signal.timestamp,
      'matchedBy': signal.matchedBy,
      'source': signal.source,
      'parseOutcome': parseOutcome,
      'parsedTxnId': parsedTxnId,
      'capturedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await _b.put(signal.id, entry);
    await _prune();
  }

  /// Update the parse outcome for a previously-appended signal.
  ///
  /// `outcome` is one of: `ok`, `rejected`, `review`.
  static Future<void> markOutcome(
    String signalId,
    String outcome, [
    String? parsedTxnId,
  ]) async {
    final existing = _b.get(signalId);
    if (existing == null) return;
    final updated = Map<String, dynamic>.from(existing);
    updated['parseOutcome'] = outcome;
    if (parsedTxnId != null) updated['parsedTxnId'] = parsedTxnId;
    await _b.put(signalId, updated);
  }

  /// Most-recent-first list of entries, capped to [limit].
  static List<Map<String, dynamic>> recent({int limit = 20}) {
    final entries = _b.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) =>
          (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    return entries.take(limit).toList();
  }

  /// All entries, used by reprocess. Returns [RawTxnSignal]s ordered
  /// oldest-first so reprocessing happens in arrival order.
  static List<RawTxnSignal> all() {
    final entries = _b.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) =>
          (a['timestamp'] as int).compareTo(b['timestamp'] as int));
    return entries.map(RawTxnSignal.fromMap).toList();
  }

  static Future<void> clear() => _b.clear();

  static int get count => _box?.length ?? 0;

  static Future<void> _prune() async {
    final cutoff = DateTime.now().subtract(_maxAge).millisecondsSinceEpoch;

    final toDeleteByAge = <dynamic>[];
    for (final key in _b.keys) {
      final entry = _b.get(key);
      if (entry == null) continue;
      final ts = (entry['timestamp'] as num?)?.toInt() ?? 0;
      if (ts < cutoff) toDeleteByAge.add(key);
    }
    if (toDeleteByAge.isNotEmpty) await _b.deleteAll(toDeleteByAge);

    if (_b.length <= _maxEntries) return;
    final entries = _b.toMap().entries.toList()
      ..sort((a, b) {
        final at = (a.value['timestamp'] as num?)?.toInt() ?? 0;
        final bt = (b.value['timestamp'] as num?)?.toInt() ?? 0;
        return at.compareTo(bt);
      });
    final excess = _b.length - _maxEntries;
    final keysToDrop = entries.take(excess).map((e) => e.key).toList();
    await _b.deleteAll(keysToDrop);
  }

  static Future<List<int>> _loadOrCreateKey() async {
    final existing = await _secure.read(key: _keyAlias);
    if (existing != null && existing.isNotEmpty) {
      try {
        return base64Decode(existing);
      } catch (_) {
        // fall through to regen
      }
    }
    final rng = Random.secure();
    final key = List<int>.generate(32, (_) => rng.nextInt(256));
    await _secure.write(key: _keyAlias, value: base64Encode(key));
    return key;
  }
}
