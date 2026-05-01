import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/storage/local_storage.dart';
enum BootState {
  loading,
  unauthenticated,
  onboarding,
  ready,
}

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final appBootProvider = FutureProvider<BootState>((ref) async {
  final auth = await ref.watch(authStateProvider.future);

  if (auth == null) {
    return BootState.unauthenticated;
  }

  final onboardingDone =
      await LocalStorage.isOnboardingComplete();

  if (!onboardingDone) {
    return BootState.onboarding;
  }

  return BootState.ready;
});