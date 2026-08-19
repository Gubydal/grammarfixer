import 'package:flutter/material.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../data/repositories/personal_style_repository.dart';
import '../../domain/entities/language.dart';
import '../../domain/entities/writing_style_profile.dart';

class WritingStyleSheet extends StatefulWidget {
  const WritingStyleSheet({
    super.key,
    required this.personalStyleRepo,
  });

  final PersonalStyleRepository personalStyleRepo;

  static Future<void> show(
    BuildContext context, {
    required PersonalStyleRepository personalStyleRepo,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WritingStyleSheet(personalStyleRepo: personalStyleRepo),
    );
  }

  @override
  State<WritingStyleSheet> createState() => _WritingStyleSheetState();
}

class _WritingStyleSheetState extends State<WritingStyleSheet> {
  late WritingStyleProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.personalStyleRepo.profile;
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: AppIcon(
                        AppIcons.more,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Writing Style',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Tailor grammar suggestions & improve mode tone',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. TONE & FORMALITY PRESET
              _buildSectionTitle('WRITING TONE & FORMALITY', textSecondary),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildToneCard(
                    icon: '👔',
                    title: 'Professional',
                    subtitle: 'Polished & formal',
                    isSelected: _profile.formalityPreference == FormalityStyle.formal,
                    isDark: isDark,
                    onTap: () async {
                      await widget.personalStyleRepo.updateFormality(FormalityStyle.formal);
                      setState(() => _profile = widget.personalStyleRepo.profile);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildToneCard(
                    icon: '🌿',
                    title: 'Natural',
                    subtitle: 'Standard balance',
                    isSelected: _profile.formalityPreference == FormalityStyle.neutral,
                    isDark: isDark,
                    onTap: () async {
                      await widget.personalStyleRepo.updateFormality(FormalityStyle.neutral);
                      setState(() => _profile = widget.personalStyleRepo.profile);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildToneCard(
                    icon: '😊',
                    title: 'Casual',
                    subtitle: 'Warm & relaxed',
                    isSelected: _profile.formalityPreference == FormalityStyle.casual,
                    isDark: isDark,
                    onTap: () async {
                      await widget.personalStyleRepo.updateFormality(FormalityStyle.casual);
                      setState(() => _profile = widget.personalStyleRepo.profile);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. ENGLISH DIALECT
              _buildSectionTitle('ENGLISH DIALECT', textSecondary),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDialectChip(EnglishDialect.american, '🇺🇸 American (US)', isDark),
                  _buildDialectChip(EnglishDialect.british, '🇬🇧 British (UK)', isDark),
                  _buildDialectChip(EnglishDialect.canadian, '🇨🇦 Canadian (CA)', isDark),
                  _buildDialectChip(EnglishDialect.australian, '🇦🇺 Australian (AU)', isDark),
                ],
              ),
              const SizedBox(height: 20),

              // 3. CONTRACTION PREFERENCES
              _buildSectionTitle('CONTRACTIONS', textSecondary),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    _buildOptionItem(
                      title: 'Natural (don\'t, can\'t, I\'ll)',
                      isSelected: _profile.contractionsPreference == ContractionStyle.preferContractions,
                      isDark: isDark,
                      onTap: () async {
                        await widget.personalStyleRepo.updateContractionsPreference(ContractionStyle.preferContractions);
                        setState(() => _profile = widget.personalStyleRepo.profile);
                      },
                    ),
                    const Divider(height: 1),
                    _buildOptionItem(
                      title: 'Expanded / Formal (do not, cannot, I will)',
                      isSelected: _profile.contractionsPreference == ContractionStyle.preferExpanded,
                      isDark: isDark,
                      onTap: () async {
                        await widget.personalStyleRepo.updateContractionsPreference(ContractionStyle.preferExpanded);
                        setState(() => _profile = widget.personalStyleRepo.profile);
                      },
                    ),
                    const Divider(height: 1),
                    _buildOptionItem(
                      title: 'No preference',
                      isSelected: _profile.contractionsPreference == ContractionStyle.neutral,
                      isDark: isDark,
                      onTap: () async {
                        await widget.personalStyleRepo.updateContractionsPreference(ContractionStyle.neutral);
                        setState(() => _profile = widget.personalStyleRepo.profile);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. OXFORD COMMA
              _buildSectionTitle('OXFORD (SERIAL) COMMA', textSecondary),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    _buildOptionItem(
                      title: 'Always use ("apples, bananas, and oranges")',
                      isSelected: _profile.oxfordCommaPreference == OxfordCommaStyle.always,
                      isDark: isDark,
                      onTap: () async {
                        await widget.personalStyleRepo.updateOxfordCommaPreference(OxfordCommaStyle.always);
                        setState(() => _profile = widget.personalStyleRepo.profile);
                      },
                    ),
                    const Divider(height: 1),
                    _buildOptionItem(
                      title: 'Never use ("apples, bananas and oranges")',
                      isSelected: _profile.oxfordCommaPreference == OxfordCommaStyle.never,
                      isDark: isDark,
                      onTap: () async {
                        await widget.personalStyleRepo.updateOxfordCommaPreference(OxfordCommaStyle.never);
                        setState(() => _profile = widget.personalStyleRepo.profile);
                      },
                    ),
                    const Divider(height: 1),
                    _buildOptionItem(
                      title: 'No preference',
                      isSelected: _profile.oxfordCommaPreference == OxfordCommaStyle.neutral,
                      isDark: isDark,
                      onTap: () async {
                        await widget.personalStyleRepo.updateOxfordCommaPreference(OxfordCommaStyle.neutral);
                        setState(() => _profile = widget.personalStyleRepo.profile);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildToneCard({
    required String icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurfaceGreen : AppColors.primarySoft)
                : (isDark ? AppColors.darkSurface : AppColors.lightSurfaceSoft),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialectChip(EnglishDialect dialect, String label, bool isDark) {
    final isSelected = _profile.dialect == dialect;
    return GestureDetector(
      onTap: () async {
        await widget.personalStyleRepo.updateDialect(dialect);
        setState(() => _profile = widget.personalStyleRepo.profile);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurfaceGreen : AppColors.primarySoft)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurfaceSoft),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          : Icon(Icons.circle_outlined, color: isDark ? AppColors.darkBorder : AppColors.lightBorder, size: 20),
      onTap: onTap,
    );
  }
}
