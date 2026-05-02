import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:ui';
import 'app.dart';
import 'core/storage/hive_service.dart';
import 'firebase_options.dart';
import 'core/services/scan_service.dart';
import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

const scanTask = "sms_scan_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await HiveService.init();

      if (task == scanTask) {
        await ScanService.scan();
      }

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

 void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform,
  );

  await HiveService.init();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  await Workmanager().registerPeriodicTask(
    scanTask,
    scanTask,
    frequency: const Duration(
      hours: 6,
    ),
  );

  FlutterError.onError =
      FirebaseCrashlytics
          .instance
          .recordFlutterFatalError;

  PlatformDispatcher.instance.onError =
      (error, stack) {
        FirebaseCrashlytics.instance
            .recordError(
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