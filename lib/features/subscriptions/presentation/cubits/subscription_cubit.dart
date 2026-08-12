/*

CHECKS IF THE USER IS PRO OR FREE

*/

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/revenuecat_service.dart';
import 'subscription_states.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({
    bool attachRevenueCatListener = true,
    bool forcePro = false,
    Future<bool> Function()? isProCheck,
  }) : _isProCheck = isProCheck ?? RevenuecatService.isProUser,
       super(SubscriptionInitial()) {
    if (forcePro) {
      emit(const SubscriptionLoaded(true));
      return;
    }
    if (attachRevenueCatListener) {
      RevenuecatService.addCustomerInfoUpdateListener((_) {
        checkProStatus();
      });
    }
  }

  final Future<bool> Function() _isProCheck;

  Future<void> checkProStatus() async {
    emit(const SubscriptionLoading());
    try {
      final bool isPro = await _isProCheck();
      emit(SubscriptionLoaded(isPro));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> restorePurchases() async {
    await RevenuecatService.restorePurchases();
    await checkProStatus();
  }
}
