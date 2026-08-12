import 'package:flutter/material.dart';

import '../app_spacing.dart';

enum AppButtonVariant { filled, outlined, tonal }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.loading = false,
    this.expanded = true,
    this.variant = AppButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final bool loading;
  final bool expanded;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final Widget button = switch (variant) {
      AppButtonVariant.filled => FilledButton(
        onPressed: loading ? null : onPressed,
        child: _content(context),
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: loading ? null : onPressed,
        child: _content(context),
      ),
      AppButtonVariant.tonal => FilledButton.tonal(
        onPressed: loading ? null : onPressed,
        child: _content(context),
      ),
    };

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _content(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ?leading,
        if (leading == null && icon != null) Icon(icon, size: 20),
        if (leading != null || icon != null)
          const SizedBox(width: AppSpacing.sm),
        Text(label),
      ],
    );
  }
}
