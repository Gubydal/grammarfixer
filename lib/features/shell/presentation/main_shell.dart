import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design/app_icons.dart';
import '../../../design/app_spacing.dart';
import '../../../design/components/app_bottom_bar.dart';
import '../../ads/presentation/app_banner_ad.dart';
import '../../home/presentation/home_page.dart';
import '../../profile/profile_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../subscriptions/presentation/cubits/subscription_cubit.dart';
import '../../subscriptions/presentation/cubits/subscription_states.dart';
import '../../subscriptions/presentation/pages/offerings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  List<AppBottomDestination> _destinations(BuildContext context) {
    final l10n = context.l10n;
    return [
      AppBottomDestination(icon: AppIcons.home, label: l10n.home),
      AppBottomDestination(icon: AppIcons.profile, label: l10n.profile),
      AppBottomDestination(icon: AppIcons.settings, label: l10n.settings),
      AppBottomDestination(icon: AppIcons.crown, label: l10n.upgrade),
    ];
  }

  String? _titleFor(BuildContext context, int index) {
    final l10n = context.l10n;
    return switch (index) {
      0 => null,
      1 => l10n.profile,
      2 => l10n.settings,
      3 => l10n.upgrade,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleFor(context, _index);
    return Scaffold(
      extendBody: true,
      appBar: title == null ? null : AppBar(title: Text(title)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BlocBuilder<SubscriptionCubit, SubscriptionState>(
              builder: (context, state) {
                final isPro = state is SubscriptionLoaded && state.isPro;
                if (_index <= 1 && !isPro) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
                    child: AppBannerAd(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  HomePage(onUpgrade: () => setState(() => _index = 3)),
                  const ProfilePage(),
                  const SettingsPage(),
                  const PaywallView(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _index,
        destinations: _destinations(context),
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}
