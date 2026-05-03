import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/ingestion/manual_source.dart';
import 'core/ingestion/notification_source.dart';
import 'core/services/scan_service.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/raw_signal_log.dart';
import 'features/parser/user_rule_memory.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await HiveService.init();
  await RawSignalLog.init();
  await UserRuleMemory.init();

  ScanService.start([
    NotificationSource(),
    ManualSource.instance,
  ]);

  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    );
    return true;
  };

  runApp(
    const ProviderScope(
      child: TrackEApp(),
    ),
  );
}
