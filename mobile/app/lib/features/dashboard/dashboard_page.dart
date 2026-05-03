import 'package:app/repositories/transaction_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/scan_service.dart';
import '../../core/storage/local_storage.dart';
import '../../repositories/cloud_transaction_repository.dart';
import '../insights/insights_page.dart';
import '../settings/capture_log_page.dart';
import '../transactions/manual_add_page.dart';
import '../transactions/review_queue_page.dart';
import 'connection_status.dart';

enum FilterRange { today, week, month, custom, all }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final repo = TransactionRepository();
  String selectedCategory = 'All';

  List<Map<String, dynamic>> txns = [];
  bool loading = true;
  FilterRange selectedRange = FilterRange.month;
  DateTimeRange? customRange;

  int _titleTapCount = 0;
  DateTime? _firstTapAt;

  @override
  void initState() {
    super.initState();
    boot();
  }

  Future<void> boot() async {
    setState(() => loading = true);
    final data = repo.getAllTyped();
    if (!mounted) return;
    setState(() {
      txns = data;
      loading = false;
    });
  }

  List<Map<String, dynamic>> get filteredTxns {
    final now = DateTime.now();
    return txns.where((t) {
      final d = DateTime.fromMillisecondsSinceEpoch(t['timestamp']);
      bool dateMatch;
      switch (selectedRange) {
        case FilterRange.today:
          dateMatch =
              d.year == now.year && d.month == now.month && d.day == now.day;
          break;
        case FilterRange.week:
          dateMatch = now.difference(d).inDays <= 7;
          break;
        case FilterRange.month:
          dateMatch = d.year == now.year && d.month == now.month;
          break;
        case FilterRange.custom:
          if (customRange == null) {
            dateMatch = true;
          } else {
            final start = DateTime(customRange!.start.year,
                customRange!.start.month, customRange!.start.day);
            final end = DateTime(customRange!.end.year, customRange!.end.month,
                customRange!.end.day, 23, 59, 59);
            dateMatch = !d.isBefore(start) && !d.isAfter(end);
          }
          break;
        case FilterRange.all:
          dateMatch = true;
          break;
      }
      if (!dateMatch) return false;
      if (selectedCategory == 'All') return true;
      return t['category'] == selectedCategory;
    }).toList();
  }

  String formatMoney(double amount, String currency) {
    if (currency == 'INR') {
      return NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 2,
      ).format(amount);
    }
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '﷼',
      decimalDigits: 2,
    ).format(amount);
  }

  double get todaySpend {
    final now = DateTime.now();
    return filteredTxns
        .where((t) {
          final d = DateTime.fromMillisecondsSinceEpoch(t['timestamp']);
          return d.year == now.year &&
              d.month == now.month &&
              d.day == now.day;
        })
        .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  }

  String get topCategory {
    final counts = <String, double>{};
    for (final t in filteredTxns) {
      final cat = t['category'] ?? 'Other';
      counts[cat] = (counts[cat] ?? 0) + (t['amount'] as num).toDouble();
    }
    if (counts.isEmpty) return 'None';
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      if (entry.key != 'Other') return entry.key;
    }
    return sorted.first.key;
  }

  List<String> get categories {
    final set = <String>{'All'};
    for (final t in txns) {
      set.add((t['category'] ?? 'Other').toString());
    }
    final list = set.toList();
    list.remove('All');
    list.sort();
    return ['All', ...list];
  }

  String emoji(String category) {
    switch (category) {
      case 'Food':
        return '🍔';
      case 'Shopping':
        return '🛍';
      case 'Travel':
        return '🚕';
      case 'Fuel':
        return '⛽';
      case 'Recharge':
        return '📱';
      case 'Bills':
        return '💡';
      case 'Health':
        return '🏥';
      case 'Entertainment':
        return '🎬';
      case 'Education':
        return '📚';
      case 'Grocery':
        return '🛒';
      case 'Transfer':
        return '💸';
      default:
        return '📦';
    }
  }

  Widget categoryChip(String category) {
    final selected = selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${emoji(category)} $category',
          style: TextStyle(color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _chip(String label, FilterRange range) {
    final selected = selectedRange == range;
    return GestureDetector(
      onTap: () async {
        if (range == FilterRange.custom) {
          await pickCustomRange();
          return;
        }
        setState(() => selectedRange = range);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(color: selected ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child:
                Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void showTxnDetail(Map<String, dynamic> t) {
    final date = DateFormat('dd MMM yyyy • hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(t['timestamp']));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatMoney((t['amount'] as num).toDouble(), t['currency']),
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Text(t['displayName'],
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              detailRow('Category', t['category']),
              detailRow('Mode', t['mode']),
              detailRow('Bank', t['bank']),
              detailRow(
                'Provider',
                t['provider'].toString().isEmpty ? '-' : t['provider'],
              ),
              detailRow('Date', date),
              if (t['confidence'] != null)
                detailRow(
                  'Confidence',
                  '${((t['confidence'] as num).toDouble() * 100).round()}%',
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: customRange,
    );
    if (picked == null) return;
    setState(() {
      customRange = picked;
      selectedRange = FilterRange.custom;
    });
  }

  String get selectedLabel {
    switch (selectedRange) {
      case FilterRange.today:
        return 'Today';
      case FilterRange.week:
        return 'This week';
      case FilterRange.month:
        return 'This month';
      case FilterRange.all:
        return 'All time';
      case FilterRange.custom:
        return customRange == null
            ? 'Custom'
            : '${DateFormat('dd MMM').format(customRange!.start)} → ${DateFormat('dd MMM').format(customRange!.end)}';
    }
  }

  bool get hasActiveFilters {
    return selectedRange != FilterRange.month ||
        selectedCategory != 'All' ||
        customRange != null;
  }

  void resetFilters() {
    setState(() {
      selectedRange = FilterRange.month;
      selectedCategory = 'All';
      customRange = null;
    });
  }

  String get primaryCurrency {
    for (final t in filteredTxns) {
      final c = t['currency'];
      if (c != null) return c;
    }
    return 'INR';
  }

  double get selectedSpend {
    return filteredTxns.fold(
      0.0,
      (sum, t) => sum + (t['amount'] as num).toDouble(),
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> clear() async {
    await repo.clear();
    await CloudTransactionRepository().clearAll();
    await LocalStorage.clearScanState();
    if (!mounted) return;
    setState(() => txns = []);
  }

  void _onTitleTap() {
    final now = DateTime.now();
    if (_firstTapAt == null ||
        now.difference(_firstTapAt!) > const Duration(seconds: 3)) {
      _firstTapAt = now;
      _titleTapCount = 1;
      return;
    }
    _titleTapCount++;
    if (_titleTapCount >= 7) {
      _titleTapCount = 0;
      _firstTapAt = null;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CaptureLogPage()),
      );
    }
  }

  Future<void> _openManualAdd() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ManualAddPage()),
    );
    if (added == true) await boot();
  }

  Future<void> _openReviewQueue() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReviewQueuePage()),
    );
    await boot();
  }

  @override
  Widget build(BuildContext context) {
    final reviewCount = repo.needsReviewCount();

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTitleTap,
          child: const Text('TrackE'),
        ),
        actions: [
          if (reviewCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: TextButton.icon(
                onPressed: _openReviewQueue,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amber.shade100,
                  foregroundColor: Colors.brown.shade800,
                ),
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text('Review ($reviewCount)'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InsightsPage(txns: filteredTxns),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              setState(() => loading = true);
              await ScanService.scan();
              await boot();
            },
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Rebuild history?'),
                  content: const Text(
                      'This clears stored transactions and reprocesses captured signals.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Rebuild'),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;
              setState(() => loading = true);
              await clear();
              await ScanService.scan();
              await boot();
            },
          ),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openManualAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const ConnectionStatusBanner(),
                if (filteredTxns.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long,
                                size: 56, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No transactions yet',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hasActiveFilters
                                  ? 'Try changing filters'
                                  : 'Transactions will appear here as your bank notifications arrive.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey.shade600),
                            ),
                            if (hasActiveFilters) ...[
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: resetFilters,
                                child: const Text('Reset filters'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _chip('Today', FilterRange.today),
                        const SizedBox(width: 8),
                        _chip('Week', FilterRange.week),
                        const SizedBox(width: 8),
                        _chip('Month', FilterRange.month),
                        const SizedBox(width: 8),
                        _chip('Custom', FilterRange.custom),
                        const SizedBox(width: 8),
                        _chip('All', FilterRange.all),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => categoryChip(categories[i]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatMoney(selectedSpend, primaryCurrency),
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(selectedLabel),
                        const SizedBox(height: 18),
                        Text(
                            'Today: ${formatMoney(todaySpend, primaryCurrency)}'),
                        const SizedBox(height: 6),
                        Text('Top: ${emoji(topCategory)} $topCategory'),
                        const SizedBox(height: 6),
                        Text('${filteredTxns.length} transactions'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredTxns.length,
                      itemBuilder: (_, i) {
                        final t = filteredTxns[i];
                        final date = DateFormat('dd MMM yyyy').format(
                          DateTime.fromMillisecondsSinceEpoch(
                              t['timestamp']),
                        );
                        final review = (t['needsReview'] as bool?) ?? false;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: ListTile(
                            onTap: () => showTxnDetail(t),
                            title: Text(
                              formatMoney(
                                (t['amount'] as num).toDouble(),
                                t['currency'],
                              ),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(t['displayName']),
                                Text(
                                  '${t['mode']} • ${t['bank']} • $date',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    t['category'],
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (review) ...[
                                  const SizedBox(height: 4),
                                  const Icon(Icons.flag_outlined,
                                      size: 14, color: Colors.orange),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
