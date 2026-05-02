import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  static const _storage = FlutterSecureStorage();

  static const _onboardingKey =
      'onboarding_completed';

  static const _lastScanKey = 'last_scan_at';
  static const _pendingScanKey = 'pending_scan';

  static Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(
      key: _onboardingKey,
    );

    return value == 'true';
  }
  static Future<bool> hasPendingScan() async {
  final value = await _storage.read(
    key: _pendingScanKey,
  );

  return value == 'true';
}

static Future<void> setPendingScan(
  bool value,
) async {
  await _storage.write(
    key: _pendingScanKey,
    value: value.toString(),
  );
}
static Future<void> clearScanState() async {
  await _storage.delete(key: _lastScanKey);
}

  static Future<void> setOnboardingComplete() async {
    await _storage.write(
      key: _onboardingKey,
      value: 'true',
    );
  }

  static Future<int?> getLastScanAt() async {
    final value = await _storage.read(
      key: _lastScanKey,
    );

    if (value == null) return null;

    return int.tryParse(value);
  }

  static Future<void> setLastScanAt(
    int timestamp,
  ) async {
    await _storage.write(
      key: _lastScanKey,
      value: timestamp.toString(),
    );
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}