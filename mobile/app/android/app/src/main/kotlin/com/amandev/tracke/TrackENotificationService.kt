package com.amandev.tracke

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class TrackENotificationService : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        NotificationSignalChannel.markListenerAlive()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        if (packageName == applicationContext.packageName) return

        val extras = sbn.notification?.extras ?: return

        val title = firstNonBlank(
            extras.getCharSequence(Notification.EXTRA_TITLE)?.toString(),
            extras.getCharSequence(Notification.EXTRA_TITLE_BIG)?.toString(),
        )

        val body = firstNonBlank(
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString(),
            joinTextLines(extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)),
            extras.getCharSequence(Notification.EXTRA_TEXT)?.toString(),
            extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString(),
        )

        if (title.isNullOrBlank() && body.isNullOrBlank()) return

        val combined = "${title.orEmpty()} ${body.orEmpty()}"

        // Always reject auth/security noise even if it slips through.
        if (NotificationFilters.isSecurityNoise(combined)) return

        val matchedBy = when {
            NotificationFilters.isAllowlistedPackage(packageName) -> "allowlist"
            NotificationFilters.looksTransactional(combined) -> "heuristic"
            else -> return
        }

        NotificationSignalChannel.emit(
            packageName = packageName,
            title = title.orEmpty(),
            body = body.orEmpty(),
            timestamp = sbn.postTime,
            matchedBy = matchedBy,
        )
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // No-op. We snapshot at post time.
    }

    private fun firstNonBlank(vararg candidates: String?): String? {
        for (c in candidates) {
            if (!c.isNullOrBlank()) return c
        }
        return null
    }

    private fun joinTextLines(lines: Array<CharSequence>?): String? {
        if (lines == null || lines.isEmpty()) return null
        return lines.joinToString(separator = "\n") { it.toString() }
            .ifBlank { null }
    }
}
