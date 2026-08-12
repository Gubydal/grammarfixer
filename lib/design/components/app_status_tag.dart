import 'package:flutter/material.dart';

import '../app_colors.dart';

enum AppStatus { done, inProgress, todo, locked }

class AppStatusTag extends StatelessWidget {
  const AppStatusTag({super.key, required this.status, required this.label});

  final AppStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      AppStatus.done => (AppColors.primaryContainer, AppColors.primaryDark),
      AppStatus.inProgress => (
        const Color(0xFFFFE9E1),
        AppColors.warning,
      ),
      AppStatus.todo => (
        const Color(0xFFE3F2FF),
        AppColors.info,
      ),
      AppStatus.locked => (
        Theme.of(context).colorScheme.surfaceContainerHighest,
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
