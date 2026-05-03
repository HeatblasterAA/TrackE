import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/parser/user_rule_memory.dart';
import '../../models/transaction_model.dart';
import '../../repositories/cloud_transaction_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../../shared/constants/merchant_categories.dart';

/// Lists transactions where `needsReview == true` and lets the user
/// confirm or correct merchant + category. Corrections write into
/// [UserRuleMemory] so the same merchant is auto-categorized next time.
class ReviewQueuePage extends StatefulWidget {
  const ReviewQueuePage({super.key});

  @override
  State<ReviewQueuePage> createState() => _ReviewQueuePageState();
}

class _ReviewQueuePageState extends State<ReviewQueuePage> {
  final _repo = TransactionRepository();
  final _cloud = CloudTransactionRepository();

  List<TransactionModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _items = _repo.getNeedsReview());
  }

  List<String> get _categories {
    final set = <String>{...merchantCategories.values, 'Transfer', 'Other'};
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _confirm(TransactionModel t) async {
    final updated = t.copyWith(needsReview: false, confidence: 1.0);
    await _repo.upsert(updated);
    try {
      await _cloud.upsert(updated);
    } catch (_) {}
    await UserRuleMemory.remember(t.displayName.toUpperCase(), t.category);
    _load();
  }

  Future<void> _edit(TransactionModel t) async {
    final result = await showModalBottomSheet<_EditResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditSheet(
        initialMerchant: t.displayName,
        initialCategory: t.category,
        categories: _categories,
      ),
    );
    if (result == null) return;

    final newMerchant = result.merchant.trim().isEmpty
        ? t.displayName
        : result.merchant.trim();
    final newCategory = result.category;
    final updated = t.copyWith(
      displayName: newMerchant,
      category: newCategory,
      needsReview: false,
      confidence: 1.0,
    );
    await _repo.upsert(updated);
    try {
      await _cloud.upsert(updated);
    } catch (_) {}
    await UserRuleMemory.remember(newMerchant.toUpperCase(), newCategory);
    _load();
  }

  String _formatMoney(double a, String currency) {
    final symbol = switch (currency) {
      'INR' => '₹',
      'SAR' => '﷼',
      'AED' => 'د.إ',
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      _ => '',
    };
    return NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: 2,
      locale: 'en_US',
    ).format(a);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review queue')),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.done_all,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Nothing to review',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = _items[i];
                final date = DateFormat('dd MMM • hh:mm a').format(
                  DateTime.fromMillisecondsSinceEpoch(t.timestamp),
                );
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatMoney(t.amount, t.currency),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'conf ${(t.confidence * 100).round()}%',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(t.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${t.category} • ${t.bank} • $date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            )),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _edit(t),
                                child: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _confirm(t),
                                child: const Text('Looks right'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _EditResult {
  final String merchant;
  final String category;
  _EditResult(this.merchant, this.category);
}

class _EditSheet extends StatefulWidget {
  final String initialMerchant;
  final String initialCategory;
  final List<String> categories;
  const _EditSheet({
    required this.initialMerchant,
    required this.initialCategory,
    required this.categories,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _merchant =
      TextEditingController(text: widget.initialMerchant);
  late String _category = widget.initialCategory;

  @override
  void dispose() {
    _merchant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Correct this transaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _merchant,
            decoration: const InputDecoration(
              labelText: 'Merchant',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: widget.categories.contains(_category)
                ? _category
                : widget.categories.first,
            items: widget.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) =>
                setState(() => _category = v ?? widget.categories.first),
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This rule applies to future "${_merchant.text.trim()}" transactions too.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              _EditResult(_merchant.text, _category),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
