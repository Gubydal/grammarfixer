import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_icons.dart';
import '../../../design/app_spacing.dart';
import '../../../design/components/app_section_title.dart';
import '../../auth/presentation/cubits/auth_cubit.dart';
import '../../subscriptions/presentation/cubits/subscription_cubit.dart';
import '../../subscriptions/presentation/cubits/subscription_states.dart';
import 'components/pro_status_card.dart';

/// Generic template home.
///
/// This screen is intentionally a polished placeholder: future apps replace
/// the feature section with their main feature while keeping the shell,
/// Pro entry point, and design language.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onUpgrade});

  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final email = context.read<AuthCubit>().currentUser?.email ?? '';
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        140,
      ),
      children: [
        Text(
          l10n.homeGreeting(AppConfig.appName),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.homeReadyMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.homeSignedInAs(email),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIcon(
                      AppIcons.rocket,
                      size: 22,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.homeFeatureTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.homeFeatureMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionTitle(
          l10n.homeGetStarted,
          icon: Icons.rocket_launch_outlined,
        ),
        _StepCard(
          number: '1',
          text: l10n.homeStepOne,
        ),
        const SizedBox(height: AppSpacing.sm),
        _StepCard(
          number: '2',
          text: l10n.homeStepTwo,
        ),
        const SizedBox(height: AppSpacing.sm),
        _StepCard(
          number: '3',
          text: l10n.homeStepThree,
        ),
        const SizedBox(height: AppSpacing.xl),
        BlocBuilder<SubscriptionCubit, SubscriptionState>(
          builder: (context, state) {
            final isPro = state is SubscriptionLoaded && state.isPro;
            return ProStatusCard(
              isPro: isPro,
              onUpgrade: onUpgrade,
            );
          },
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
