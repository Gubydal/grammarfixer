import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/components/app_button.dart';
import '../../data/repositories/correction_repository.dart';
import '../../domain/entities/correction_result.dart';
import '../../domain/entities/language.dart';

class ProcessTextPage extends StatefulWidget {
  const ProcessTextPage({
    super.key,
    required this.correctionRepository,
    this.initialText = '',
    this.isReadOnly = false,
  });

  final CorrectionRepository correctionRepository;
  final String initialText;
  final bool isReadOnly;

  @override
  State<ProcessTextPage> createState() => _ProcessTextPageState();
}

class _ProcessTextPageState extends State<ProcessTextPage> {
  static const MethodChannel _channel = MethodChannel('com.mogate.grammarfix/process_text_channel');

  String _inputText = '';
  bool _isReadOnly = false;
  bool _isLoading = true;
  CorrectionResult? _result;

  @override
  void initState() {
    super.initState();
    _fetchIntentAndProcess();
  }

  Future<void> _fetchIntentAndProcess() async {
    String text = widget.initialText;
    bool readOnly = widget.isReadOnly;

    if (text.isEmpty) {
      try {
        final data = await _channel.invokeMethod<Map<dynamic, dynamic>>('getProcessTextData');
        if (data != null) {
          text = data['text'] as String? ?? '';
          readOnly = data['isReadOnly'] as bool? ?? false;
        }
      } catch (_) {}
    }

    setState(() {
      _inputText = text;
      _isReadOnly = readOnly;
    });

    if (text.trim().isNotEmpty) {
      final res = await widget.correctionRepository.correct(
        text: text,
        selectedLanguage: AppLanguage.auto,
      );
      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyAndFinish() async {
    final corrected = _result?.correctedText ?? _inputText;
    try {
      await _channel.invokeMethod<bool>('applyCorrection', {
        'correctedText': corrected,
      });
    } catch (_) {}
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop(corrected);
    }
  }

  Future<void> _cancelAndFinish() async {
    try {
      await _channel.invokeMethod<bool>('cancel');
    } catch (_) {}
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final correctedText = _result?.correctedText ?? _inputText;
    final hasIssues = _result != null && _result!.hasIssues;
    final issueCount = _result?.activeIssueCount ?? 0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: AppIcon(AppIcons.tickCircle, size: 18, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Fix Grammar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const AppIcon(AppIcons.x, size: 18),
                    onPressed: _cancelAndFinish,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_isLoading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ] else if (_inputText.trim().isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No text was selected.',
                    style: TextStyle(color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceGreen : AppColors.lightSurfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      correctedText,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AppIcon(
                      hasIssues ? AppIcons.tickCircle : AppIcons.success,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    Expanded(
                      child: Text(
                        hasIssues
                            ? 'Corrected ($issueCount fix${issueCount == 1 ? '' : 'es'} applied)'
                            : 'Text is already correct',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (!_isReadOnly) ...[
                  AppButton(
                    label: 'Apply to text',
                    icon: AppIcons.tick,
                    onPressed: _applyAndFinish,
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const AppIcon(AppIcons.copy, size: 16),
                        label: const Text('Copy'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: correctedText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              backgroundColor: AppColors.primary,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelAndFinish,
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
