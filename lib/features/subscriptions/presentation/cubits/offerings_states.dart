import 'package:purchases_flutter/purchases_flutter.dart';

abstract class OfferingsState {
  const OfferingsState();
}

class OfferingsInitial extends OfferingsState {
  const OfferingsInitial();
}

class OfferingsLoading extends OfferingsState {
  const OfferingsLoading();
}

class OfferingsLoaded extends OfferingsState {
  const OfferingsLoaded(this.packages);

  final List<Package?> packages;
}

class OfferingsError extends OfferingsState {
  const OfferingsError(this.message);

  final String message;
}

class PurchaseLoading extends OfferingsState {
  const PurchaseLoading();
}

class PurchaseError extends OfferingsState {
  const PurchaseError(this.message);

  final String message;
}
