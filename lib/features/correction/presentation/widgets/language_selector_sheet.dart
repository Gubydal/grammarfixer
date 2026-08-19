import 'package:flutter/material.dart';

import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../domain/entities/language.dart';

class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageSelected,
    required this.isPackInstalled,
  });

  final AppLanguage selectedLanguage;
  final ValueChanged<AppLanguage> onLanguageSelected;
  final bool isPackInstalled;

  static Future<AppLanguage?> show(
    BuildContext context, {
    required AppLanguage currentLanguage,
    required bool isPackInstalled,
  }) {
    return showModalBottomSheet<AppLanguage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageSelectorSheet(
        selectedLanguage: currentLanguage,
        isPackInstalled: isPackInstalled,
        onLanguageSelected: (lang) => Navigator.of(context).pop(lang),
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

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                Text(
                  'Select Language',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const AppIcon(AppIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: AppLanguage.values.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final lang = AppLanguage.values[index];
                  final isSelected = lang == selectedLanguage;
                  final needsPack = lang.requiresPack && !isPackInstalled;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft)
                            : (isDark ? AppColors.darkSurfaceGreen : AppColors.lightSurfaceSoft),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        lang.code.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                              : textSecondary,
                        ),
                      ),
                    ),
                    title: Text(
                      lang.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                            : textPrimary,
                      ),
                    ),
                    subtitle: needsPack
                        ? Row(
                            children: [
                              const AppIcon(AppIcons.download, size: 12, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                'Requires offline pack',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        : null,
                    trailing: isSelected
                        ? const AppIcon(AppIcons.tickCircle, size: 22, color: AppColors.primary)
                        : null,
                    onTap: () => onLanguageSelected(lang),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
