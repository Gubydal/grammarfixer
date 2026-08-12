import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../domain/feedback_repo.dart';

class SupabaseFeedbackRepo implements FeedbackRepo {
  SupabaseFeedbackRepo(this._client);

  final SupabaseClient _client;

  @override
  Future<void> submit({
    required int rating,
    required String message,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to send feedback.');
    }

    await _client
        .schema(AppConfig.supabaseSchema)
        .from('feedback')
        .insert({
          'user_id': user.id,
          'rating': rating,
          'message': message,
        });
  }
}
