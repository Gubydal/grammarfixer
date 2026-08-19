import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/correction_repository.dart';
import '../../data/repositories/draft_repository.dart';
import '../../data/repositories/model_pack_repository.dart';
import '../../data/repositories/personal_style_repository.dart';
import '../../domain/entities/correction_issue.dart';
import '../../domain/entities/correction_mode.dart';
import '../../domain/entities/language.dart';
import 'correction_state.dart';

class CorrectionCubit extends Cubit<CorrectionState> {
  CorrectionCubit({
    required CorrectionRepository repository,
    required ModelPackRepository modelPackRepository,
    required DraftRepository draftRepository,
    required PersonalStyleRepository personalStyleRepository,
  })  : _repo = repository,
        _modelPack = modelPackRepository,
        _draftRepo = draftRepository,
        _personalStyle = personalStyleRepository,
        super(const CorrectionInitial()) {
    _loadInitialDraft();
  }

  final CorrectionRepository _repo;
  final ModelPackRepository _modelPack;
  final DraftRepository _draftRepo;
  final PersonalStyleRepository _personalStyle;

  String _currentInputText = '';
  AppLanguage _currentLanguage = AppLanguage.auto;
  CorrectionMode _currentMode = CorrectionMode.correct;

  // Live correction debounce timers
  Timer? _quickCheckTimer;
  Timer? _contextCheckTimer;
  int _liveRevision = 0;

  // Undo support for live auto-fix
  String? _preAutoFixText;

  void _loadInitialDraft() {
    final savedDraft = _draftRepo.getDraft();
    if (savedDraft != null && savedDraft.isNotEmpty) {
      _currentInputText = savedDraft;
      emit(CorrectionEditing(
        text: _currentInputText,
        selectedLanguage: _currentLanguage,
        mode: _currentMode,
      ));
    }
  }

  /// Called by the editor on every text change. Handles live correction scheduling.
  void updateText(String text) {
    _currentInputText = text;
    _draftRepo.saveDraft(text);

    // Cancel stale timers
    _quickCheckTimer?.cancel();
    _contextCheckTimer?.cancel();

    // Preserve current live issues while scheduling new check
    final currentLiveIssues = state is CorrectionEditing
        ? (state as CorrectionEditing).liveIssues
        : <CorrectionIssue>[];
    final currentAutoFix = state is CorrectionEditing
        ? (state as CorrectionEditing).lastAutoFix
        : null;

    emit(CorrectionEditing(
      text: text,
      selectedLanguage: _currentLanguage,
      mode: _currentMode,
      liveIssues: currentLiveIssues,
      lastAutoFix: currentAutoFix,
      isLiveChecking: false,
    ));

    if (text.trim().isEmpty) return;

    // Determine trigger type from the last character
    final lastChar = text.isNotEmpty ? text[text.length - 1] : '';
    final isWordBoundary = lastChar == ' ' || lastChar == '\n' || lastChar == '\t';
    final isSentenceEnd = lastChar == '.' || lastChar == '!' || lastChar == '?' || lastChar == '\n';

    if (isWordBoundary) {
      // Quick check immediately on word boundary (space)
      _scheduleQuickCheck(delay: const Duration(milliseconds: 50));
    }

    if (isSentenceEnd) {
      // Sentence-ending punctuation: run slightly delayed full context check
      _scheduleQuickCheck(delay: const Duration(milliseconds: 100));
    }

    // Always schedule a debounced context check for idle detection (400-600ms)
    _scheduleContextCheck();
  }

  void _scheduleQuickCheck({Duration delay = const Duration(milliseconds: 50)}) {
    _quickCheckTimer?.cancel();
    _quickCheckTimer = Timer(delay, () {
      _runQuickCheck();
    });
  }

  void _scheduleContextCheck() {
    _contextCheckTimer?.cancel();
    _contextCheckTimer = Timer(const Duration(milliseconds: 500), () {
      _runQuickCheck();
    });
  }

  void _runQuickCheck() {
    if (state is! CorrectionEditing) return;
    final text = _currentInputText;
    if (text.trim().isEmpty) return;

    final revision = ++_liveRevision;

    // Emit checking state
    emit(CorrectionEditing(
      text: text,
      selectedLanguage: _currentLanguage,
      mode: _currentMode,
      liveIssues: (state as CorrectionEditing).liveIssues,
      lastAutoFix: (state as CorrectionEditing).lastAutoFix,
      isLiveChecking: true,
    ));

    // Run synchronous quick check
    final issues = _repo.quickCheck(
      text: text,
      selectedLanguage: _currentLanguage,
      mode: _currentMode,
    );

    // Stale check
    if (revision != _liveRevision) return;
    if (state is! CorrectionEditing) return;

    // Auto-fix logic
    if (_personalStyle.isAutoFixEnabled && issues.isNotEmpty) {
      final autoFixable = issues.where((i) =>
          i.confidence == IssueConfidence.high &&
          i.isAutoFixable &&
          _isAutoFixEligible(i),
      ).toList();

      if (autoFixable.isNotEmpty) {
        _applyLiveAutoFix(text, autoFixable.first, issues);
        return;
      }
    }

    emit(CorrectionEditing(
      text: text,
      selectedLanguage: _currentLanguage,
      mode: _currentMode,
      liveIssues: issues,
      lastAutoFix: (state as CorrectionEditing).lastAutoFix,
      isLiveChecking: false,
    ));
  }

  /// Determines if an issue is eligible for automatic live correction.
  bool _isAutoFixEligible(CorrectionIssue issue) {
    // Eligible: objective grammar, spelling, agreement, tense, word choice (high confidence)
    switch (issue.category) {
      case IssueCategory.spelling:
      case IssueCategory.agreement:
      case IssueCategory.tense:
      case IssueCategory.wordBoundary:
      case IssueCategory.punctuation:
        return true;
      case IssueCategory.wordChoice:
      case IssueCategory.grammar:
        // Only auto-fix if high confidence
        return issue.confidence == IssueConfidence.high;
      case IssueCategory.style:
      case IssueCategory.clarity:
      case IssueCategory.capitalization:
      case IssueCategory.other:
        // Not eligible for auto-fix
        return false;
    }
  }

  void _applyLiveAutoFix(String text, CorrectionIssue issue, List<CorrectionIssue> allIssues) {
    if (issue.suggestions.isEmpty) return;
    if (issue.start < 0 || issue.end > text.length) return;

    _preAutoFixText = text;
    final replacement = issue.topSuggestion;
    final fixedText = text.replaceRange(issue.start, issue.end, replacement);

    _currentInputText = fixedText;
    _draftRepo.saveDraft(fixedText);

    // Remove the fixed issue from live issues and mark applied
    final remainingIssues = allIssues.where((i) => i.id != issue.id).toList();

    emit(CorrectionEditing(
      text: fixedText,
      selectedLanguage: _currentLanguage,
      mode: _currentMode,
      liveIssues: remainingIssues,
      lastAutoFix: LiveAutoFix(
        original: issue.original,
        replacement: replacement,
        reason: issue.shortReason ?? issue.category.displayName,
        start: issue.start,
        end: issue.end,
        timestamp: DateTime.now(),
      ),
      isLiveChecking: false,
    ));
  }

  /// Undoes the last live auto-fix.
  void undoLiveAutoFix() {
    if (_preAutoFixText == null) return;
    if (state is! CorrectionEditing) return;

    final restoredText = _preAutoFixText!;
    _preAutoFixText = null;
    _currentInputText = restoredText;
    _draftRepo.saveDraft(restoredText);

    emit(CorrectionEditing(
      text: restoredText,
      selectedLanguage: _currentLanguage,
      mode: _currentMode,
      liveIssues: const [],
      lastAutoFix: null,
      isLiveChecking: false,
    ));

    // Re-run quick check on restored text
    _scheduleQuickCheck(delay: const Duration(milliseconds: 200));
  }

  /// Dismisses the auto-fix explanation bar without undoing.
  void dismissAutoFixExplanation() {
    if (state is! CorrectionEditing) return;
    final s = state as CorrectionEditing;
    emit(CorrectionEditing(
      text: s.text,
      selectedLanguage: s.selectedLanguage,
      mode: s.mode,
      liveIssues: s.liveIssues,
      lastAutoFix: null,
      isLiveChecking: s.isLiveChecking,
    ));
  }

  void setLanguage(AppLanguage language) {
    _currentLanguage = language;
    if (state is CorrectionEditing) {
      emit(CorrectionEditing(
        text: _currentInputText,
        selectedLanguage: _currentLanguage,
        mode: _currentMode,
      ));
    }
  }

  void setMode(CorrectionMode mode) {
    _currentMode = mode;
    if (state is CorrectionEditing) {
      emit(CorrectionEditing(
        text: _currentInputText,
        selectedLanguage: _currentLanguage,
        mode: _currentMode,
      ));
    } else if (state is CorrectionReview) {
      // Re-run correction with new mode
      runCorrection();
    }
  }

  void clearText() {
    _currentInputText = '';
    _quickCheckTimer?.cancel();
    _contextCheckTimer?.cancel();
    _preAutoFixText = null;
    _draftRepo.clearDraft();
    emit(CorrectionEditing(
      text: '',
      selectedLanguage: _currentLanguage,
      mode: _currentMode,
    ));
  }

  void pasteText(String text) {
    if (text.isEmpty) return;
    _currentInputText = text;
    _draftRepo.saveDraft(text);
    emit(CorrectionEditing(
      text: text,
      selectedLanguage: _currentLanguage,
      mode: _currentMode,
    ));
    // Run quick check on pasted text
    _scheduleQuickCheck(delay: const Duration(milliseconds: 200));
  }

  Future<void> runCorrection() async {
    final text = _currentInputText.trim();
    if (text.isEmpty) return;

    // Cancel live check timers — manual correction takes over
    _quickCheckTimer?.cancel();
    _contextCheckTimer?.cancel();

    if (_currentLanguage.requiresPack && !_modelPack.isInstalled) {
      emit(CorrectionLanguagePackRequired(language: _currentLanguage, text: text));
      return;
    }

    emit(CorrectionProcessing(text: text, language: _currentLanguage, mode: _currentMode));

    try {
      final result = await _repo.correct(
        text: text,
        selectedLanguage: _currentLanguage,
        mode: _currentMode,
      );

      if (result.engineName == 'Language Pack Required') {
        emit(CorrectionLanguagePackRequired(
          language: result.language,
          text: text,
        ));
        return;
      }

      var currentWorkingText = text;
      final issues = List<CorrectionIssue>.from(result.issues);

      // Auto-fix obvious mistakes if setting enabled (high confidence only)
      if (_personalStyle.isAutoFixEnabled) {
        final highConfidenceIssues = issues.where((i) => i.confidence == IssueConfidence.high && i.isAutoFixable).toList();
        if (highConfidenceIssues.isNotEmpty) {
          currentWorkingText = _repo.applyFixAll(text, highConfidenceIssues);
          for (int i = 0; i < issues.length; i++) {
            if (issues[i].confidence == IssueConfidence.high && issues[i].isAutoFixable) {
              issues[i] = issues[i].copyWith(isApplied: true, appliedReplacement: issues[i].topSuggestion);
            }
          }
        }
      }

      emit(CorrectionReview(
        sourceText: text,
        currentText: currentWorkingText,
        result: result,
        issues: issues,
        language: result.language,
        mode: _currentMode,
        undoStack: currentWorkingText != text ? [text] : [],
      ));
    } catch (e) {
      emit(CorrectionError(
        message: 'Correction encountered an issue. Your writing was not changed.',
        text: text,
        language: _currentLanguage,
      ));
    }
  }

  void selectIssue(CorrectionIssue? issue) {
    if (state is CorrectionReview) {
      final s = state as CorrectionReview;
      emit(CorrectionReview(
        sourceText: s.sourceText,
        currentText: s.currentText,
        result: s.result,
        issues: s.issues,
        selectedIssue: issue,
        language: s.language,
        mode: s.mode,
        isFixedAll: s.isFixedAll,
        isBeforeAfterVisible: s.isBeforeAfterVisible,
        undoStack: s.undoStack,
      ));
    }
  }

  void toggleBeforeAfter() {
    if (state is CorrectionReview) {
      final s = state as CorrectionReview;
      emit(CorrectionReview(
        sourceText: s.sourceText,
        currentText: s.currentText,
        result: s.result,
        issues: s.issues,
        selectedIssue: s.selectedIssue,
        language: s.language,
        mode: s.mode,
        isFixedAll: s.isFixedAll,
        isBeforeAfterVisible: !s.isBeforeAfterVisible,
        undoStack: s.undoStack,
      ));
    }
  }

  void applySuggestion(CorrectionIssue issue, String replacement) {
    if (state is CorrectionReview) {
      final s = state as CorrectionReview;
      final updatedIssues = s.issues.map((i) {
        if (i.id == issue.id) {
          return i.copyWith(isApplied: true, appliedReplacement: replacement);
        }
        return i;
      }).toList();

      final newText = _repo.applySingleSuggestion(s.currentText, issue, replacement);

      // Record style learning decision
      if (issue.category == IssueCategory.style) {
        _personalStyle.recordStyleDecision(
          original: issue.original,
          suggestion: replacement,
          isAccepted: true,
        );
      }

      emit(CorrectionReview(
        sourceText: s.sourceText,
        currentText: newText,
        result: s.result,
        issues: updatedIssues,
        selectedIssue: null,
        language: s.language,
        mode: s.mode,
        isBeforeAfterVisible: s.isBeforeAfterVisible,
        undoStack: [...s.undoStack, s.currentText],
      ));
    }
  }

  void ignoreSuggestion(CorrectionIssue issue) {
    if (state is CorrectionReview) {
      final s = state as CorrectionReview;
      final updatedIssues = s.issues.map((i) {
        if (i.id == issue.id) {
          return i.copyWith(isIgnored: true);
        }
        return i;
      }).toList();

      // Record style rejection
      if (issue.category == IssueCategory.style && issue.suggestions.isNotEmpty) {
        _personalStyle.recordStyleDecision(
          original: issue.original,
          suggestion: issue.suggestions.first,
          isAccepted: false,
        );
      }

      emit(CorrectionReview(
        sourceText: s.sourceText,
        currentText: s.currentText,
        result: s.result,
        issues: updatedIssues,
        selectedIssue: null,
        language: s.language,
        mode: s.mode,
        isBeforeAfterVisible: s.isBeforeAfterVisible,
        undoStack: s.undoStack,
      ));
    }
  }

  void undo() {
    if (state is CorrectionReview) {
      final s = state as CorrectionReview;
      if (s.undoStack.isEmpty) return;

      final previousText = s.undoStack.last;
      final newUndoStack = List<String>.from(s.undoStack)..removeLast();

      emit(CorrectionReview(
        sourceText: s.sourceText,
        currentText: previousText,
        result: s.result,
        issues: s.issues.map((i) => i.copyWith(isApplied: false, isIgnored: false)).toList(),
        selectedIssue: null,
        language: s.language,
        mode: s.mode,
        isFixedAll: false,
        isBeforeAfterVisible: s.isBeforeAfterVisible,
        undoStack: newUndoStack,
      ));
    }
  }

  Future<void> addWordToDictionary(String word) async {
    await _repo.addUserWord(word);
    if (state is CorrectionReview) {
      final s = state as CorrectionReview;
      final updatedIssues = s.issues.where((i) => i.original.toLowerCase() != word.toLowerCase()).toList();
      emit(CorrectionReview(
        sourceText: s.sourceText,
        currentText: s.currentText,
        result: s.result,
        issues: updatedIssues,
        selectedIssue: null,
        language: s.language,
        mode: s.mode,
        isBeforeAfterVisible: s.isBeforeAfterVisible,
        undoStack: s.undoStack,
      ));
    }
  }

  void applyFixAll() {
    if (state is CorrectionReview) {
      final s = state as CorrectionReview;
      // In correct mode, apply only objective/correctness issues
      final fixableIssues = s.mode == CorrectionMode.correct
          ? s.issues.where((i) => i.category != IssueCategory.style).toList()
          : s.issues;

      final fixedText = _repo.applyFixAll(s.sourceText, fixableIssues);
      final allAppliedIssues = s.issues.map((i) {
        if (!i.isIgnored && (s.mode == CorrectionMode.improve || i.category != IssueCategory.style)) {
          return i.copyWith(isApplied: true, appliedReplacement: i.topSuggestion);
        }
        return i;
      }).toList();

      emit(CorrectionReview(
        sourceText: s.sourceText,
        currentText: fixedText,
        result: s.result,
        issues: allAppliedIssues,
        selectedIssue: null,
        language: s.language,
        mode: s.mode,
        isFixedAll: true,
        isBeforeAfterVisible: s.isBeforeAfterVisible,
        undoStack: [...s.undoStack, s.currentText],
      ));
    }
  }

  void backToEdit() {
    if (state is CorrectionReview) {
      final s = state as CorrectionReview;
      _currentInputText = s.currentText;
      _draftRepo.saveDraft(_currentInputText);
      emit(CorrectionEditing(
        text: _currentInputText,
        selectedLanguage: _currentLanguage,
        mode: _currentMode,
      ));
    } else {
      emit(CorrectionEditing(
        text: _currentInputText,
        selectedLanguage: _currentLanguage,
        mode: _currentMode,
      ));
    }
  }

  @override
  Future<void> close() {
    _quickCheckTimer?.cancel();
    _contextCheckTimer?.cancel();
    return super.close();
  }
}
