import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/play_services.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../../correction/data/repositories/draft_repository.dart';
import '../../../correction/data/repositories/model_pack_repository.dart';
import '../../../correction/data/repositories/personal_style_repository.dart';
import '../../../correction/domain/entities/language.dart';
import '../../../correction/presentation/cubits/correction_cubit.dart';
import '../../../correction/presentation/cubits/model_pack_cubit.dart';
import '../../../correction/presentation/widgets/model_pack_download_sheet.dart';
import '../../../feedback/presentation/feedback_page.dart';
import '../../../subscriptions/presentation/cubits/subscription_cubit.dart';
import '../../../subscriptions/presentation/cubits/subscription_states.dart';
import '../../../subscriptions/presentation/pages/offerings_page.dart';
import 'custom_dictionary_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _settingsChannel = MethodChannel('com.mogate.grammarfix/android_settings');
  Map<String, dynamic>? _keyboardStatus;
  Map<String, dynamic>? _spellCheckerStatus;

  @override
  void initState() {
    super.initState();
    _refreshNativeStatus();
  }

  Future<void> _refreshNativeStatus() async {
    try {
      final kbStatus = await _settingsChannel.invokeMapMethod<String, dynamic>('getKeyboardStatus');
      final scStatus = await _settingsChannel.invokeMapMethod<String, dynamic>('getSpellCheckerStatus');
      if (mounted) {
        setState(() {
          _keyboardStatus = kbStatus;
          _spellCheckerStatus = scStatus;
        });
      }
    } catch (_) {
      // Native bridge not available (e.g. running on iOS or test)
    }
  }

  void _showDialectPicker(BuildContext context, PersonalStyleRepository personalStyleRepo) {
    final currentDialect = personalStyleRepo.profile.dialect;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'English Variant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...EnglishDialect.values.map((dialect) {
                final isSelected = dialect == currentDialect;
                return ListTile(
                  title: Text(dialect.displayName),
                  trailing: isSelected ? const AppIcon(AppIcons.tickCircle, size: 20, color: AppColors.primary) : null,
                  onTap: () {
                    personalStyleRepo.updateDialect(dialect);
                    context.read<CorrectionCubit>().setLanguage(AppLanguage.english);
                    setState(() {});
                    Navigator.pop(bCtx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonalStyleDialog(BuildContext context, PersonalStyleRepository personalStyleRepo) {
    final profile = personalStyleRepo.profile;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            AppIcon(AppIcons.edit, size: 22, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Personal Style'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GrammarFix learns your personal style preferences locally from your accepted and rejected suggestions.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            _buildStyleItem('Active Dialect', profile.dialect.displayName),
            _buildStyleItem('Accepted Patterns', '${profile.acceptedStylePatterns.length} learned'),
            _buildStyleItem('Rejected Patterns', '${profile.rejectedStylePatterns.length} muted'),
            _buildStyleItem('Preferred Terms', '${profile.preferredTerms.length} saved'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: Objective grammar rules (e.g. subject-verb agreement) can never be learned away.',
                style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await personalStyleRepo.resetProfile();
              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Personal style reset to defaults')),
                );
              }
            },
            child: const Text('Reset Style', style: TextStyle(color: AppColors.error)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showKeyboardSetupDialog(BuildContext context) {
    final isEnabled = _keyboardStatus?['enabled'] == true;
    final isActive = _keyboardStatus?['active'] == true;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            AppIcon(AppIcons.tickCircle, size: 22, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Grammar Keyboard'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isActive) ...[
              const Text('✓ GrammarFix Keyboard is your active keyboard!',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 12),
              const Text('You can switch input methods when typing using the keyboard icon in your navigation bar.'),
            ] else if (isEnabled) ...[
              const Text('GrammarFix Keyboard is enabled but not active.'),
              const SizedBox(height: 12),
              const Text('Tap "Switch Now" to make it your active keyboard.'),
            ] else ...[
              const Text('To use GrammarFix while typing in any app:'),
              const SizedBox(height: 12),
              const Text('1. Tap "Open Settings" below.'),
              const SizedBox(height: 6),
              const Text('2. Enable "GrammarFix Keyboard".'),
              const SizedBox(height: 6),
              const Text('3. Switch your input method when typing.'),
            ],
            const SizedBox(height: 12),
            const Text(
              'Privacy Guarantee: Password fields and PINs automatically disable all correction suggestions. No keystroke data leaves your phone.',
              style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (isEnabled && !isActive)
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _settingsChannel.invokeMethod<bool>('showInputMethodPicker');
                } catch (_) {}
                await _refreshNativeStatus();
              },
              child: const Text('Switch Now'),
            )
          else if (!isEnabled)
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _settingsChannel.invokeMethod<bool>('openInputMethodSettings');
                } catch (_) {
                  if (context.mounted) {
                    _showManualSettingsGuide(context, 'Keyboard & Input Methods');
                  }
                }
                await _refreshNativeStatus();
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }

  void _showManualSettingsGuide(BuildContext context, String targetSection) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open Settings Manually'),
        content: Text(
          'Your device vendor customized the settings menu. Please navigate to:\n\n'
          'Android Settings -> System -> Languages & Input -> $targetSection\n\n'
          'and enable GrammarFix.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draftRepo = context.read<DraftRepository>();
    final personalStyleRepo = context.watch<PersonalStyleRepository>();
    final isDraftEnabled = draftRepo.isPersistenceEnabled;
    final isPrivateMode = personalStyleRepo.isPrivateMode;
    final isAutoFixEnabled = personalStyleRepo.isAutoFixEnabled;
    final currentDialect = personalStyleRepo.profile.dialect;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 1. WRITING SECTION
            _buildSectionHeader('WRITING'),
            _buildCard([
              ListTile(
                leading: const AppIcon(AppIcons.edit, size: 20),
                title: const Text('English Variant'),
                subtitle: Text(currentDialect.displayName),
                trailing: const AppIcon(AppIcons.arrowRight, size: 16),
                onTap: () => _showDialectPicker(context, personalStyleRepo),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const AppIcon(AppIcons.tickCircle, size: 20),
                title: const Text('Auto-Fix Obvious Mistakes'),
                subtitle: const Text('Automatically fixes clear typos on correct (high confidence only)'),
                value: isAutoFixEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  await personalStyleRepo.setAutoFixEnabled(val);
                  setState(() {});
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const AppIcon(AppIcons.more, size: 20),
                title: const Text('Personal Style'),
                subtitle: const Text('Adaptive local preferences (dialect, Oxford comma, formality)'),
                trailing: const AppIcon(AppIcons.arrowRight, size: 16),
                onTap: () => _showPersonalStyleDialog(context, personalStyleRepo),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const AppIcon(AppIcons.lock, size: 20),
                title: const Text('Private Mode'),
                subtitle: const Text('Pauses style learning and clears all ephemeral context'),
                value: isPrivateMode,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  await personalStyleRepo.setPrivateMode(val);
                  setState(() {});
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const AppIcon(AppIcons.bookmark, size: 20),
                title: const Text('Custom Dictionary'),
                subtitle: const Text('Manage locally whitelisted words and names'),
                trailing: const AppIcon(AppIcons.arrowRight, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CustomDictionaryPage()),
                  );
                },
              ),
            ]),

            const SizedBox(height: 20),

            // 2. WRITING EVERYWHERE (Android System-Wide)
            _buildSectionHeader('WRITING EVERYWHERE'),
            _buildCard([
              ListTile(
                leading: AppIcon(
                  _keyboardStatus?['active'] == true ? AppIcons.tickCircle : AppIcons.edit,
                  size: 20,
                  color: _keyboardStatus?['active'] == true ? AppColors.primary : null,
                ),
                title: const Text('Grammar Keyboard'),
                subtitle: Text(
                  _keyboardStatus?['active'] == true
                      ? 'Active ✓'
                      : _keyboardStatus?['enabled'] == true
                          ? 'Enabled · Tap to switch'
                          : 'Not enabled · Real-time suggestions while typing',
                ),
                trailing: _keyboardStatus?['active'] == true
                    ? FilledButton.tonal(
                        onPressed: () async {
                          try {
                            await _settingsChannel.invokeMethod<bool>('showInputMethodPicker');
                          } catch (_) {}
                          await _refreshNativeStatus();
                        },
                        child: const Text('Choose'),
                      )
                    : _keyboardStatus?['enabled'] == true
                        ? FilledButton.tonal(
                            onPressed: () async {
                              try {
                                await _settingsChannel.invokeMethod<bool>('showInputMethodPicker');
                              } catch (_) {}
                              await _refreshNativeStatus();
                            },
                            child: const Text('Switch'),
                          )
                        : FilledButton.tonal(
                            onPressed: () => _showKeyboardSetupDialog(context),
                            child: const Text('Enable'),
                          ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: AppIcon(
                  _spellCheckerStatus?['available'] == true ? AppIcons.tick : AppIcons.tick,
                  size: 20,
                  color: _spellCheckerStatus?['available'] == true ? AppColors.primary : null,
                ),
                title: const Text('System Grammar Checker'),
                subtitle: Text(
                  _spellCheckerStatus?['available'] == true
                      ? 'Available · Compatible apps show local suggestions'
                      : 'Not available',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () async {
                    try {
                      await _settingsChannel.invokeMethod<bool>('openSpellCheckerSettingsIfSupported');
                    } catch (_) {
                      if (context.mounted) {
                        _showManualSettingsGuide(context, 'Spell Checker / Text Services');
                      }
                    }
                    await _refreshNativeStatus();
                  },
                  child: const Text('Set up'),
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: AppIcon(AppIcons.more, size: 20),
                title: Text('Select text → Fix grammar'),
                subtitle: Text('Select text in any app, choose "Fix grammar" from the menu'),
              ),
            ]),

            const SizedBox(height: 20),

            // 3. OFFLINE LANGUAGES SECTION
            _buildSectionHeader('OFFLINE LANGUAGES'),
            BlocBuilder<ModelPackCubit, ModelPackState>(
              builder: (context, packState) {
                final isInstalled = packState.isInstalled;
                return _buildCard([
                  ListTile(
                    leading: AppIcon(
                      isInstalled ? AppIcons.tickCircle : AppIcons.download,
                      size: 20,
                      color: isInstalled ? AppColors.primary : null,
                    ),
                    title: const Text('Multilingual Model Pack'),
                    subtitle: Text(
                      isInstalled
                          ? 'Installed · ~475 MB (Arabic, French, Spanish, German, Portuguese, Italian)'
                          : 'Not installed · Arabic, French, Spanish, German, Portuguese, Italian',
                    ),
                    trailing: isInstalled
                        ? TextButton(
                            onPressed: () {
                              context.read<ModelPackCubit>().removePack();
                            },
                            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
                          )
                        : TextButton(
                            onPressed: () => ModelPackDownloadSheet.show(context),
                            child: const Text('Download'),
                          ),
                  ),
                ]);
              },
            ),

            const SizedBox(height: 20),

            // 4. PRIVACY & STORAGE SECTION
            _buildSectionHeader('PRIVACY & STORAGE'),
            _buildCard([
              SwitchListTile(
                secondary: const AppIcon(AppIcons.lock, size: 20),
                title: const Text('Save Editor Draft Locally'),
                subtitle: const Text('Keeps typed text on device across restarts (Default: Off)'),
                value: isDraftEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  await draftRepo.setPersistenceEnabled(val);
                  setState(() {});
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const AppIcon(AppIcons.link, size: 20),
                title: const Text('Privacy Policy'),
                subtitle: const Text('Writing stays 100% on your phone'),
                trailing: const AppIcon(AppIcons.arrowRight, size: 16),
                onTap: () => launchUrl(Uri.parse(AppConfig.privacyPolicyUrl)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const AppIcon(AppIcons.link, size: 20),
                title: const Text('Terms of Service'),
                trailing: const AppIcon(AppIcons.arrowRight, size: 16),
                onTap: () => launchUrl(Uri.parse(AppConfig.termsUrl)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const AppIcon(AppIcons.trash, size: 20),
                title: const Text('Delete Account & Local Data'),
                trailing: const AppIcon(AppIcons.arrowRight, size: 16),
                onTap: () => launchUrl(Uri.parse(AppConfig.accountDeletionUrl)),
              ),
            ]),

            const SizedBox(height: 20),

            // 5. MEMBERSHIP SECTION (Pro removes ads)
            _buildSectionHeader('MEMBERSHIP'),
            _buildCard([
              BlocBuilder<SubscriptionCubit, SubscriptionState>(
                builder: (context, subState) {
                  final isPro = subState is SubscriptionLoaded && subState.isPro;
                  return ListTile(
                    leading: AppIcon(
                      AppIcons.crown,
                      size: 20,
                      color: isPro ? AppColors.primary : null,
                    ),
                    title: Text(isPro ? 'Pro Member (Ad-Free)' : 'Go Ad-Free'),
                    subtitle: Text(isPro ? 'Thank you for your support!' : 'Remove ads completely'),
                    trailing: isPro
                        ? const AppIcon(AppIcons.tickCircle, size: 20, color: AppColors.primary)
                        : const AppIcon(AppIcons.arrowRight, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const PaywallPage()),
                      );
                    },
                  );
                },
              ),
            ]),

            const SizedBox(height: 20),

            // 6. SUPPORT & APP INFO
            _buildSectionHeader('SUPPORT & APP INFO'),
            _buildCard([
              ListTile(
                leading: const AppIcon(AppIcons.message, size: 20),
                title: const Text('Send Anonymous Feedback'),
                trailing: const AppIcon(AppIcons.arrowRight, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const FeedbackPage()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const AppIcon(AppIcons.info, size: 20),
                title: const Text('Check for Updates'),
                trailing: const AppIcon(AppIcons.arrowRight, size: 16),
                onTap: () => PlayServices.checkForUpdate(),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: AppIcon(AppIcons.info, size: 20),
                title: Text('Version'),
                trailing: Text('1.0.0+1', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}
