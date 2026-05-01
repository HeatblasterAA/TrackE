import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  static const _storage = FlutterSecureStorage();

  static const _onboardingKey = 'onboarding_completed';

  static Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }
  static Future<void> clear() async {
  await _storage.deleteAll();
}

  static Future<void> setOnboardingComplete() async {
    await _storage.write(
      key: _onboardingKey,
      value: 'true',
    );
  }
}