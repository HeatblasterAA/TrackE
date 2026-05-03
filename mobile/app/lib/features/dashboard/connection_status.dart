import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/notification_bridge.dart';
import '../../core/services/scan_service.dart';
import '../../core/storage/local_storage.dart';

enum _StatusKind { connectedFresh, connectedStale, neverEnabled, revoked }

class _Status {
  final _StatusKind kind;
  final String message;
  final Color color;
  final IconData icon;
  final String? actionLabel;
  const _Status({
    required this.kind,
    required this.message,
    required this.color,
    required this.icon,
    this.actionLabel,
  });
}

/// Banner shown at the top of the dashboard. States:
///
/// - Green:  listener enabled + a signal arrived in the last 5 days
/// - Amber:  listener enabled but no signals in 5 days
/// - Blue:   listener never enabled (soft nudge for users who skipped onboarding)
/// - Red:    listener was previously enabled, now off (user revoked it)
class ConnectionStatusBanner extends StatefulWidget {
  const ConnectionStatusBanner({super.key});

  @override
  State<ConnectionStatusBanner> createState() => _ConnectionStatusBannerState();
}

class _ConnectionStatusBannerState extends State<ConnectionStatusBanner>
    with WidgetsBindingObserver {
  _Status? _status;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await NotificationBridge.isListenerEnabled();
    final everEnabled = await LocalStorage.wasListenerEverEnabled();
    if (enabled && !everEnabled) {
      await LocalStorage.setListenerEverEnabled();
    }

    final lastMs = ScanService.lastSignalAt;
    final now = DateTime.now().millisecondsSinceEpoch;
    const fiveDaysMs = 5 * 24 * 60 * 60 * 1000;
    final fresh = lastMs != null && (now - lastMs) < fiveDaysMs;

    _Status status;
    if (!enabled && everEnabled) {
      status = const _Status(
        kind: _StatusKind.revoked,
        message: 'Notification access was turned off — re-enable it.',
        color: Color(0xFFD32F2F),
        icon: Icons.error_outline,
        actionLabel: 'Re-enable',
      );
    } else if (!enabled) {
      status = const _Status(
        kind: _StatusKind.neverEnabled,
        message:
            'Turn on notification access to track spending automatically.',
        color: Color(0xFF1565C0),
        icon: Icons.notifications_active_outlined,
        actionLabel: 'Enable',
      );
    } else if (!fresh) {
      status = const _Status(
        kind: _StatusKind.connectedStale,
        message:
            'No transaction alerts seen recently. Check your bank app notification settings.',
        color: Color(0xFFEF6C00),
        icon: Icons.warning_amber_outlined,
      );
    } else {
      final mins = ((now - lastMs) / 60000).round();
      String age;
      if (mins < 60) {
        age = '${mins}m ago';
      } else if (mins < 1440) {
        age = '${(mins / 60).round()}h ago';
      } else {
        age = '${(mins / 1440).round()}d ago';
      }
      status = _Status(
        kind: _StatusKind.connectedFresh,
        message: 'Connected — last transaction $age',
        color: const Color(0xFF2E7D32),
        icon: Icons.check_circle_outline,
      );
    }

    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _onAction() async {
    await NotificationBridge.openListenerSettings();
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    if (s == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.10),
        border: Border.all(color: s.color.withValues(alpha: 0.40)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(s.icon, color: s.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.message,
              style: TextStyle(color: s.color, fontWeight: FontWeight.w600),
            ),
          ),
          if (s.actionLabel != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _onAction,
              style: TextButton.styleFrom(
                foregroundColor: s.color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: Text(s.actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
