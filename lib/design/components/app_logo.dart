import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Neutral app mark used on auth and profile screens.
///
/// Renders a rounded brand surface with the app's first letter (or a custom
/// icon) so the template has no third-party branding. Future apps can replace
/// this with their real logo asset while keeping the same component slot.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.icon,
    this.label,
  });

  final double size;
  final IconData? icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, AppColors.primaryPressed],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: size * 0.5, color: scheme.onPrimary)
            : Text(
                label ?? '',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
      ),
    );
  }
}
