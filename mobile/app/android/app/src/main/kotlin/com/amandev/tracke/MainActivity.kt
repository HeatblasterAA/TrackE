package com.amandev.tracke

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NotificationBridge.CHANNEL_NAME,
        ).setMethodCallHandler(NotificationBridge(applicationContext))

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NotificationSignalChannel.CHANNEL_NAME,
        ).setStreamHandler(NotificationSignalChannel)
    }
}
