abstract class SubscriptionState {
  const SubscriptionState();
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

class SubscriptionLoaded extends SubscriptionState {
  const SubscriptionLoaded(this.isPro);

  final bool isPro;
}

class SubscriptionError extends SubscriptionState {
  const SubscriptionError(this.message);

  final String message;
}
