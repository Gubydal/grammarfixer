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

  void updateText(String text) {
    _currentInputText = text;
    _draftRepo.saveDraft(text);
    emit(CorrectionEditing(
      text: text,
      selectedLanguage: _currentLanguage,
      mode: _currentMode,
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
  }

  Future<void> runCorrection() async {
    final text = _currentInputText.trim();
    if (text.isEmpty) return;

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
}
