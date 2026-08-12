import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/feedback_repo.dart';
import 'feedback_states.dart';

class FeedbackCubit extends Cubit<FeedbackState> {
  FeedbackCubit(this._repo) : super(FeedbackInitial());

  final FeedbackRepo _repo;

  Future<void> submit({
    required int rating,
    required String message,
  }) async {
    emit(FeedbackSubmitting());
    try {
      await _repo.submit(rating: rating, message: message);
      emit(FeedbackSuccess());
    } catch (e) {
      emit(FeedbackError(e.toString()));
    }
  }
}
