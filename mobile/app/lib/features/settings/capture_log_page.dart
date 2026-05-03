import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/scan_service.dart';
import '../../core/storage/raw_signal_log.dart';

/// Debug screen showing the most recent raw notification signals captured
/// by the listener and what the parser did with each. Reachable via a
/// hidden 7-tap on the dashboard title.
///
/// Drastically speeds up bank-compatibility tuning: when something doesn't
/// show up in the dashboard, you can immediately tell whether it's a
/// capture failure (signal absent) or a parse failure (signal present,
/// outcome `rejected`).
class CaptureLogPage extends StatefulWidget {
  const CaptureLogPage({super.key});

  @override
  State<CaptureLogPage> createState() => _CaptureLogPageState();
}

class _CaptureLogPageState extends State<CaptureLogPage> {
  List<Map<String, dynamic>> _entries = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() => _entries = RawSignalLog.recent(limit: 20));
  }

  Future<void> _reprocess() async {
    setState(() => _busy = true);
    final result = await ScanService.reprocess();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reprocessed ${result.raw} signals — ${result.parsed} parsed, '
          '${result.inserted} new',
        ),
      ),
    );
    _refresh();
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear capture log?'),
        content: const Text(
            'This deletes the local copy of recently captured notifications. '
            'Stored transactions are not affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await RawSignalLog.clear();
    _refresh();
  }

  Color _outcomeColor(String outcome) {
    switch (outcome) {
      case 'ok':
        return Colors.green;
      case 'review':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture log'),
        actions: [
          IconButton(
            tooltip: 'Reprocess',
            icon: const Icon(Icons.replay),
            onPressed: _busy ? null : _reprocess,
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline),
            onPressed: _busy ? null : _clear,
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('No signals captured yet',
                          style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = _entries[i];
                    final ts = (e['timestamp'] as num?)?.toInt() ?? 0;
                    final body = (e['body'] ?? '').toString();
                    final shortBody =
                        body.length > 120 ? '${body.substring(0, 120)}…' : body;
                    final outcome = (e['parseOutcome'] ?? 'pending').toString();
                    final matchedBy = (e['matchedBy'] ?? '').toString();
                    return Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e['sender']?.toString() ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _outcomeColor(outcome)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(outcome,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: _outcomeColor(outcome),
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(shortBody,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('dd MMM • hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(ts))}  •  $matchedBy',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
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
