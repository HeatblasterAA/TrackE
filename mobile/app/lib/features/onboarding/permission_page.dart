import 'package:flutter/material.dart';

import '../../core/services/notification_bridge.dart';
import '../../core/storage/local_storage.dart';
import '../dashboard/dashboard_page.dart';

/// Soft-gated notification access prompt.
///
/// Either "Enable now" or "Skip for now" finishes onboarding. We never
/// hard-block the dashboard on listener access — the dashboard
/// connection-status banner handles the nudge if the user skipped.
class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage>
    with WidgetsBindingObserver {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed) return;
    if (!_opening) return;
    _opening = false;
    final ok = await NotificationBridge.isListenerEnabled();
    if (ok) await _finish();
  }

  Future<void> _enable() async {
    _opening = true;
    await NotificationBridge.openListenerSettings();
  }

  Future<void> _skip() async => _finish();

  Future<void> _finish() async {
    await LocalStorage.setOnboardingComplete();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Track spending automatically',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Allow notification access so TrackE can read transaction notifications from your bank and payment apps. Other notifications are ignored.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You can change this anytime from system settings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _enable,
                child: const Text('Enable now'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _skip,
                child: const Text('Skip for now'),
              ),
              const SizedBox(height: 16),
              Text(
                'You can also add transactions manually.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
