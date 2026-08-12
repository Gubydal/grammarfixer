abstract class FeedbackState {}

class FeedbackInitial extends FeedbackState {}

class FeedbackSubmitting extends FeedbackState {}

class FeedbackSuccess extends FeedbackState {}

class FeedbackError extends FeedbackState {
  FeedbackError(this.message);

  final String message;
}
