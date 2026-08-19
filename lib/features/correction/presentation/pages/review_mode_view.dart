import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/components/app_button.dart';
import '../../domain/entities/correction_issue.dart';
import '../cubits/correction_cubit.dart';
import '../cubits/correction_state.dart';
import '../widgets/suggestion_bottom_sheet.dart';

class ReviewModeView extends StatelessWidget {
  const ReviewModeView({
    super.key,
    required this.state,
  });

  final CorrectionReview state;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<CorrectionCubit>();

    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final activeCount = state.activeIssueCount;

    return Directionality(
      textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const AppIcon(AppIcons.arrowLeft, size: 22),
            onPressed: () => cubit.backToEdit(),
          ),
          title: Text(
            activeCount > 0 ? '$activeCount issue${activeCount == 1 ? '' : 's'} found' : 'All clear',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            // Before / After Toggle
            IconButton(
              tooltip: 'Compare before & after',
              icon: Icon(
                state.isBeforeAfterVisible ? Icons.visibility_off_outlined : Icons.compare_arrows_rounded,
                size: 22,
                color: state.isBeforeAfterVisible ? AppColors.primary : null,
              ),
              onPressed: () => cubit.toggleBeforeAfter(),
            ),
            if (state.canUndo)
              IconButton(
                tooltip: 'Undo last change',
                icon: const Icon(Icons.undo_rounded, size: 22),
                onPressed: () => cubit.undo(),
              ),
            TextButton.icon(
              icon: const AppIcon(AppIcons.edit, size: 16),
              label: const Text('Edit'),
              onPressed: () => cubit.backToEdit(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Summary Breakdown Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                color: isDark ? AppColors.darkSurfaceGreen : AppColors.primarySoft,
                child: Row(
                  children: [
                    const AppIcon(AppIcons.tickCircle, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.summaryDescription,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.isBeforeAfterVisible) ...[
                        // Before / After Split View
                        _buildSectionHeader('Original text', textSecondary),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Text(
                            state.sourceText,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Corrected text', isDark ? AppColors.darkPrimary : AppColors.primary),
                        const SizedBox(height: 6),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: _buildRichReviewText(context),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomActionCard(context, cubit, isDark, textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRichReviewText(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final spans = <InlineSpan>[];
    final text = state.currentText;
    final issues = List<CorrectionIssue>.from(state.issues)
      ..sort((a, b) => a.start.compareTo(b.start));

    var lastIndex = 0;

    for (final issue in issues) {
      if (issue.start < 0 || issue.end > text.length || issue.start < lastIndex) {
        continue;
      }

      // Normal text prior to issue
      if (issue.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, issue.start)));
      }

      final issueSubstring = text.substring(issue.start, issue.end);

      Color highlightBg;
      Color highlightBorder;
      TextDecoration decoration = TextDecoration.underline;

      if (issue.isApplied) {
        highlightBg = AppColors.fixedGreenBg;
        highlightBorder = AppColors.fixedGreenBorder;
        decoration = TextDecoration.none;
      } else if (issue.isIgnored) {
        highlightBg = AppColors.ignoredBg;
        highlightBorder = AppColors.ignoredBorder;
        decoration = TextDecoration.none;
      } else {
        if (issue.category == IssueCategory.spelling || issue.category == IssueCategory.wordBoundary) {
          highlightBg = AppColors.issueCoralBg;
          highlightBorder = AppColors.issueCoralBorder;
        } else if (issue.category == IssueCategory.style) {
          highlightBg = isDark ? AppColors.darkSurfaceGreen : AppColors.primarySoft;
          highlightBorder = AppColors.primary;
        } else {
          highlightBg = AppColors.issueAmberBg;
          highlightBorder = AppColors.issueAmberBorder;
        }
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () {
              SuggestionBottomSheet.show(
                context,
                issue: issue,
                onApply: (repl) => context.read<CorrectionCubit>().applySuggestion(issue, repl),
                onIgnore: () => context.read<CorrectionCubit>().ignoreSuggestion(issue),
                onAddToDictionary: (word) => context.read<CorrectionCubit>().addWordToDictionary(word),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: highlightBg,
                borderRadius: BorderRadius.circular(4),
                border: Border(
                  bottom: BorderSide(
                    color: highlightBorder,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                issueSubstring.isNotEmpty ? issueSubstring : (issue.appliedReplacement ?? ' '),
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  decoration: decoration,
                  decorationColor: highlightBorder,
                ),
              ),
            ),
          ),
        ),
      );

      lastIndex = issue.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return SelectableText.rich(
      TextSpan(
        style: theme.textTheme.bodyLarge?.copyWith(
          color: textPrimary,
          fontSize: 16,
          height: 1.6,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildBottomActionCard(
    BuildContext context,
    CorrectionCubit cubit,
    bool isDark,
    Color textSecondary,
  ) {
    final activeCount = state.activeIssueCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        border: Border(
          top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeCount > 0) ...[
            AppButton(
              label: 'Fix all ($activeCount issue${activeCount == 1 ? '' : 's'})',
              icon: AppIcons.checkAll,
              onPressed: () => cubit.applyFixAll(),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const AppIcon(AppIcons.copy, size: 18),
                  label: const Text('Copy'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: state.currentText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const AppIcon(AppIcons.share, size: 18),
                  label: const Text('Share'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: state.currentText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Text ready to share (copied to clipboard)'),
                        duration: Duration(seconds: 2),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
