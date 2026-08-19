package com.mogate.grammarfix

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.view.Window
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

/**
 * Lightweight native Android ACTION_PROCESS_TEXT ("Fix grammar") dialog activity.
 * Immediately runs GrammarCore without spinning up FlutterEngine.
 * Directly replaces text via RESULT_OK for writable selections, or copies to clipboard for read-only.
 */
class ProcessTextActivity : Activity() {

    private lateinit var grammarCore: GrammarCore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        window?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))

        grammarCore = GrammarCore.getInstance(this)

        val rawText = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString() ?: ""
        val isReadOnly = intent.getBooleanExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, false)

        if (rawText.isBlank()) {
            finish()
            return
        }

        // Run fast on-device correction
        val result = grammarCore.correct(rawText)

        // Show compact native dialog
        showCorrectionDialog(rawText, result.correctedText, result.issues.size, isReadOnly)
    }

    private fun showCorrectionDialog(
        original: String,
        corrected: String,
        issueCount: Int,
        isReadOnly: Boolean
    ) {
        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#132219")) // Dark forest
            setPadding(dpToPx(20), dpToPx(20), dpToPx(20), dpToPx(20))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        val title = TextView(this).apply {
            text = "✨ GrammarFix"
            setTextColor(Color.WHITE)
            textSize = 17f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setPadding(0, 0, 0, dpToPx(12))
        }
        rootLayout.addView(title)

        val summary = TextView(this).apply {
            text = if (issueCount == 0) "No issues found! Text looks great." else "$issueCount ${if (issueCount == 1) "fix" else "fixes"} found"
            setTextColor(Color.parseColor("#66D58C"))
            textSize = 13f
            setPadding(0, 0, 0, dpToPx(8))
        }
        rootLayout.addView(summary)

        val preview = TextView(this).apply {
            text = corrected
            setTextColor(Color.WHITE)
            textSize = 15f
            setPadding(dpToPx(12), dpToPx(10), dpToPx(12), dpToPx(10))
            setBackgroundColor(Color.parseColor("#1A2B20"))
        }
        rootLayout.addView(preview)

        val buttonBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END
            setPadding(0, dpToPx(16), 0, 0)
        }

        val cancelBtn = Button(this).apply {
            text = "Cancel"
            setTextColor(Color.parseColor("#9E9E9E"))
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener {
                setResult(Activity.RESULT_CANCELED)
                finish()
            }
        }
        buttonBar.addView(cancelBtn)

        val actionBtn = Button(this).apply {
            text = if (isReadOnly) "Copy text" else "Apply"
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#178A4B"))
            setOnClickListener {
                if (isReadOnly) {
                    val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
                    clipboard?.setPrimaryClip(ClipData.newPlainText("GrammarFix", corrected))
                    Toast.makeText(this@ProcessTextActivity, "Copied to clipboard", Toast.LENGTH_SHORT).show()
                } else {
                    val resultIntent = Intent().apply {
                        putExtra(Intent.EXTRA_PROCESS_TEXT, corrected)
                    }
                    setResult(Activity.RESULT_OK, resultIntent)
                }
                finish()
            }
        }
        buttonBar.addView(actionBtn)

        rootLayout.addView(buttonBar)

        setContentView(rootLayout)
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }
}
