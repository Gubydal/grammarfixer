import 'package:flutter/material.dart';

import '../app_icons.dart';
import '../app_spacing.dart';
import 'app_button.dart';

/// Generic plan summary card (Free / Pro) used on Profile and Home.
class AppPlanCard extends StatelessWidget {
  const AppPlanCard({
    super.key,
    required this.isPro,
    required this.title,
    this.subtitle,
    this.onUpgrade,
    this.upgradeLabel,
  });

  final bool isPro;
  final String title;
  final String? subtitle;
  final VoidCallback? onUpgrade;
  final String? upgradeLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(
                  isPro ? AppIcons.crown : AppIcons.rocket,
                  size: 22,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle!),
            ],
            if (!isPro && onUpgrade != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: upgradeLabel ?? 'Upgrade',
                leading: const AppIcon(AppIcons.crown, size: 20),
                onPressed: onUpgrade,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
