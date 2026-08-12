import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_icons.dart';

/// A single destination in the floating glass bottom bar.
class AppBottomDestination {
  const AppBottomDestination({
    required this.icon,
    required this.label,
    this.semanticsLabel,
  });

  final String icon;
  final String label;
  final String? semanticsLabel;
}

/// Floating glass bottom bar: a compact translucent glossy rounded rectangle
/// that holds the configured destinations. Icons change color when selected;
/// no pill outline.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppBottomDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(48, 0, 48, 10),
        child: SizedBox(
          height: 54,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.black.withValues(alpha: 0.24),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.42),
                            Colors.white.withValues(alpha: 0.16),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.22 : 0.07,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 22,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(27),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(
                                  alpha: isDark ? 0.08 : 0.30,
                                ),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          Expanded(
                            child: _Slot(
                              icon: destinations[i].icon,
                              selected: currentIndex == i,
                              label: destinations[i].semanticsLabel ??
                                  destinations[i].label,
                              color: scheme.primary,
                              onTap: () => onDestinationSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.icon,
    required this.selected,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String icon;
  final bool selected;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? color : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: color.withValues(alpha: 0.14),
          highlightColor: color.withValues(alpha: 0.06),
          child: SizedBox(
            height: 44,
            child: Center(child: AppIcon(icon, size: 22, color: foreground)),
          ),
        ),
      ),
    );
  }
}
