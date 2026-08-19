package com.mogate.grammarfix

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Dedicated lightweight activity for Android ACTION_PROCESS_TEXT ("Fix grammar").
 * Handles writable text replacement returning RESULT_OK with EXTRA_PROCESS_TEXT,
 * or copy/share for read-only selections.
 */
class ProcessTextActivity : FlutterActivity() {
    private val CHANNEL_PROCESS_TEXT = "com.mogate.grammarfix/process_text_channel"

    private var processText: String? = null
    private var isReadOnly: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val text = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)
        processText = text?.toString()
        isReadOnly = intent.getBooleanExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PROCESS_TEXT).setMethodCallHandler { call, result ->
            when (call.method) {
                "getProcessTextData" -> {
                    result.success(mapOf(
                        "text" to (processText ?: ""),
                        "isReadOnly" to isReadOnly
                    ))
                }
                "applyCorrection" -> {
                    val correctedText = call.argument<String>("correctedText") ?: processText ?: ""
                    if (!isReadOnly) {
                        val resultIntent = Intent().apply {
                            putExtra(Intent.EXTRA_PROCESS_TEXT, correctedText)
                        }
                        setResult(Activity.RESULT_OK, resultIntent)
                    }
                    finish()
                    result.success(true)
                }
                "cancel" -> {
                    setResult(Activity.RESULT_CANCELED)
                    finish()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
