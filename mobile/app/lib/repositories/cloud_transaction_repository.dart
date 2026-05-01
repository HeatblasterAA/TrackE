import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class CloudTransactionRepository {
  final _db = FirebaseFirestore.instance;

  String? get _uid =>
      FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>
  get _collection {
    final uid = _uid;

    if (uid == null) {
      throw Exception('Not logged in');
    }

    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions');
  }

  Future<void> upsert(
    TransactionModel txn,
  ) async {
    await _collection.doc(txn.id).set(
          txn.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> upsertMany(
    List<TransactionModel> txns,
  ) async {
    if (txns.isEmpty) return;

    final batch = _db.batch();

    for (final txn in txns) {
      final ref =
          _collection.doc(txn.id);

      batch.set(
        ref,
        txn.toMap(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>>
  fetchAll() async {
    final snap =
        await _collection.orderBy(
          'timestamp',
          descending: true,
        ).get();

    return snap.docs
        .map((e) => e.data())
        .toList();
  }
}