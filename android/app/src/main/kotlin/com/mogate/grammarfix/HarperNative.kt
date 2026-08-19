package com.mogate.grammarfix

import android.util.Log

/**
 * JNI wrapper for the native Harper grammar checker.
 * Safely handles cases where the native .so is not present on device.
 */
object HarperNative {
    private const val TAG = "HarperNative"
    private var isLoaded = false
    private var nativeContextPtr: Long = 0

    init {
        try {
            System.loadLibrary("harper_bridge")
            isLoaded = true
            Log.i(TAG, "libharper_bridge loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            isLoaded = false
            Log.w(TAG, "libharper_bridge not available; using Kotlin rules fallback: ${e.message}")
        }
    }

    fun isAvailable(): Boolean = isLoaded

    // Native C-ABI signatures (external methods)
    private external fun harperCreate(dialect: Int): Long
    private external fun harperDestroy(ctx: Long)
    private external fun harperAddUserWord(ctx: Long, word: String): Int
    private external fun harperRemoveUserWord(ctx: Long, word: String): Int
    private external fun harperLintJson(ctx: Long, text: String): String?

    @Synchronized
    fun initContext(dialect: Int = 0) {
        if (!isLoaded) return
        if (nativeContextPtr != 0L) {
            destroyContext()
        }
        try {
            nativeContextPtr = harperCreate(dialect)
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to create Harper context", e)
        }
    }

    @Synchronized
    fun destroyContext() {
        if (!isLoaded || nativeContextPtr == 0L) return
        try {
            harperDestroy(nativeContextPtr)
            nativeContextPtr = 0L
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to destroy Harper context", e)
        }
    }

    @Synchronized
    fun addUserWord(word: String): Boolean {
        if (!isLoaded || nativeContextPtr == 0L) return false
        return try {
            harperAddUserWord(nativeContextPtr, word) == 0
        } catch (e: Throwable) {
            false
        }
    }

    @Synchronized
    fun lintText(text: String): String? {
        if (!isLoaded || nativeContextPtr == 0L) return null
        return try {
            harperLintJson(nativeContextPtr, text)
        } catch (e: Throwable) {
            Log.e(TAG, "Harper lint failed", e)
            null
        }
    }
}
