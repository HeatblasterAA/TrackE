package com.amandev.tracke

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.util.ArrayDeque

/**
 * Bridges TrackENotificationService -> Flutter via an EventChannel.
 *
 * The listener service can fire before Dart attaches its sink (especially if the
 * service is auto-restarted by the system). We buffer up to BUFFER_LIMIT events
 * and flush as soon as a sink connects.
 */
object NotificationSignalChannel : EventChannel.StreamHandler {

    const val CHANNEL_NAME = "tracke/notifications/stream"
    private const val BUFFER_LIMIT = 100

    private val mainHandler = Handler(Looper.getMainLooper())
    private val pending = ArrayDeque<Map<String, Any?>>()

    @Volatile
    private var sink: EventChannel.EventSink? = null

    @Volatile
    private var listenerAlive: Boolean = false

    fun markListenerAlive() {
        listenerAlive = true
    }

    fun isListenerAlive(): Boolean = listenerAlive

    fun emit(
        packageName: String,
        title: String,
        body: String,
        timestamp: Long,
        matchedBy: String,
    ) {
        val payload: Map<String, Any?> = mapOf(
            "source" to "notification",
            "sender" to packageName,
            "title" to title,
            "body" to body,
            "timestamp" to timestamp,
            "matchedBy" to matchedBy,
        )

        mainHandler.post {
            val s = sink
            if (s != null) {
                s.success(payload)
            } else {
                if (pending.size >= BUFFER_LIMIT) {
                    pending.pollFirst()
                }
                pending.addLast(payload)
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        if (events == null) return
        while (pending.isNotEmpty()) {
            events.success(pending.pollFirst())
        }
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}
