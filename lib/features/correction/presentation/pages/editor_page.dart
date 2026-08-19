import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/components/app_button.dart';
import '../../data/repositories/model_pack_repository.dart';
import '../../data/repositories/personal_style_repository.dart';
import '../../domain/entities/correction_mode.dart';
import '../../domain/entities/writing_style_profile.dart';
import '../cubits/correction_cubit.dart';
import '../cubits/correction_state.dart';
import '../cubits/model_pack_cubit.dart';
import '../widgets/language_selector_sheet.dart';
import '../widgets/model_pack_download_sheet.dart';
import '../widgets/rewrite_cards_view.dart';
import '../widgets/writing_style_sheet.dart';
import 'review_mode_view.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _suppressTextChangeCallback = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_suppressTextChangeCallback) return;
    final cubit = context.read<CorrectionCubit>();
    if (cubit.state is! CorrectionReview && cubit.state is! CorrectionProcessing) {
      cubit.updateText(_textController.text);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getStyleSummary(WritingStyleProfile profile) {
    final formalityName = switch (profile.formalityPreference) {
      FormalityStyle.formal => 'Professional',
      FormalityStyle.casual => 'Casual',
      FormalityStyle.neutral => 'Natural',
    };
    return '$formalityName (${profile.dialect.displayName.split(' ').first})';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<CorrectionCubit, CorrectionState>(
      listener: (context, state) {
        if (state is CorrectionEditing && state.text != _textController.text) {
          // Suppress callback to avoid re-triggering updateText
          _suppressTextChangeCallback = true;
          _textController.value = TextEditingValue(
            text: state.text,
            selection: TextSelection.collapsed(offset: state.text.length),
          );
          _suppressTextChangeCallback = false;
        } else if (state is CorrectionLanguagePackRequired) {
          ModelPackDownloadSheet.show(context);
        }
      },
      builder: (context, state) {
        if (state is CorrectionReview) {
          return ReviewModeView(state: state);
        }

        final isProcessing = state is CorrectionProcessing;
        final currentText = _textController.text;
        final isEditingState = state is CorrectionEditing;
        final selectedLanguage = isEditingState ? state.selectedLanguage : null;
        final currentMode = isEditingState ? state.mode : CorrectionMode.correct;
        final isRtl = isEditingState ? state.isRtl : false;
        final liveIssues = isEditingState ? state.liveIssues : [];
        final rewriteOptions = isEditingState ? state.rewriteOptions : [];
        final lastAutoFix = isEditingState ? state.lastAutoFix : null;
        final isLiveChecking = isEditingState ? state.isLiveChecking : false;

        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        final surfaceSoft = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSoft;

        final personalStyleRepo = context.read<PersonalStyleRepository>();
        final styleProfile = personalStyleRepo.profile;

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              titleSpacing: 12,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Center(
                      child: AppIcon(
                        AppIcons.edit,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GrammarFix',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceGreen : AppColors.lightSurfaceStrong,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(AppIcons.lock, size: 10, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          'On-device',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                BlocBuilder<ModelPackCubit, ModelPackState>(
                  builder: (context, packState) {
                    return TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const AppIcon(AppIcons.more, size: 14),
                      label: Text(
                        selectedLanguage?.displayName ?? 'Auto',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      onPressed: () async {
                        final chosen = await LanguageSelectorSheet.show(
                          context,
                          currentLanguage: selectedLanguage ?? (state as dynamic).selectedLanguage,
                          isPackInstalled: packState.isInstalled,
                        );
                        if (chosen != null && context.mounted) {
                          context.read<CorrectionCubit>().setLanguage(chosen);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Clean Segmented Toolbar (0% overflow guaranteed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Row(
                      children: [
                        // Mode Switcher (Correct vs Improve)
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildModeButton(
                                label: 'Correct',
                                isSelected: currentMode == CorrectionMode.correct,
                                isDark: isDark,
                                onTap: () => context.read<CorrectionCubit>().setMode(CorrectionMode.correct),
                              ),
                              _buildModeButton(
                                label: 'Improve',
                                isSelected: currentMode == CorrectionMode.improve,
                                isDark: isDark,
                                onTap: () => context.read<CorrectionCubit>().setMode(CorrectionMode.improve),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Compact Style Button (Wrapped in Flexible to prevent overflow)
                        Flexible(
                          child: GestureDetector(
                            onTap: () async {
                              await WritingStyleSheet.show(context, personalStyleRepo: personalStyleRepo);
                              if (context.mounted) {
                                setState(() {});
                                context.read<CorrectionCubit>().updateText(_textController.text);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceGreen : AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _getStyleSummary(styleProfile),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.tune,
                                    size: 13,
                                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Tone Bar (Shown in Improve mode for 1-tap style switching)
                  if (currentMode == CorrectionMode.improve)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Tone:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildQuickToneChip(
                              label: '👔 Professional',
                              isSelected: styleProfile.formalityPreference == FormalityStyle.formal,
                              isDark: isDark,
                              onTap: () async {
                                await personalStyleRepo.updateFormality(FormalityStyle.formal);
                                setState(() {});
                                if (context.mounted) {
                                  context.read<CorrectionCubit>().updateText(_textController.text);
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildQuickToneChip(
                              label: '🌿 Natural',
                              isSelected: styleProfile.formalityPreference == FormalityStyle.neutral,
                              isDark: isDark,
                              onTap: () async {
                                await personalStyleRepo.updateFormality(FormalityStyle.neutral);
                                setState(() {});
                                if (context.mounted) {
                                  context.read<CorrectionCubit>().updateText(_textController.text);
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildQuickToneChip(
                              label: '😊 Casual',
                              isSelected: styleProfile.formalityPreference == FormalityStyle.casual,
                              isDark: isDark,
                              onTap: () async {
                                await personalStyleRepo.updateFormality(FormalityStyle.casual);
                                setState(() {});
                                if (context.mounted) {
                                  context.read<CorrectionCubit>().updateText(_textController.text);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Column(
                        children: [
                          Container(
                            height: 220,
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Text input area
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    focusNode: _focusNode,
                                    maxLines: null,
                                    expands: true,
                                    textAlignVertical: TextAlignVertical.top,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: textPrimary,
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: currentMode == CorrectionMode.correct
                                          ? 'Paste or type text to fix grammar, typos, and punctuation…'
                                          : 'Paste or type text to polish phrasing and enhance style…',
                                      hintStyle: TextStyle(
                                        color: textSecondary.withValues(alpha: 0.6),
                                        fontSize: 15,
                                      ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                                // Live issue indicator strip (shown when there are unfixed live issues)
                                if (liveIssues.isNotEmpty && lastAutoFix == null)
                                  _buildLiveIssueStrip(liveIssues, isDark, textPrimary),
                                // Quick Action Toolbar
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: surfaceSoft,
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                                  ),
                                  child: Row(
                                    children: [
                                      // Smart Paste Button
                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () async {
                                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                                          if (data?.text != null && context.mounted) {
                                            context.read<CorrectionCubit>().pasteText(data!.text!);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          child: Row(
                                            children: [
                                              const AppIcon(AppIcons.copy, size: 16),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Paste',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (currentText.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () => context.read<CorrectionCubit>().clearText(),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            child: Row(
                                              children: [
                                                const AppIcon(AppIcons.trash, size: 16),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Clear',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      // Live checking indicator
                                      if (isLiveChecking)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        '${currentText.length} chars · ${currentText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Multi-Option Rewrite Cards in Improve Mode
                          if (currentMode == CorrectionMode.improve && rewriteOptions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            RewriteCardsView(
                              options: rewriteOptions.cast(),
                              onApply: (opt) {
                                context.read<CorrectionCubit>().applyRewriteOption(opt);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Auto-Fix Explanation Bar (shown after auto-fix is applied)
                  if (lastAutoFix != null)
                    _buildAutoFixBar(lastAutoFix, isDark),
                  if (state is CorrectionError) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.issueCoralBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.issueCoralBorder),
                        ),
                        child: Row(
                          children: [
                            const AppIcon(AppIcons.warning, size: 18, color: AppColors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.message,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Bottom CTA
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: AppButton(
                      label: isProcessing
                          ? 'Analyzing writing…'
                          : (currentMode == CorrectionMode.correct ? 'Correct' : 'Improve writing'),
                      icon: isProcessing ? null : AppIcons.tickCircle,
                      isLoading: isProcessing,
                      onPressed: currentText.trim().isEmpty || isProcessing
                          ? null
                          : () {
                              _focusNode.unfocus();
                              context.read<CorrectionCubit>().runCorrection();
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickToneChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  /// Compact live issue indicator strip (not full review mode).
  Widget _buildLiveIssueStrip(List liveIssues, bool isDark, Color textPrimary) {
    final issueCount = liveIssues.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceGreen.withValues(alpha: 0.5)
            : AppColors.primarySoft.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$issueCount ${issueCount == 1 ? 'issue' : 'issues'} found',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
          ),
          const Spacer(),
          Text(
            'Tap Correct to review',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Auto-fix explanation bar: "went → gone | Verb tense | Undo"
  Widget _buildAutoFixBar(LiveAutoFix autoFix, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceGreen : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const AppIcon(AppIcons.tickCircle, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: autoFix.original,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: ' → '),
                    TextSpan(
                      text: autoFix.replacement,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: '  ·  ${autoFix.reason}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.read<CorrectionCubit>().undoLiveAutoFix(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Undo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => context.read<CorrectionCubit>().dismissAutoFixExplanation(),
              child: Icon(
                Icons.close,
                size: 16,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
