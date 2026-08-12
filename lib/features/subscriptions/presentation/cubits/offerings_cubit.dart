/*

THIS CUBIT IS RESPONSIBLE FOR FETCHING & PURCHASING OFFERINGS FROM REVENUECAT

The async seams (fetchOfferings / purchasePackage) default to the live
RevenueCat SDK and can be injected in tests.

*/

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../data/revenuecat_service.dart';
import 'offerings_states.dart';

class OfferingsCubit extends Cubit<OfferingsState> {
  OfferingsCubit({
    Future<Offerings?> Function()? fetchOfferings,
    Future<CustomerInfo?> Function(Package package)? purchasePackage,
  }) : _fetchOfferings = fetchOfferings ?? RevenuecatService.fetchOfferings,
       _purchasePackage =
           purchasePackage ?? RevenuecatService.purchasePackage,
       super(const OfferingsInitial());

  final Future<Offerings?> Function() _fetchOfferings;
  final Future<CustomerInfo?> Function(Package package) _purchasePackage;

  // Cache of the loaded packages so the UI can return after a purchase
  // attempt without refetching.
  List<Package> _packages = [];

  List<Package> get packages => List.unmodifiable(_packages);

  // LOAD OFFERINGS
  Future<void> loadOfferings() async {
    emit(const OfferingsLoading());

    try {
      final offerings = await _fetchOfferings();

      // offerings are available
      if (offerings != null && offerings.current != null) {
        _packages = [];

        // add monthly package if available
        if (offerings.current!.monthly != null) {
          _packages.add(offerings.current!.monthly!);
        }

        // add annual package if available
        if (offerings.current!.annual != null) {
          _packages.add(offerings.current!.annual!);
        }

        emit(OfferingsLoaded(_packages));
      } else {
        // no offerings available
        _packages = [];
        emit(const OfferingsLoaded([]));
      }
    } catch (e) {
      emit(OfferingsError(e.toString()));
    }
  }

  // PURCHASE PACKAGE
  Future<void> purchasePackage(Package package, VoidCallback onSuccess) async {
    emit(const PurchaseLoading());
    try {
      final customerInfo = await _purchasePackage(package);

      // successful purchase
      if (customerInfo != null &&
          customerInfo.entitlements.active.containsKey('pro')) {
        // after purchase, call onSuccess to let app know user successfully
        // purchased.
        onSuccess();
      } else {
        // user cancelled purchase flow
        // revert to last known offerings
        emit(OfferingsLoaded(_packages));
      }
    } on PlatformException catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError.name) {
        // user cancelled purchase flow
        // revert to last known offerings
        emit(OfferingsLoaded(_packages));
      } else {
        emit(PurchaseError(e.toString()));
      }
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }
}
