package com.amandev.tracke

import android.database.Cursor
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "tracke/sms"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(
            flutterEngine
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "readSmsHistory" -> {
                   val since =
    (call.argument<Number>("since")
        ?: 0).toLong()

                    result.success(readSms(since))
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun readSms(
        since: Long
    ): List<Map<String, Any?>> {
        val messages =
            mutableListOf<Map<String, Any?>>()

        val uri =
            Uri.parse("content://sms/inbox")

        val cursor: Cursor? =
            contentResolver.query(
                uri,
                arrayOf(
                    "address",
                    "body",
                    "date"
                ),
                "date > ?",
                arrayOf(since.toString()),
                "date DESC"
            )

        cursor?.use {
            val addressIndex =
                it.getColumnIndex("address")

            val bodyIndex =
                it.getColumnIndex("body")

            val dateIndex =
                it.getColumnIndex("date")

            while (it.moveToNext()) {
                val sender =
                    it.getString(addressIndex) ?: ""

                val body =
                    it.getString(bodyIndex) ?: ""

                val timestamp =
                    it.getLong(dateIndex)

                val financialSenders = listOf(
                    "BOB",
                    "HDFC",
                    "SBI",
                    "ICICI",
                    "AXIS",
                    "PAYTM",
                    "PHONEPE",
                    "GPAY",
                    "AMAZON",
                    "CRED"
                )

                val looksFinancial =
                    financialSenders.any {
                        sender.uppercase()
                            .contains(it)
                    }

                if (!looksFinancial) continue

                messages.add(
                    mapOf(
                        "sender" to sender,
                        "body" to body,
                        "timestamp" to timestamp
                    )
                )
            }
        }

        return messages
    }
}