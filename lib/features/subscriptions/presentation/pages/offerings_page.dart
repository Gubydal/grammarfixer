import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/app_spacing.dart';
import '../../../../design/components/app_state_view.dart';
import '../../domain/entities/paywall_content.dart';
import '../cubits/offerings_cubit.dart';
import '../cubits/offerings_states.dart';
import '../cubits/subscription_cubit.dart';
import '../cubits/subscription_states.dart';

const Color _paywallBackground = Color(0xFF0F0F14);
const Color _paywallSurface = Color(0xFF1A1A21);
const Color _paywallAccent = Color(0xFFFFD12E);

/// Presents the paywall as a polished modal sheet.
Future<void> showPaywallSheet(
  BuildContext context, {
  PaywallContent? content,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.94,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: PaywallView(content: content),
      ),
    ),
  );
}

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key, this.content});

  final PaywallContent? content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paywallBackground,
      body: SafeArea(child: PaywallView(content: content)),
    );
  }
}

class PaywallView extends StatefulWidget {
  const PaywallView({super.key, this.content});

  final PaywallContent? content;

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  Package? _selected;

  PaywallContent get _content =>
      widget.content ?? PaywallContent.forApp(AppConfig.appName);

  @override
  void initState() {
    super.initState();
    context.read<OfferingsCubit>().loadOfferings();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _purchase(BuildContext context, Package package) async {
    final offeringsCubit = context.read<OfferingsCubit>();
    final subscriptionCubit = context.read<SubscriptionCubit>();
    await offeringsCubit.purchasePackage(package, () {
      subscriptionCubit.checkProStatus();
    });
  }

  Future<void> _restore() async {
    await context.read<SubscriptionCubit>().restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.purchasesRestored)),
      );
    }
  }

  void _selectDefault(List<Package> packages) {
    if (_selected != null || packages.isEmpty) return;
    final preferred = packages.indexWhere(
      (p) => p.packageType == _content.recommendedPlan,
    );
    _selected = packages[preferred >= 0 ? preferred : 0];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: _paywallBackground,
      body: SafeArea(
        child: BlocConsumer<OfferingsCubit, OfferingsState>(
          listener: (context, state) {
            if (state is PurchaseError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is OfferingsLoading || state is OfferingsInitial) {
              return const LoadingStateView(message: 'Loading offers…');
            }
            if (state is OfferingsError) {
              return _ErrorOffers(
                message: state.message,
                onRetry: () => context.read<OfferingsCubit>().loadOfferings(),
              );
            }

            final packages = state is OfferingsLoaded
                ? state.packages.whereType<Package>().toList()
                : <Package>[];
            _selectDefault(packages);
            final isPurchasing = state is PurchaseLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppIcon(
                        AppIcons.crown,
                        size: 22,
                        color: _paywallAccent,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _content.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.paywallTitle(AppConfig.appName),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _content.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB8B8C4),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (packages.isEmpty)
                    const _NoOffers()
                  else ...[
                    _BenefitList(benefits: _content.benefits),
                    const SizedBox(height: AppSpacing.xl),
                    _PlanCards(
                      packages: packages,
                      selected: _selected,
                      recommended: _content.recommendedPlan,
                      onSelected: (package) =>
                          setState(() => _selected = package),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _ActiveProGate(
                      child: FilledButton(
                        onPressed: _selected == null || isPurchasing
                            ? null
                            : () => _purchase(context, _selected!),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 58),
                          backgroundColor: _paywallAccent,
                          foregroundColor: const Color(0xFF111111),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(
                          _selected == null
                              ? l10n.subscribe
                              : '${_content.primaryCtaLabel ?? l10n.startPro} — '
                                    '${_selected!.storeProduct.priceString}',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _selected?.storeProduct.priceString ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB8B8C4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.autoRenewNote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8A8A96),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: isPurchasing ? null : _restore,
                    child: Text(
                      l10n.restorePurchases,
                      style: const TextStyle(color: Color(0xFFB8B8C4)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.md,
                    children: [
                      TextButton(
                        onPressed: () => _launchUrl(AppConfig.termsUrl),
                        child: const Text(
                          'Terms of Use',
                          style: TextStyle(color: Color(0xFF8A8A96)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _launchUrl(AppConfig.privacyPolicyUrl),
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(color: Color(0xFF8A8A96)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Shows a Pro-active panel instead of the purchase CTA when the user already
/// holds the entitlement.
class _ActiveProGate extends StatelessWidget {
  const _ActiveProGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      builder: (context, state) {
        final isPro = state is SubscriptionLoaded && state.isPro;
        if (!isPro) return child;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: _paywallSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _paywallAccent.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              const AppIcon(
                AppIcons.tickCircle,
                size: 34,
                color: _paywallAccent,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.proActiveTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.proActiveMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB8B8C4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BenefitList extends StatelessWidget {
  const _BenefitList({required this.benefits});

  final List<String> benefits;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final benefit in benefits)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                const AppIcon(
                  AppIcons.tickCircle,
                  size: 22,
                  color: _paywallAccent,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    benefit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanCards extends StatelessWidget {
  const _PlanCards({
    required this.packages,
    required this.selected,
    required this.recommended,
    required this.onSelected,
  });

  final List<Package> packages;
  final Package? selected;
  final PackageType recommended;
  final ValueChanged<Package> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < packages.length; i++) ...[
          Expanded(
            child: _PlanCard(
              package: packages[i],
              isSelected: selected?.identifier == packages[i].identifier,
              isRecommended: packages[i].packageType == recommended,
              onTap: () => onSelected(packages[i]),
            ),
          ),
          if (i != packages.length - 1) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.package,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  final Package package;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  String _periodLabel(BuildContext context) {
    return switch (package.packageType) {
      PackageType.annual => context.l10n.annual,
      PackageType.monthly => context.l10n.monthly,
      _ => package.storeProduct.title,
    };
  }

  String _periodSuffix(BuildContext context) {
    return switch (package.packageType) {
      PackageType.annual => context.l10n.perYear,
      PackageType.monthly => context.l10n.perMonth,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      label: _periodLabel(context),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? _paywallAccent.withValues(alpha: 0.10)
                : _paywallSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? _paywallAccent
                  : const Color(0xFF2C2C36),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Stack(
            children: [
              if (isRecommended)
                Positioned(
                  top: -9,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _paywallAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        context.l10n.bestValue,
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _periodLabel(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const AppIcon(
                          AppIcons.tickCircle,
                          size: 18,
                          color: _paywallAccent,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    package.storeProduct.priceString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _periodSuffix(context),
                    style: const TextStyle(
                      color: Color(0xFF8A8A96),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoOffers extends StatelessWidget {
  const _NoOffers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _paywallSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.l10n.noUpgradeMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFB8B8C4)),
      ),
    );
  }
}

class _ErrorOffers extends StatelessWidget {
  const _ErrorOffers({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB8B8C4), size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
