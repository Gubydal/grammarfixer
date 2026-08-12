abstract class FeedbackRepo {
  Future<void> submit({
    required int rating,
    required String message,
  });
}
