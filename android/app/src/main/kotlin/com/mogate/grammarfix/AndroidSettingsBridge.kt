package com.mogate.grammarfix

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Native Android bridge for system settings access.
 *
 * Replaces broken url_launcher usage for Android intent actions.
 * Provides real IME status detection using InputMethodManager.
 */
class AndroidSettingsBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.mogate.grammarfix/android_settings"
        private const val KEYBOARD_SERVICE_ID = "com.mogate.grammarfix/.GrammarKeyboardService"
        private const val SPELL_SERVICE_ID = "com.mogate.grammarfix/.GrammarSpellCheckerService"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openInputMethodSettings" -> openInputMethodSettings(result)
            "showInputMethodPicker" -> showInputMethodPicker(result)
            "getKeyboardStatus" -> getKeyboardStatus(result)
            "getSpellCheckerStatus" -> getSpellCheckerStatus(result)
            "openSpellCheckerSettingsIfSupported" -> openSpellCheckerSettingsIfSupported(result)
            else -> result.notImplemented()
        }
    }

    private fun openInputMethodSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                result.success(true)
            } else {
                // Fallback: try generic Settings
                val fallback = Intent(Settings.ACTION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(fallback)
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", "Cannot open input method settings: ${e.message}", null)
        }
    }

    private fun showInputMethodPicker(result: MethodChannel.Result) {
        try {
            val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
            if (imm != null) {
                imm.showInputMethodPicker()
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("PICKER_ERROR", "Cannot show input method picker: ${e.message}", null)
        }
    }

    private fun getKeyboardStatus(result: MethodChannel.Result) {
        try {
            val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
            if (imm == null) {
                result.success(mapOf(
                    "installed" to false,
                    "enabled" to false,
                    "active" to false
                ))
                return
            }

            // Check if GrammarFix is in the list of installed IMEs
            val allInputMethods = imm.inputMethodList
            val grammarFixIme = allInputMethods.find {
                it.id.contains("com.mogate.grammarfix") &&
                it.id.contains("GrammarKeyboardService")
            }
            val isInstalled = grammarFixIme != null

            // Check if it's enabled (user has turned it on in settings)
            val enabledInputMethods = imm.enabledInputMethodList
            val isEnabled = enabledInputMethods.any {
                it.id.contains("com.mogate.grammarfix") &&
                it.id.contains("GrammarKeyboardService")
            }

            // Check if it's the currently active/default IME
            val defaultImeId = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.DEFAULT_INPUT_METHOD
            ) ?: ""
            val isActive = defaultImeId.contains("com.mogate.grammarfix") &&
                    defaultImeId.contains("GrammarKeyboardService")

            result.success(mapOf(
                "installed" to isInstalled,
                "enabled" to isEnabled,
                "active" to isActive,
                "defaultImeId" to defaultImeId
            ))
        } catch (e: Exception) {
            result.error("STATUS_ERROR", "Cannot get keyboard status: ${e.message}", null)
        }
    }

    private fun getSpellCheckerStatus(result: MethodChannel.Result) {
        try {
            // Check if our spell checker service is declared in the manifest
            // The actual enabled state is managed by Android system settings
            val packageInfo = context.packageManager.getPackageInfo(
                context.packageName,
                android.content.pm.PackageManager.GET_SERVICES
            )
            val hasSpellService = packageInfo.services?.any {
                it.name.contains("GrammarSpellCheckerService")
            } ?: false

            result.success(mapOf(
                "available" to hasSpellService,
                "serviceId" to SPELL_SERVICE_ID
            ))
        } catch (e: Exception) {
            result.success(mapOf(
                "available" to false,
                "serviceId" to ""
            ))
        }
    }

    private fun openSpellCheckerSettingsIfSupported(result: MethodChannel.Result) {
        try {
            // Android doesn't have a direct spell checker settings intent on all devices
            // Try ACTION_TEXT_SERVICES first, then fall back to language & input
            val textServicesIntent = Intent("android.settings.TEXT_SERVICES_SETTINGS").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (textServicesIntent.resolveActivity(context.packageManager) != null) {
                context.startActivity(textServicesIntent)
                result.success(true)
            } else {
                // Fallback to input method settings which often contains spell checker
                val fallback = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(fallback)
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", "Cannot open spell checker settings: ${e.message}", null)
        }
    }
}
