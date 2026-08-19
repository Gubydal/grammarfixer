package com.mogate.grammarfix

import android.service.textservice.SpellCheckerService
import android.view.textservice.SentenceSuggestionsInfo
import android.view.textservice.SuggestionsInfo
import android.view.textservice.TextInfo

/**
 * System-wide Spell and Grammar Checker Service using GrammarFix on-device rules.
 * Does NOT use AccessibilityService and never transmits user text to remote servers.
 */
class GrammarSpellCheckerService : SpellCheckerService() {

    override fun createSession(): Session {
        return GrammarSpellCheckerSession()
    }

    private class GrammarSpellCheckerSession : Session() {
        // High-frequency typos and corrections map
        private val quickTypos = mapOf(
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
            "occured" to "occurred",
            "untill" to "until",
            "truely" to "truly",
            "definately" to "definitely",
            "cant" to "can't",
            "dont" to "don't",
            "wont" to "won't",
            "theyre" to "they're",
            "youre" to "you're",
            "alot" to "a lot"
        )

        override fun onCreate() {
            // Local on-device initialization
        }

        override fun onGetSuggestions(textInfo: TextInfo?, suggestionsLimit: Int): SuggestionsInfo {
            if (textInfo == null) {
                return SuggestionsInfo(SuggestionsInfo.RESULT_ATTR_LOOKS_LIKE_TYPO, emptyArray())
            }

            val text = textInfo.text
            val lower = text.lowercase()

            if (quickTypos.containsKey(lower)) {
                val fix = quickTypos[lower]!!
                val formattedFix = if (text.isNotEmpty() && text[0].isUpperCase()) {
                    fix.replaceFirstChar { it.uppercase() }
                } else {
                    fix
                }
                return SuggestionsInfo(
                    SuggestionsInfo.RESULT_ATTR_LOOKS_LIKE_TYPO,
                    arrayOf(formattedFix)
                )
            }

            // Looks valid or no suggestion
            return SuggestionsInfo(SuggestionsInfo.RESULT_ATTR_IN_THE_DICTIONARY, emptyArray())
        }

        override fun onGetSentenceSuggestionsMultiple(
            textInfos: Array<out TextInfo>?,
            suggestionsLimit: Int
        ): Array<SentenceSuggestionsInfo> {
            if (textInfos == null || textInfos.isEmpty()) {
                return emptyArray()
            }

            val results = ArrayList<SentenceSuggestionsInfo>()
            for (textInfo in textInfos) {
                val suggestions = onGetSuggestions(textInfo, suggestionsLimit)
                val lengths = intArrayOf(textInfo.text.length)
                val offsets = intArrayOf(0)
                results.add(SentenceSuggestionsInfo(arrayOf(suggestions), offsets, lengths))
            }
            return results.toTypedArray()
        }
    }
}
