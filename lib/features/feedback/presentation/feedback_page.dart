import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_icons.dart';
import '../../../design/app_spacing.dart';
import '../../../design/components/app_button.dart';
import '../../../design/components/app_state_view.dart';
import '../../../design/components/app_text_field.dart';
import '../data/supabase_feedback_repo.dart';
import '../domain/feedback_repo.dart';
import 'feedback_cubit.dart';
import 'feedback_states.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, this.repo});

  final FeedbackRepo? repo;

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

  void _submit(BuildContext context) {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a feedback message.')),
      );
      return;
    }
    context.read<FeedbackCubit>().submit(rating: _rating, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRepo = widget.repo ?? SupabaseFeedbackRepo(Supabase.instance.client);

    return BlocProvider<FeedbackCubit>(
      create: (_) => FeedbackCubit(effectiveRepo),
      child: Scaffold(
        appBar: AppBar(title: const Text('Send Feedback')),
        body: BlocConsumer<FeedbackCubit, FeedbackState>(
          listener: (context, state) {
            if (state is FeedbackSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: AppColors.primary,
                ),
              );
              Navigator.of(context).pop();
            } else if (state is FeedbackError) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not send feedback. Please try again later.'),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is FeedbackSubmitting) {
              return const LoadingStateView(message: 'Sending feedback…');
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'How is GrammarFix working for you?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.issueAmberBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.issueAmberBorder),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppIcon(AppIcons.warning, size: 16, color: AppColors.warning),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please don\'t include text you are correcting or other private information.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    hintText: 'Tell us what you think or how we can improve…',
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Send Feedback',
                    onPressed: () => _submit(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
