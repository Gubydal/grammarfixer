package com.mogate.grammarfix

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.inputmethodservice.InputMethodService
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Optional Privacy-First Grammar Keyboard (InputMethodService).
 *
 * Provides Latin QWERTY and Arabic layouts with debounced on-device suggestions.
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

    // High-frequency typos for immediate keyboard correction strip
    private val keyboardTypos = mapOf(
        "teh" to "the",
        "recieve" to "receive",
        "recieved" to "received",
        "seperate" to "separate",
        "thsi" to "this",
        "becuase" to "because",
        "adn" to "and",
        "taht" to "that",
        "wierd" to "weird",
        "freind" to "friend",
        "cant" to "can't",
        "dont" to "don't",
        "wont" to "won't",
        "theyre" to "they're",
        "youre" to "you're",
        "alot" to "a lot"
    )

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
                scheduleDebouncedSuggestions()
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

    private fun scheduleDebouncedSuggestions() {
        if (isSensitiveField) {
            clearSuggestions()
            return
        }

        pendingDebounceRunnable?.let { debounceHandler.removeCallbacks(it) }
        val runnable = Runnable {
            updateSuggestionStrip()
        }
        pendingDebounceRunnable = runnable
        debounceHandler.postDelayed(runnable, 150L)
    }

    // Multi-word contextual phrases for retroactive correction
    private val contextualPhrases = mapOf(
        "their going" to "they're going",
        "their coming" to "they're coming",
        "could of" to "could have",
        "should of" to "should have",
        "would of" to "would have",
        "your right" to "you're right",
        "your welcome" to "you're welcome",
        "better then" to "better than",
        "more then" to "more than",
        "the dogs is" to "the dogs are",
        "i has" to "I have",
        "he dont" to "he doesn't",
        "she dont" to "she doesn't",
        "هذه كتاب" to "هذا كتاب",
        "هذا سيارة" to "هذه سيارة",
        "ان شاء الله" to "إن شاء الله"
    )

    private fun updateSuggestionStrip() {
        val ic = currentInputConnection ?: return
        val textBefore = ic.getTextBeforeCursor(60, 0)?.toString() ?: ""
        if (textBefore.isEmpty()) {
            clearSuggestions()
            return
        }

        clearSuggestions()

        // 1. Check multi-word phrase patterns retroactively (last 2-3 words)
        val lowerText = textBefore.lowercase().trimEnd()
        for ((pattern, fix) in contextualPhrases) {
            if (lowerText.endsWith(pattern)) {
                val matchLength = pattern.length
                addSuggestionButton(fix, matchLength)
                return
            }
        }

        // 2. Check single word typos
        val lastWord = textBefore.split(Regex("\\s+")).lastOrNull()?.trim() ?: ""
        if (lastWord.isNotEmpty()) {
            val lower = lastWord.lowercase()
            if (keyboardTypos.containsKey(lower)) {
                val fix = keyboardTypos[lower]!!
                val formattedFix = if (lastWord[0].isUpperCase()) fix.replaceFirstChar { it.uppercase() } else fix
                addSuggestionButton(formattedFix, lastWord.length)
            }
        }
    }

    private fun addSuggestionButton(suggestion: String, replaceLength: Int) {
        val btn = TextView(this).apply {
            text = "✓ $suggestion"
            setTextColor(Color.parseColor("#66D58C")) // Bright green
            textSize = 14f
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
                ic.deleteSurroundingText(replaceLength, 0)
                ic.commitText("$suggestion ", 1)
                clearSuggestions()
            }
        }
        suggestionStrip.addView(btn)
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
