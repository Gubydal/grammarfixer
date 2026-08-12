import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/app_spacing.dart';
import '../../../../design/components/app_button.dart';

class ProStatusCard extends StatelessWidget {
  const ProStatusCard({
    super.key,
    required this.isPro,
    this.onUpgrade,
  });

  final bool isPro;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                Text(
                  isPro ? l10n.youArePro : l10n.goPro,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isPro ? l10n.proCardProMessage : l10n.proCardFreeMessage,
            ),
            if (!isPro) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.upgrade,
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
