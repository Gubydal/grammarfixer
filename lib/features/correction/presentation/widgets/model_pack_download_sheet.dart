import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/components/app_button.dart';
import '../../data/repositories/model_pack_repository.dart';
import '../cubits/model_pack_cubit.dart';

class ModelPackDownloadSheet extends StatelessWidget {
  const ModelPackDownloadSheet({
    super.key,
    required this.onDownloadStarted,
  });

  final VoidCallback onDownloadStarted;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModelPackDownloadSheet(
        onDownloadStarted: () {
          context.read<ModelPackCubit>().downloadPack();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SafeArea(
        child: BlocConsumer<ModelPackCubit, ModelPackState>(
          listener: (context, state) {
            if (state.isInstalled) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Offline language pack installed successfully.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          },
          builder: (context, state) {
            final isDownloading = state.isDownloading;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: AppIcon(
                          AppIcons.download,
                          size: 24,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline Language Pack',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Size: ~475 MB · Google Play On-Demand',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Correct Arabic, French, Spanish, German, Portuguese, and Italian entirely on your phone with zero internet required after download.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceGreen : AppColors.lightSurfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const AppIcon(AppIcons.lock, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Privacy Absolute: User writing never leaves your device. No cloud AI is used.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (isDownloading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: state.progress > 0 ? state.progress : null,
                      minHeight: 8,
                      backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Downloading offline pack… ${(state.progress * 100).toInt()}%',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  AppButton(
                    label: 'Download Pack (~475 MB)',
                    icon: AppIcons.download,
                    onPressed: () {
                      onDownloadStarted();
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Not now'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
