package com.example.notifhub.notif_hub

import android.provider.Telephony
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val smsChannel = "notif_hub/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, smsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "fetchSmsInbox" -> {
                        val limit = call.argument<Int>("limit") ?: 200
                        result.success(fetchSmsInbox(limit))
                    }
                    "fetchSmsThreads" -> {
                        val limit = call.argument<Int>("limit") ?: 100
                        result.success(fetchSmsThreads(limit))
                    }
                    "fetchSmsThreadMessages" -> {
                        val threadId = call.argument<Number>("threadId")?.toLong()
                        if (threadId == null) {
                            result.error("invalid_args", "threadId is required", null)
                            return@setMethodCallHandler
                        }
                        val limit = call.argument<Int>("limit") ?: 500
                        result.success(fetchSmsThreadMessages(threadId, limit))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun fetchSmsInbox(limit: Int): List<Map<String, Any?>> {
        val rows = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE
        )

        val cursor = contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            projection,
            null,
            null,
            "${Telephony.Sms.DATE} DESC"
        )

        cursor?.use {
            var count = 0
            while (it.moveToNext() && count < limit) {
                rows.add(
                    mapOf(
                        "id" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms._ID)),
                        "address" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)),
                        "body" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY)),
                        "date" to it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.DATE))
                    )
                )
                count++
            }
        }

        return rows
    }

    private fun fetchSmsThreads(limit: Int): List<Map<String, Any?>> {
        val byThread = linkedMapOf<Long, MutableMap<String, Any?>>()
        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.THREAD_ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE
        )

        val cursor = contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            projection,
            null,
            null,
            "${Telephony.Sms.DATE} DESC"
        )

        cursor?.use {
            while (it.moveToNext()) {
                val threadId =
                    it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.THREAD_ID))
                val existing = byThread[threadId]
                if (existing == null) {
                    if (byThread.size >= limit) {
                        continue
                    }
                    byThread[threadId] = mutableMapOf(
                        "threadId" to threadId,
                        "id" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms._ID)),
                        "address" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)),
                        "snippet" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY)),
                        "date" to it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.DATE)),
                        "messageCount" to 1
                    )
                } else {
                    val count = (existing["messageCount"] as? Int) ?: 0
                    existing["messageCount"] = count + 1
                }
            }
        }

        return byThread.values.toList()
    }

    private fun fetchSmsThreadMessages(threadId: Long, limit: Int): List<Map<String, Any?>> {
        val rows = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.THREAD_ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
            Telephony.Sms.TYPE
        )
        val selection = "${Telephony.Sms.THREAD_ID} = ?"
        val selectionArgs = arrayOf(threadId.toString())

        val cursor = contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            "${Telephony.Sms.DATE} DESC"
        )

        cursor?.use {
            var count = 0
            while (it.moveToNext() && count < limit) {
                rows.add(
                    mapOf(
                        "id" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms._ID)),
                        "threadId" to it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.THREAD_ID)),
                        "address" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)),
                        "body" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY)),
                        "date" to it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.DATE)),
                        "type" to it.getInt(it.getColumnIndexOrThrow(Telephony.Sms.TYPE))
                    )
                )
                count++
            }
        }

        return rows
    }
}
