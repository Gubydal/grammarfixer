import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design/app_icons.dart';
import '../../../design/components/app_bottom_bar.dart';
import '../../ads/presentation/app_banner_ad.dart';
import '../../correction/presentation/pages/editor_page.dart';
import '../../settings/presentation/pages/settings_page.dart';
import '../../subscriptions/presentation/cubits/subscription_cubit.dart';
import '../../subscriptions/presentation/cubits/subscription_states.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  List<AppBottomDestination> _destinations() {
    return const [
      AppBottomDestination(icon: AppIcons.edit, label: 'Correct'),
      AppBottomDestination(icon: AppIcons.settings, label: 'Settings'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BlocBuilder<SubscriptionCubit, SubscriptionState>(
              builder: (context, state) {
                final isPro = state is SubscriptionLoaded && state.isPro;
                if (!isPro && _index == 1) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: AppBannerAd(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  EditorPage(),
                  SettingsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _index,
        destinations: _destinations(),
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}
