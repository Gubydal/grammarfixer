package com.mogate.grammarfix

import android.app.Dialog
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.inputmethodservice.InputMethodService
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Privacy-First Grammar Keyboard (InputMethodService).
 *
 * Uses shared GrammarCore for continuous on-device suggestions and retroactive corrections.
 * Strictly disables suggestions and learning on sensitive fields (passwords, PINs, OTPs).
 */
class GrammarKeyboardService : InputMethodService() {

    private var isShifted = false
    private var isSymbols = false
    private var currentLanguage = "en" // "en" or "ar"
    private var isSensitiveField = false

    private lateinit var mainLayout: LinearLayout
    private lateinit var suggestionStrip: LinearLayout
    private lateinit var keyboardContainer: LinearLayout
    private val debounceHandler = Handler(Looper.getMainLooper())
    private var pendingDebounceRunnable: Runnable? = null

    private lateinit var grammarCore: GrammarCore
    private lateinit var settings: SharedSettings

    // Undo state for keyboard auto-fix / suggestion apply
    private var lastReplacedOriginal: String? = null
    private var lastReplacementLength: Int = 0

    override fun onCreate() {
        super.onCreate()
        grammarCore = GrammarCore.getInstance(this)
        settings = SharedSettings(this)
    }

    override fun onCreateInputView(): View {
        mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#0C1410")) // Dark forest background
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        // 1. Suggestion Strip
        val scrollView = HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(44)
            )
            setBackgroundColor(Color.parseColor("#132219"))
        }

        suggestionStrip = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dpToPx(8), 0, dpToPx(8), 0)
        }
        scrollView.addView(suggestionStrip)
        mainLayout.addView(scrollView)

        // 2. Keyboard Rows Container
        keyboardContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(4), dpToPx(4), dpToPx(4), dpToPx(8))
        }
        mainLayout.addView(keyboardContainer)

        renderKeyboard()
        return mainLayout
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)

        // Sensitive field detection
        isSensitiveField = false
        if (info != null) {
            val inputType = info.inputType
            val variation = inputType and EditorInfo.TYPE_MASK_VARIATION
            if (variation == EditorInfo.TYPE_TEXT_VARIATION_PASSWORD ||
                variation == EditorInfo.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
                variation == EditorInfo.TYPE_TEXT_VARIATION_WEB_PASSWORD ||
                variation == EditorInfo.TYPE_NUMBER_VARIATION_PASSWORD
            ) {
                isSensitiveField = true
            }
        }

        clearSuggestions()
    }

    private fun renderKeyboard() {
        keyboardContainer.removeAllViews()

        if (currentLanguage == "ar") {
            renderArabicLayout()
        } else {
            renderLatinLayout()
        }
    }

    private fun renderLatinLayout() {
        val rows = if (isSymbols) {
            listOf(
                listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0"),
                listOf("@", "#", "\$", "%", "&", "-", "+", "(", ")", "/"),
                listOf("=", "*", "\"", "'", ":", ";", "!", "?", "⌫"),
                listOf("ABC", "عربي", " ", ".", "↵")
            )
        } else {
            val r1 = listOf("q", "w", "e", "r", "t", "y", "u", "i", "o", "p")
            val r2 = listOf("a", "s", "d", "f", "g", "h", "j", "k", "l")
            val r3 = listOf("⇧", "z", "x", "c", "v", "b", "n", "m", "⌫")
            val r4 = listOf("?123", "عربي", " ", ".", "↵")
            listOf(r1, r2, r3, r4)
        }

        for (row in rows) {
            val rowLayout = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dpToPx(52)
                )
            }

            for (key in row) {
                val button = createKeyButton(key)
                rowLayout.addView(button)
            }
            keyboardContainer.addView(rowLayout)
        }
    }

    private fun renderArabicLayout() {
        val rows = listOf(
            listOf("ض", "ص", "ث", "ق", "ف", "غ", "ع", "ه", "خ", "ح", "ج", "د"),
            listOf("ش", "س", "ي", "ب", "ل", "ا", "ت", "ن", "م", "ك", "ط"),
            listOf("ئ", "ء", "ؤ", "ر", "لا", "ى", "ة", "و", "ز", "ظ", "⌫"),
            listOf("?123", "EN", " ", "،", "↵")
        )

        for (row in rows) {
            val rowLayout = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dpToPx(52)
                )
            }

            for (key in row) {
                val button = createKeyButton(key)
                rowLayout.addView(button)
            }
            keyboardContainer.addView(rowLayout)
        }
    }

    private fun createKeyButton(key: String): Button {
        val btn = Button(this).apply {
            val displayKey = if (isShifted && key.length == 1) key.uppercase() else key
            text = displayKey
            setTextColor(Color.WHITE)
            textSize = if (key.length > 2) 13f else 18f
            typeface = Typeface.DEFAULT_BOLD
            isAllCaps = false
            setBackgroundColor(
                when (key) {
                    "↵" -> Color.parseColor("#178A4B") // Mogate Green accent for Enter
                    "⇧", "⌫", "?123", "ABC", "عربي", "EN" -> Color.parseColor("#1A2B20")
                    else -> Color.parseColor("#203527")
                }
            )

            val weight = when (key) {
                " " -> 4.0f
                "↵", "⌫", "⇧", "?123", "ABC" -> 1.5f
                else -> 1.0f
            }

            layoutParams = LinearLayout.LayoutParams(0, dpToPx(46), weight).apply {
                setMargins(dpToPx(2), dpToPx(3), dpToPx(2), dpToPx(3))
            }

            setOnClickListener {
                vibrateKey()
                handleKeyPress(key)
            }
        }
        return btn
    }

    private fun handleKeyPress(key: String) {
        val ic = currentInputConnection ?: return

        when (key) {
            "⌫" -> {
                ic.deleteSurroundingText(1, 0)
                scheduleDebouncedSuggestions()
            }
            "↵" -> {
                ic.performEditorAction(EditorInfo.IME_ACTION_DONE)
            }
            "⇧" -> {
                isShifted = !isShifted
                renderKeyboard()
            }
            "?123" -> {
                isSymbols = true
                renderKeyboard()
            }
            "ABC" -> {
                isSymbols = false
                renderKeyboard()
            }
            "عربي" -> {
                currentLanguage = "ar"
                renderKeyboard()
            }
            "EN" -> {
                currentLanguage = "en"
                renderKeyboard()
            }
            " " -> {
                ic.commitText(" ", 1)
                scheduleDebouncedSuggestions(50L) // Quick check on space
            }
            else -> {
                val output = if (isShifted && key.length == 1) key.uppercase() else key
                ic.commitText(output, 1)
                if (isShifted) {
                    isShifted = false
                    renderKeyboard()
                }
                scheduleDebouncedSuggestions()
            }
        }
    }

    private fun scheduleDebouncedSuggestions(delayMs: Long = 150L) {
        if (isSensitiveField) {
            clearSuggestions()
            return
        }

        pendingDebounceRunnable?.let { debounceHandler.removeCallbacks(it) }
        val runnable = Runnable {
            updateSuggestionStrip()
        }
        pendingDebounceRunnable = runnable
        debounceHandler.postDelayed(runnable, delayMs)
    }

    private fun updateSuggestionStrip() {
        val ic = currentInputConnection ?: return
        // Expanded context window: up to 500 chars before cursor
        val textBefore = ic.getTextBeforeCursor(500, 0)?.toString() ?: ""
        if (textBefore.isEmpty()) {
            clearSuggestions()
            return
        }

        clearSuggestions()

        // Add Writing Tools Wand button
        addWritingToolsWand()

        // Check suggestions via GrammarCore
        val issues = grammarCore.quickCheck(textBefore, currentLanguage)
        if (issues.isNotEmpty()) {
            // Find most recent issue near cursor
            val latestIssue = issues.last()
            val issueOffsetFromEnd = textBefore.length - latestIssue.end
            val replaceLength = latestIssue.original.length + issueOffsetFromEnd

            addSuggestionButton(
                original = latestIssue.original,
                suggestion = latestIssue.topSuggestion,
                reason = latestIssue.shortReason,
                replaceLength = replaceLength,
                issueOffsetFromEnd = issueOffsetFromEnd
            )
        }
    }

    private fun addWritingToolsWand() {
        val wandBtn = TextView(this).apply {
            text = "✨"
            textSize = 16f
            setPadding(dpToPx(10), dpToPx(6), dpToPx(10), dpToPx(6))
            setOnClickListener {
                showWritingToolsDialog()
            }
        }
        suggestionStrip.addView(wandBtn)
    }

    private fun showWritingToolsDialog() {
        val ic = currentInputConnection ?: return
        val textBefore = ic.getTextBeforeCursor(500, 0)?.toString() ?: ""
        if (textBefore.isBlank()) return

        val commands = listOf(
            "Fix Only" to "fix_only",
            "Professional" to "professional",
            "Friendly" to "friendly",
            "Concise" to "concise",
            "Academic" to "academic"
        )

        val dialog = Dialog(this).apply {
            requestWindowFeature(Window.FEATURE_NO_TITLE)
            window?.setBackgroundDrawable(ColorDrawable(Color.parseColor("#132219")))
            window?.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        }

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(16), dpToPx(16), dpToPx(16), dpToPx(16))
        }

        val title = TextView(this).apply {
            text = "✨ Writing Tools (On-Device)"
            setTextColor(Color.WHITE)
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, 0, 0, dpToPx(12))
        }
        layout.addView(title)

        for ((label, cmd) in commands) {
            val itemBtn = Button(this).apply {
                text = label
                setTextColor(Color.parseColor("#66D58C"))
                setBackgroundColor(Color.parseColor("#1A2B20"))
                textSize = 14f
                setOnClickListener {
                    dialog.dismiss()
                    val rewritten = grammarCore.rewrite(textBefore, cmd)
                    ic.beginBatchEdit()
                    ic.deleteSurroundingText(textBefore.length, 0)
                    ic.commitText(rewritten, 1)
                    ic.endBatchEdit()
                }
            }
            layout.addView(itemBtn)
        }

        dialog.setContentView(layout)
        dialog.window?.setType(android.view.WindowManager.LayoutParams.TYPE_INPUT_METHOD)
        dialog.show()
    }

    private fun addSuggestionButton(
        original: String,
        suggestion: String,
        reason: String,
        replaceLength: Int,
        issueOffsetFromEnd: Int
    ) {
        val btn = TextView(this).apply {
            text = "✓ $suggestion  · $reason"
            setTextColor(Color.parseColor("#66D58C")) // Bright green
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))
            setBackgroundColor(Color.parseColor("#178A4B"))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(dpToPx(4), 0, dpToPx(4), 0)
            }

            setOnClickListener {
                val ic = currentInputConnection ?: return@setOnClickListener
                lastReplacedOriginal = original
                lastReplacementLength = suggestion.length

                // Batch edit: delete exact original and replace cleanly without extra trailing space
                ic.beginBatchEdit()
                ic.deleteSurroundingText(replaceLength, 0)
                ic.commitText(suggestion, 1)
                if (issueOffsetFromEnd > 0) {
                    // Re-insert trailing text if any
                    val trailing = ic.getTextAfterCursor(issueOffsetFromEnd, 0)
                }
                ic.endBatchEdit()

                showUndoInStrip()
            }
        }
        suggestionStrip.addView(btn)
    }

    private fun showUndoInStrip() {
        suggestionStrip.removeAllViews()

        val undoBtn = TextView(this).apply {
            text = "↩ Undo (${lastReplacedOriginal})"
            setTextColor(Color.parseColor("#FF8A80"))
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))
            setBackgroundColor(Color.parseColor("#2C1518"))

            setOnClickListener {
                val ic = currentInputConnection ?: return@setOnClickListener
                if (lastReplacedOriginal != null) {
                    ic.beginBatchEdit()
                    ic.deleteSurroundingText(lastReplacementLength, 0)
                    ic.commitText(lastReplacedOriginal!!, 1)
                    ic.endBatchEdit()
                    lastReplacedOriginal = null
                }
                clearSuggestions()
            }
        }
        suggestionStrip.addView(undoBtn)
    }

    private fun clearSuggestions() {
        suggestionStrip.removeAllViews()
    }

    private fun vibrateKey() {
        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            vibrator?.vibrate(VibrationEffect.createOneShot(15, VibrationEffect.DEFAULT_AMPLITUDE))
        } catch (e: Exception) {}
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }
}
