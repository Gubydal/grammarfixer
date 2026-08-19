import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/components/app_button.dart';
import '../../data/repositories/model_pack_repository.dart';
import '../../data/repositories/personal_style_repository.dart';
import '../../domain/entities/correction_mode.dart';
import '../cubits/correction_cubit.dart';
import '../cubits/correction_state.dart';
import '../cubits/model_pack_cubit.dart';
import '../widgets/language_selector_sheet.dart';
import '../widgets/model_pack_download_sheet.dart';
import 'review_mode_view.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<CorrectionCubit, CorrectionState>(
      listener: (context, state) {
        if (state is CorrectionEditing && state.text != _textController.text) {
          _textController.value = TextEditingValue(
            text: state.text,
            selection: TextSelection.collapsed(offset: state.text.length),
          );
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

        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        final surfaceSoft = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSoft;

        final personalStyleRepo = context.read<PersonalStyleRepository>();
        final currentDialect = personalStyleRepo.profile.dialect;

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: AppIcon(
                        AppIcons.edit,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GrammarFix',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceGreen : AppColors.lightSurfaceStrong,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(AppIcons.lock, size: 11, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'On-device',
                          style: TextStyle(
                            fontSize: 10,
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
                      icon: const AppIcon(AppIcons.more, size: 16),
                      label: Text(
                        selectedLanguage?.displayName ?? 'Auto',
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                const SizedBox(width: 8),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Mode Selector Header & Personal Style Indicator
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
                        // Personal Style Indicator Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceGreen : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Using ${currentDialect.displayName}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Container(
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
                    ),
                  ),
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
                          ? 'Correcting on your phone…'
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
