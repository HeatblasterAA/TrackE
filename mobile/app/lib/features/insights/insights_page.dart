import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InsightsPage extends StatelessWidget {
  final List<Map<String, dynamic>> txns;

  const InsightsPage({
    super.key,
    required this.txns,
  });

  String formatMoney(
    double amount,
    String currency,
  ) {
    if (currency == 'SAR') {
      return NumberFormat.currency(
        locale: 'en_US',
        symbol: '﷼',
        decimalDigits: 2,
      ).format(amount);
    }

    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
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

  @override
  Widget build(BuildContext context) {
    final total = txns.fold<double>(
      0,
      (sum, t) =>
          sum +
          (t['amount'] as num)
              .toDouble(),
    );

    final avg =
        txns.isEmpty
            ? 0
            : total / txns.length;

    final currency =
        txns.isEmpty
            ? 'INR'
            : (txns.first['currency'] ??
                'INR');

    final categoryTotals =
        <String, double>{};

    for (final t in txns) {
      final cat =
          t['category'] ?? 'Other';

      categoryTotals[cat] =
          (categoryTotals[cat] ?? 0) +
          (t['amount'] as num)
              .toDouble();
    }

    final topCategories =
        categoryTotals.entries.toList()
          ..sort(
            (a, b) => b.value.compareTo(
              a.value,
            ),
          );

    final biggest =
        txns.isEmpty
            ? null
            : (txns.toList()
              ..sort(
                (a, b) =>
                    (b['amount'] as num)
                        .compareTo(
                          a['amount']
                              as num,
                        ),
              )).first;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Insights',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          Text(
            formatMoney(
              total,
              currency,
            ),
            style:
                const TextStyle(
                  fontSize: 32,
                  fontWeight:
                      FontWeight.bold,
                ),
          ),

          const SizedBox(height: 6),

          Text(
            '${txns.length} transactions',
            style: TextStyle(
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          ...topCategories
              .take(5)
              .map(
                (e) => Padding(
                  padding:
                      const EdgeInsets.only(
                        bottom: 12,
                      ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${emoji(e.key)} ${e.key}',
                        ),
                      ),
                      Text(
                        formatMoney(
                          e.value,
                          currency,
                        ),
                        style:
                            const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

          const SizedBox(height: 28),

          if (biggest != null) ...[
            const Text(
              'Biggest Spend',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              '${formatMoney((biggest['amount'] as num).toDouble(), currency)} • ${biggest['displayName']}',
            ),

            const SizedBox(height: 28),
          ],

          const Text(
            'Average Spend',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${formatMoney(avg.toDouble(), currency)} / txn',
          ),
        ],
      ),
    );
  }
}