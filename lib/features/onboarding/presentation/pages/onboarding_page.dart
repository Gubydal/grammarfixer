import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/components/app_button.dart';
import '../../../shell/presentation/main_shell.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    // Screen 1: Privacy First
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: AppIcon(
                              AppIcons.lock,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Private Grammar Correction',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Everything runs locally on your phone. No cloud servers, no AI tracking, and your writing never leaves your device.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Screen 2: System Text Selection Integration
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: AppIcon(
                              AppIcons.tickCircle,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Works Anywhere on Android',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Select text in your favorite apps (Messages, Browser, Notes) and choose "Fix grammar" for instant on-device correction.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  2,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Start as guest',
                icon: AppIcons.rocket,
                onPressed: _completeOnboarding,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
