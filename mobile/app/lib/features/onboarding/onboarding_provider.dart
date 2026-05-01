import 'package:app/core/storage/local_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingCompleteProvider = Provider((ref) {
  return LocalStorage();
});