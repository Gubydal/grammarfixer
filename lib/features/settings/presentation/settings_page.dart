import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/play_services.dart';
import '../../../design/app_icons.dart';
import '../../../design/app_spacing.dart';
import '../../../design/components/app_settings_tile.dart';
import '../../auth/presentation/cubits/auth_cubit.dart';
import '../../feedback/data/supabase_feedback_repo.dart';
import '../../feedback/presentation/feedback_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenLink)),
      );
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.logoutTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().logout();
            },
            child: Text(context.l10n.logout),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteAccountTitle),
        content: Text(context.l10n.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().deleteAccount();
            },
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        140,
      ),
      children: [
        AppSettingsTile(
          icon: AppIcons.compose,
          title: l10n.sendFeedback,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FeedbackPage(
                  repo: SupabaseFeedbackRepo(Supabase.instance.client),
                ),
              ),
            );
          },
        ),
        AppSettingsTile(
          icon: AppIcons.star,
          title: l10n.rateOnGooglePlay,
          onTap: () => PlayServices.openStoreListing(),
        ),
        AppSettingsTile(
          icon: AppIcons.lock,
          title: l10n.privacyPolicy,
          onTap: () => _openUrl(context, AppConfig.privacyPolicyUrl),
        ),
        AppSettingsTile(
          icon: AppIcons.paperBlank,
          title: l10n.termsOfUse,
          onTap: () => _openUrl(context, AppConfig.termsUrl),
        ),
        AppSettingsTile(
          icon: AppIcons.link,
          title: l10n.deleteAccountOnWeb,
          subtitle: AppConfig.accountDeletionUrl,
          onTap: () => _openUrl(context, AppConfig.accountDeletionUrl),
        ),
        const Divider(height: AppSpacing.lg),
        AppSettingsTile(
          icon: AppIcons.logout,
          title: l10n.logout,
          showChevron: false,
          onTap: () => _confirmLogout(context),
        ),
        AppSettingsTile(
          icon: AppIcons.trash,
          title: l10n.deleteAccount,
          destructive: true,
          showChevron: false,
          onTap: () => _confirmDeleteAccount(context),
        ),
      ],
    );
  }
}
