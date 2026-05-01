import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/local_storage.dart';

enum BootState {
  loading,
  unauthenticated,
  onboarding,
  ready,
}

final appBootProvider = FutureProvider<BootState>((ref) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return BootState.unauthenticated;
  }

  final onboardingDone =
      await LocalStorage.isOnboardingComplete();

  if (!onboardingDone) {
    return BootState.onboarding;
  }

  return BootState.ready;
});