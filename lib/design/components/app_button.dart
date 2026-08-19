import 'package:flutter/material.dart';

import '../app_icons.dart';
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
    this.isLoading,
    this.expanded = true,
    this.variant = AppButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final dynamic icon; // String (AppIcons SVG name) or IconData
  final Widget? leading;
  final bool loading;
  final bool? isLoading;
  final bool expanded;
  final AppButtonVariant variant;

  bool get _effectiveLoading => isLoading ?? loading;

  @override
  Widget build(BuildContext context) {
    final Widget button = switch (variant) {
      AppButtonVariant.filled => FilledButton(
        onPressed: _effectiveLoading ? null : onPressed,
        child: _content(context),
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: _effectiveLoading ? null : onPressed,
        child: _content(context),
      ),
      AppButtonVariant.tonal => FilledButton.tonal(
        onPressed: _effectiveLoading ? null : onPressed,
        child: _content(context),
      ),
    };

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _content(BuildContext context) {
    if (_effectiveLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    Widget? iconWidget;
    if (leading != null) {
      iconWidget = leading;
    } else if (icon is String) {
      iconWidget = AppIcon(icon as String, size: 20);
    } else if (icon is IconData) {
      iconWidget = Icon(icon as IconData, size: 20);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconWidget != null) ...[
          iconWidget,
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(label),
      ],
    );
  }
}
