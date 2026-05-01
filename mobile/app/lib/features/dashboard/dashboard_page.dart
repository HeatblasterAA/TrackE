import 'package:app/core/services/sms_bridge.dart';
import 'package:app/features/parser/transaction_parser.dart';
import 'package:app/models/transaction_model.dart';
import 'package:app/repositories/transaction_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/core/services/scan_service.dart';
import 'package:app/repositories/cloud_transaction_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState
    extends State<DashboardPage> {
  final repo = TransactionRepository();

  List<Map<String, dynamic>> txns = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    boot();
  }

  Future<void> boot() async {
  print('boot start');

  setState(() => loading = true);

  if (repo.getAllTyped().isEmpty) {
    print('local empty');

    final cloud =
        await CloudTransactionRepository()
            .fetchAll();

    print('cloud fetched: ${cloud.length}');

    if (cloud.isNotEmpty) {
      await repo.replaceAll(cloud);
      print('local hydrated');
    }
  }

  print('starting sms import');

  await importSms();

  print('sms import done');

  if (!mounted) return;

  setState(() {
    txns = repo.getAllTyped();
    loading = false;
  });

  print('boot done');
}

  Future<void> importSms() async {
  final result =
      await ScanService.scan();

  print('raw sms: ${result.raw}');
  print('parsed: ${result.parsed}');
  print('inserted: ${result.inserted}');
}

  double get total =>
      txns.fold(
        0,
        (sum, e) =>
            sum + (e['amount'] as num).toDouble(),
      );

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> clear() async {
    await repo.clear();

    setState(() {
      txns = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackE'),
        actions: [
          IconButton(
            onPressed: boot,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: clear,
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : txns.isEmpty
          ? const Center(
              child:
                  Text('No transactions'),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.all(16),
                  padding:
                      const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'Total Spend',
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style:
                            const TextStyle(
                              fontSize: 30,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: txns.length,
                    itemBuilder: (_, i) {
                      final t = txns[i];

                      final date = DateFormat(
                        'dd MMM yyyy',
                      ).format(
                        DateTime.fromMillisecondsSinceEpoch(
                          t['timestamp'],
                        ),
                      );

                      return Card(
                        margin:
                            const EdgeInsets.symmetric(
                              horizontal:
                                  16,
                              vertical: 6,
                            ),
                        child: ListTile(
                          title: Text(
                            '₹${t['amount']}',
                            style:
                                const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                t['displayName'],
                              ),
                              Text(
                                '${t['mode']} • ${t['bank']} • $date',
                                style:
                                    const TextStyle(
                                      color:
                                          Colors
                                              .grey,
                                      fontSize:
                                          12,
                                    ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            t['category'],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}