import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../domain/feedback_repo.dart';

class SupabaseFeedbackRepo implements FeedbackRepo {
  SupabaseFeedbackRepo(this._client);

  final SupabaseClient _client;

  @override
  Future<void> submit({
    required int rating,
    required String message,
  }) async {
    await _client
        .schema(AppConfig.supabaseSchema)
        .from('feedback')
        .insert({
          'rating': rating,
          'message': message,
          'app_version': '1.0.0',
        });
  }
}
