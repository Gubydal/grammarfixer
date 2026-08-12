import 'package:flutter/material.dart';

import '../app_icons.dart';

/// Standard settings/profile list row using the shared icon system.
class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.showChevron = true,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppIcon(
        icon,
        size: 22,
        color: destructive ? scheme.error : scheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: destructive ? TextStyle(color: scheme.error) : null,
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
      trailing: showChevron
          ? const AppIcon(AppIcons.arrowRight, size: 18)
          : null,
      onTap: onTap,
    );
  }
}
