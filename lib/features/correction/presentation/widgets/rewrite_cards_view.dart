import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../domain/services/sentence_rewrite_engine.dart';

class RewriteCardsView extends StatelessWidget {
  const RewriteCardsView({
    super.key,
    required this.options,
    required this.onApply,
  });

  final List<RewriteOption> options;
  final ValueChanged<RewriteOption> onApply;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const AppIcon(AppIcons.edit, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Rewrite Alternatives',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '1-tap to replace',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...options.map((opt) => _buildRewriteCard(context, opt, isDark, textPrimary, textSecondary)),
      ],
    );
  }

  Widget _buildRewriteCard(
    BuildContext context,
    RewriteOption opt,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final surfaceColor = isDark ? AppColors.darkSurfaceElevated : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceGreen.withValues(alpha: 0.3) : AppColors.primarySoft.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Text(opt.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  opt.toneLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    opt.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Rewritten Text Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: SelectableText(
              opt.rewrittenText,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Card Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Copy button
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const AppIcon(AppIcons.copy, size: 14),
                  label: const Text('Copy', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: opt.rewrittenText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${opt.toneLabel} rewrite copied to clipboard'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Apply button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check, size: 14, color: Colors.white),
                  label: const Text(
                    'Apply',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  onPressed: () => onApply(opt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
