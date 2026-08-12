import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/l10n/l10n.dart';
import '../../design/app_spacing.dart';
import '../../design/components/app_logo.dart';
import '../../design/components/app_plan_card.dart';
import '../auth/presentation/cubits/auth_cubit.dart';
import '../subscriptions/presentation/cubits/subscription_cubit.dart';
import '../subscriptions/presentation/cubits/subscription_states.dart';
import '../subscriptions/presentation/pages/offerings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;
    final email = user?.email ?? '';
    final displayName = user?.displayName;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        140,
      ),
      children: [
        Center(
          child: AppLogo(
            size: 96,
            label: (displayName ?? email.split('@').first)
                .trim()
                .isEmpty
                ? '?'
                : (displayName ?? email).trim()[0].toUpperCase(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          displayName ?? email.split('@').first,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          email,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        BlocBuilder<SubscriptionCubit, SubscriptionState>(
          builder: (context, state) {
            final isPro = state is SubscriptionLoaded && state.isPro;
            return AppPlanCard(
              isPro: isPro,
              title: isPro ? l10n.proPlan : l10n.freePlan,
              subtitle: isPro
                  ? l10n.proCardProMessage
                  : l10n.proCardFreeMessage,
              upgradeLabel: l10n.upgradeToPro,
              onUpgrade: () => showPaywallSheet(context),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.profileDataNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
