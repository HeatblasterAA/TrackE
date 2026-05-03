package com.amandev.tracke

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Control channel for the notification listener:
 *   - isListenerEnabled(): Boolean
 *   - openListenerSettings(): void
 *
 * The data stream itself flows over [NotificationSignalChannel].
 */
class NotificationBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "tracke/notifications/control"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isListenerEnabled" -> {
                result.success(isListenerEnabled())
            }
            "openListenerSettings" -> {
                openListenerSettings()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun isListenerEnabled(): Boolean {
        val pkg = context.packageName
        val enabled = NotificationManagerCompat.getEnabledListenerPackages(context)
        if (!enabled.contains(pkg)) return false

        // Also confirm our specific component is enabled (defensive against
        // stale cached listings on some OEMs).
        val component = ComponentName(context, TrackENotificationService::class.java)
        val flat = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false

        return flat.split(":").any { it.equals(component.flattenToString(), ignoreCase = true) }
    }

    private fun openListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
}
