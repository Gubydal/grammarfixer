import 'package:purchases_flutter/purchases_flutter.dart';

/// Configurable copy for the reusable paywall.
///
/// The visual structure (header, benefits, plan cards, CTA, restore, legal
/// links, active-Pro state) is fixed by the template; only the app-specific
/// words are configured here. Prices always come from RevenueCat at runtime.
class PaywallContent {
  const PaywallContent({
    required this.title,
    required this.subtitle,
    required this.benefits,
    this.primaryCtaLabel,
    this.recommendedPlan = PackageType.annual,
  });

  /// e.g. `'<App Name> Pro'`.
  final String title;

  /// e.g. `'Unlock the full power of <App Name>.'`.
  final String subtitle;

  /// App-specific benefit list rendered above the plan cards.
  final List<String> benefits;

  /// CTA label; defaults to a localized "Start Pro" when null.
  final String? primaryCtaLabel;

  /// Which plan card gets the "Best value" badge.
  final PackageType recommendedPlan;

  /// Default template content. Future apps replace the benefits/title with
  /// their own app-specific copy.
  factory PaywallContent.forApp(String appName) {
    return PaywallContent(
      title: '$appName Pro',
      subtitle: 'Enjoy a completely ad-free, uninterrupted writing experience.',
      benefits: const [
        '100% Ad-free experience',
        'Support independent, privacy-first software',
        'Fast & uninterrupted corrections everywhere',
      ],
    );
  }
}
