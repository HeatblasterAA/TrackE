import 'package:app/core/services/scan_service.dart';
import 'package:app/core/storage/local_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/auth_page.dart';
import '../dashboard/dashboard_page.dart';
import '../onboarding/onboarding_page.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/cloud_transaction_repository.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

Future<Widget> _resolve() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const AuthPage();
  }

  final onboardingDone =
      await LocalStorage.isOnboardingComplete();

  if (!onboardingDone) {
    return const OnboardingPage();
  }

  try {
    final repo = TransactionRepository();

    if (repo.getAllTyped().isEmpty) {
      final cloud =
          await CloudTransactionRepository()
              .fetchAll();

      if (cloud.isNotEmpty) {
        await repo.replaceAll(cloud);
      }
    }

    await ScanService.scan();
  } catch (e) {
    print('BOOT ERROR -> $e');
  }

  return const DashboardPage();
}
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, __) {
        return FutureBuilder<Widget>(
          future: _resolve(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return snapshot.data!;
          },
        );
      },
    );
  }
}