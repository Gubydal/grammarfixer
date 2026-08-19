import 'package:flutter/material.dart';

import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/components/app_button.dart';
import '../../domain/entities/correction_issue.dart';

class SuggestionBottomSheet extends StatelessWidget {
  const SuggestionBottomSheet({
    super.key,
    required this.issue,
    required this.onApply,
    required this.onIgnore,
    required this.onAddToDictionary,
  });

  final CorrectionIssue issue;
  final ValueChanged<String> onApply;
  final VoidCallback onIgnore;
  final ValueChanged<String> onAddToDictionary;

  static Future<void> show(
    BuildContext context, {
    required CorrectionIssue issue,
    required ValueChanged<String> onApply,
    required VoidCallback onIgnore,
    required ValueChanged<String> onAddToDictionary,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SuggestionBottomSheet(
        issue: issue,
        onApply: (replacement) {
          Navigator.of(context).pop();
          onApply(replacement);
        },
        onIgnore: () {
          Navigator.of(context).pop();
          onIgnore();
        },
        onAddToDictionary: (word) {
          Navigator.of(context).pop();
          onAddToDictionary(word);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isSpelling = issue.category == IssueCategory.spelling || issue.category == IssueCategory.wordBoundary;
    final topSuggestion = issue.topSuggestion;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    issue.category.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceGreen : AppColors.lightSurfaceSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    issue.confidence == IssueConfidence.high
                        ? 'High confidence'
                        : (issue.confidence == IssueConfidence.medium ? 'Review' : 'Style suggestion'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: issue.confidence == IssueConfidence.high
                          ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                          : textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const AppIcon(AppIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (issue.original.isNotEmpty && topSuggestion.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceGreen : AppColors.lightSurfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      issue.original,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.issueCoralBorder,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      topSuggestion,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              issue.shortReason ?? issue.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (topSuggestion.isNotEmpty) ...[
              AppButton(
                label: 'Apply "$topSuggestion"',
                icon: AppIcons.tick,
                onPressed: () => onApply(topSuggestion),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const AppIcon(AppIcons.x, size: 18),
                    label: const Text('Ignore'),
                    onPressed: onIgnore,
                  ),
                ),
                if (isSpelling && issue.original.trim().isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const AppIcon(AppIcons.bookmark, size: 18),
                      label: const Text('Add word'),
                      onPressed: () => onAddToDictionary(issue.original.trim()),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
