package com.mogate.grammarfix

import android.service.textservice.SpellCheckerService
import android.view.textservice.SentenceSuggestionsInfo
import android.view.textservice.SuggestionsInfo
import android.view.textservice.TextInfo

/**
 * System-wide Spell and Grammar Checker Service using shared GrammarCore.
 * Computes granular sentence offsets for system-wide red/blue underline suggestions.
 */
class GrammarSpellCheckerService : SpellCheckerService() {

    private lateinit var grammarCore: GrammarCore

    override fun onCreate() {
        super.onCreate()
        grammarCore = GrammarCore.getInstance(this)
    }

    override fun createSession(): Session {
        return GrammarSpellCheckerSession(grammarCore)
    }

    private class GrammarSpellCheckerSession(private val core: GrammarCore) : Session() {

        override fun onCreate() {}

        override fun onGetSuggestions(textInfo: TextInfo?, suggestionsLimit: Int): SuggestionsInfo {
            if (textInfo == null || textInfo.text.isNullOrBlank()) {
                return SuggestionsInfo(SuggestionsInfo.RESULT_ATTR_IN_THE_DICTIONARY, emptyArray())
            }

            val issues = core.quickCheck(textInfo.text)
            if (issues.isNotEmpty()) {
                val suggestions = issues.first().suggestions.take(suggestionsLimit).toTypedArray()
                return SuggestionsInfo(
                    SuggestionsInfo.RESULT_ATTR_LOOKS_LIKE_TYPO or SuggestionsInfo.RESULT_ATTR_HAS_RECOMMENDED_SUGGESTIONS,
                    suggestions
                )
            }

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
                val text = textInfo.text ?: ""
                val issues = core.quickCheck(text)

                if (issues.isEmpty()) {
                    val info = SuggestionsInfo(SuggestionsInfo.RESULT_ATTR_IN_THE_DICTIONARY, emptyArray())
                    results.add(
                        SentenceSuggestionsInfo(
                            arrayOf(info),
                            intArrayOf(0),
                            intArrayOf(text.length)
                        )
                    )
                } else {
                    val suggestionsInfos = mutableListOf<SuggestionsInfo>()
                    val offsets = mutableListOf<Int>()
                    val lengths = mutableListOf<Int>()

                    for (issue in issues) {
                        val suggestions = issue.suggestions.take(suggestionsLimit).toTypedArray()
                        val info = SuggestionsInfo(
                            SuggestionsInfo.RESULT_ATTR_LOOKS_LIKE_TYPO or SuggestionsInfo.RESULT_ATTR_HAS_RECOMMENDED_SUGGESTIONS,
                            suggestions
                        )
                        suggestionsInfos.add(info)
                        offsets.add(issue.start)
                        lengths.add(issue.end - issue.start)
                    }

                    results.add(
                        SentenceSuggestionsInfo(
                            suggestionsInfos.toTypedArray(),
                            offsets.toIntArray(),
                            lengths.toIntArray()
                        )
                    )
                }
            }
            return results.toTypedArray()
        }
    }
}
