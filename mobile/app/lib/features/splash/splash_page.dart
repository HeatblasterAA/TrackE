import 'package:app/core/storage/local_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/auth_page.dart';
import '../dashboard/dashboard_page.dart';
import '../onboarding/onboarding_page.dart';

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