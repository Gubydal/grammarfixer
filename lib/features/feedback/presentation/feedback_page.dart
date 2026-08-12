import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/app_spacing.dart';
import '../../../design/components/app_button.dart';
import '../../../design/components/app_text_field.dart';
import '../../../design/components/app_state_view.dart';
import '../domain/feedback_repo.dart';
import 'feedback_cubit.dart';
import 'feedback_states.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, required this.repo});

  final FeedbackRepo repo;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _messageController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.feedbackEmpty)),
      );
      return;
    }
    context.read<FeedbackCubit>().submit(rating: _rating, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sendFeedback)),
      body: BlocConsumer<FeedbackCubit, FeedbackState>(
        listener: (context, state) {
          if (state is FeedbackSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.feedbackThanks)),
            );
            Navigator.of(context).pop();
          } else if (state is FeedbackError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.feedbackError)),
            );
          }
        },
        builder: (context, state) {
          if (state is FeedbackSubmitting) {
            return LoadingStateView(message: l10n.feedbackSending);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.feedbackPrompt(AppConfig.appName),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      onPressed: () => setState(() => _rating = star),
                      icon: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 36,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _messageController,
                  hintText: l10n.feedbackHint,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.sendFeedback,
                  onPressed: _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
