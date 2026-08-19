package com.mogate.grammarfix

import android.content.Context
import android.util.Log

data class NativeCorrectionIssue(
    val id: String,
    val start: Int,
    val end: Int,
    val original: String,
    val suggestions: List<String>,
    val message: String,
    val shortReason: String,
    val category: String,
    val isAutoFixable: Boolean,
    val confidence: String // "high", "medium", "low"
) {
    val topSuggestion: String
        get() = suggestions.firstOrNull() ?: ""
}

data class NativeCorrectionResult(
    val sourceText: String,
    val correctedText: String,
    val issues: List<NativeCorrectionIssue>,
    val engineUsed: String,
    val latencyMs: Long
)

/**
 * Shared Native Grammar Core for system-wide correction on Android.
 * Used by GrammarKeyboardService, GrammarSpellCheckerService, and ProcessTextActivity.
 */
class GrammarCore private constructor(private val context: Context) {

    private val settings = SharedSettings(context)
    private val modelManager = LocalContextModelManager(context)

    companion object {
        private const val TAG = "GrammarCore"

        @Volatile
        private var instance: GrammarCore? = null

        fun getInstance(context: Context): GrammarCore {
            return instance ?: synchronized(this) {
                instance ?: GrammarCore(context.applicationContext).also { instance = it }
            }
        }

        // Fast high-frequency typos
        private val TYPO_MAP = mapOf(
            "teh" to "the",
            "recieve" to "receive",
            "recieved" to "received",
            "recieving" to "receiving",
            "seperate" to "separate",
            "seperated" to "separated",
            "thsi" to "this",
            "becuase" to "because",
            "adn" to "and",
            "taht" to "that",
            "wierd" to "weird",
            "freind" to "friend",
            "freinds" to "friends",
            "occured" to "occurred",
            "untill" to "until",
            "truely" to "truly",
            "definately" to "definitely",
            "definitly" to "definitely",
            "accomodate" to "accommodate",
            "embarass" to "embarrass",
            "neccessary" to "necessary",
            "goverment" to "government",
            "tommorow" to "tomorrow",
            "adress" to "address",
            "belive" to "believe",
            "cant" to "can't",
            "dont" to "don't",
            "wont" to "won't",
            "theyre" to "they're",
            "youre" to "you're",
            "alot" to "a lot",
            "aswell" to "as well",
            "everytime" to "every time"
        )

        // Context phrases (multi-word retroactive triggers)
        private val CONTEXT_PHRASES = listOf(
            Triple(Regex("\\b[Tt]heir\\s+(going|coming|leaving|arriving|running|walking|trying|doing|making|getting|having|being|not)\\b", RegexOption.IGNORE_CASE), "they're", "Word choice"),
            Triple(Regex("\\b[Yy]our\\s+(going|coming|being|getting|making|doing|not|right|welcome)\\b", RegexOption.IGNORE_CASE), "you're", "Word choice"),
            Triple(Regex("\\b(could|should|would|must|might)\\s+of\\b", RegexOption.IGNORE_CASE), "have", "Grammar"),
            Triple(Regex("\\b(better|more|less|rather|other|faster|slower|bigger|smaller)\\s+then\\b", RegexOption.IGNORE_CASE), "than", "Word choice"),
            Triple(Regex("\\bI\\s+has\\b"), "have", "Agreement"),
            Triple(Regex("\\b[Tt]he\\s+\\w+s\\s+is\\b", RegexOption.IGNORE_CASE), "are", "Agreement"),
            Triple(Regex("\\b([Hh]e|[Ss]he|[Ii]t)\\s+(don't|dont)\\b", RegexOption.IGNORE_CASE), "doesn't", "Agreement"),
            Triple(Regex("\\b(have|has|had)\\s+went\\b", RegexOption.IGNORE_CASE), "gone", "Tense"),
            Triple(Regex("\\b(will|shall|would|could|should|might|may|must|can)\\s+came\\b", RegexOption.IGNORE_CASE), "come", "Tense")
        )
    }

    /**
     * Fast lightweight check for typing suggestions (Keyboard suggestion strip & live checks).
     */
    fun quickCheck(text: String, language: String = "en"): List<NativeCorrectionIssue> {
        if (text.isBlank()) return emptyList()

        val issues = mutableListOf<NativeCorrectionIssue>()
        val customWords = settings.customWords.map { it.lowercase() }.toSet()

        // 1. Check Context Phrases
        for ((regex, fix, reason) in CONTEXT_PHRASES) {
            val matches = regex.findAll(text)
            for (match in matches) {
                val fullMatch = match.value
                val firstWord = fullMatch.split(Regex("\\s+")).first()
                val start = match.range.first
                val end = start + firstWord.length

                val replacement = if (firstWord.first().isUpperCase()) {
                    fix.replaceFirstChar { it.uppercase() }
                } else {
                    fix
                }

                issues.add(
                    NativeCorrectionIssue(
                        id = "ctx_${start}_${end}",
                        start = start,
                        end = end,
                        original = firstWord,
                        suggestions = listOf(replacement),
                        message = "Suggested: $replacement",
                        shortReason = reason,
                        category = if (reason == "Grammar" || reason == "Agreement" || reason == "Tense") "grammar" else "wordChoice",
                        isAutoFixable = true,
                        confidence = "high"
                    )
                )
            }
        }

        // 2. Check Word Typos
        val wordRegex = Regex("\\b[a-zA-Z']+\\b")
        for (match in wordRegex.findAll(text)) {
            val word = match.value
            val lower = word.lowercase()

            // Skip custom dictionary
            if (customWords.contains(lower)) continue

            if (TYPO_MAP.containsKey(lower)) {
                val fix = TYPO_MAP[lower]!!
                val formattedFix = if (word.first().isUpperCase()) {
                    fix.replaceFirstChar { it.uppercase() }
                } else {
                    fix
                }

                val start = match.range.first
                val end = match.range.last + 1

                // Don't duplicate if already covered by context phrase
                if (issues.none { it.start <= start && it.end >= end }) {
                    issues.add(
                        NativeCorrectionIssue(
                            id = "typo_${start}_${end}",
                            start = start,
                            end = end,
                            original = word,
                            suggestions = listOf(formattedFix),
                            message = "Spelling: $formattedFix",
                            shortReason = "Spelling",
                            category = "spelling",
                            isAutoFixable = true,
                            confidence = "high"
                        )
                    )
                }
            }
        }

        return issues.sortedBy { it.start }
    }

    /**
     * Full correction pass (used by ProcessTextActivity and full checks).
     */
    fun correct(text: String, language: String = "en"): NativeCorrectionResult {
        val start = System.currentTimeMillis()
        val issues = quickCheck(text, language)

        var corrected = text
        // Apply issues backwards to preserve string indices
        for (issue in issues.sortedByDescending { it.start }) {
            if (issue.suggestions.isNotEmpty() && issue.start >= 0 && issue.end <= corrected.length) {
                corrected = corrected.substring(0, issue.start) + issue.topSuggestion + corrected.substring(issue.end)
            }
        }

        val elapsed = System.currentTimeMillis() - start
        val engine = if (HarperNative.isAvailable()) "Harper Native" else "Native GrammarCore"

        return NativeCorrectionResult(
            sourceText = text,
            correctedText = corrected,
            issues = issues,
            engineUsed = engine,
            latencyMs = elapsed
        )
    }

    /**
     * Writing Tool commands: Professional, Casual, Concise, Direct, Academic, Fix only.
     */
    fun rewrite(text: String, command: String): String {
        return when (command.lowercase()) {
            "fix_only" -> correct(text).correctedText
            else -> {
                // If model is ready, local model can rewrite
                // Otherwise run standard correction pass
                val result = modelManager.rewrite(text, command)
                result ?: correct(text).correctedText
            }
        }
    }
}
