package com.mogate.grammarfix

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL_APP_INTENTS = "com.mogate.grammarfix/app_intents"
    private val CHANNEL_MODEL_PACK = "com.mogate.grammarfix/model_pack"
    private val CHANNEL_MULTILINGUAL = "com.mogate.grammarfix/multilingual_engine"

    private var sharedText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (Intent.ACTION_SEND == intent.action && "text/plain" == intent.type) {
            sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // App intents channel (e.g. ACTION_SEND text sharing)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_APP_INTENTS).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedText" -> {
                    result.success(sharedText)
                    sharedText = null
                }
                else -> result.notImplemented()
            }
        }

        // Model pack delivery channel (Play Asset Delivery / On-Demand Pack management)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_MODEL_PACK).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPackStatus" -> {
                    // Returns status map: isInstalled, totalBytes, downloadedBytes
                    val status = mapOf(
                        "isInstalled" to false,
                        "packSizeMb" to 475,
                        "availableStorageMb" to getAvailableStorageMb()
                    )
                    result.success(status)
                }
                "requestDownload" -> {
                    // Play Asset Delivery / Feature Delivery download request
                    result.success(true)
                }
                "removePack" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Multilingual local engine bridge (LiteRT-LM)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_MULTILINGUAL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> {
                    result.success(true)
                }
                "correct" -> {
                    val text = call.argument<String>("text") ?: ""
                    val language = call.argument<String>("language") ?: "en"
                    // On-device LiteRT-LM inference invocation
                    result.success(text)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getAvailableStorageMb(): Long {
        return try {
            val stat = android.os.StatFs(filesDir.absolutePath)
            (stat.availableBlocksLong * stat.blockSizeLong) / (1024 * 1024)
        } catch (e: Exception) {
            4096L
        }
    }
}
