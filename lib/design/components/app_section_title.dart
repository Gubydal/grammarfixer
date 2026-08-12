import 'package:flutter/material.dart';

import '../app_spacing.dart';

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.title, {super.key, this.trailing, this.icon});

  final String title;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
