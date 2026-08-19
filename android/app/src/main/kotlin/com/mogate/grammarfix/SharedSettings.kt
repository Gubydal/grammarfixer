package com.mogate.grammarfix

import android.content.Context
import android.content.SharedPreferences

/**
 * Shared preferences helper accessible from Android native layer (Keyboard, SpellChecker, ProcessText)
 * and synced with Flutter Dart SharedPreferences (using 'flutter.' prefix where appropriate).
 */
class SharedSettings(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(
        "${context.packageName}_preferences",
        Context.MODE_PRIVATE
    )
    private val flutterPrefs: SharedPreferences = context.getSharedPreferences(
        "FlutterSharedPreferences",
        Context.MODE_PRIVATE
    )

    companion object {
        private const val KEY_AUTO_FIX = "flutter.grammarfix_auto_fix_enabled"
        private const val KEY_PRIVATE_MODE = "flutter.grammarfix_private_mode"
        private const val KEY_DIALECT = "flutter.grammarfix_dialect"
        private const val KEY_CUSTOM_WORDS = "flutter.custom_dictionary_words"
        private const val KEY_STYLE_PREFS = "flutter.grammarfix_style_profile"
    }

    val isAutoFixEnabled: Boolean
        get() = flutterPrefs.getBoolean(KEY_AUTO_FIX, true)

    val isPrivateMode: Boolean
        get() = flutterPrefs.getBoolean(KEY_PRIVATE_MODE, false)

    val dialect: String
        get() = flutterPrefs.getString(KEY_DIALECT, "us") ?: "us"

    val customWords: Set<String>
        get() = flutterPrefs.getStringSet(KEY_CUSTOM_WORDS, emptySet()) ?: emptySet()
}
