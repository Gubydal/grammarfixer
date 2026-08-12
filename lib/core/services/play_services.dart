import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';

class PlayServices {
  PlayServices._();

  /// Checks for Google Play in-app updates. Safe to call on every launch;
  /// it is a no-op for sideloaded builds.
  static Future<void> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
      }
    } catch (_) {
      // In-app updates are only available for Play-installed builds.
    }
  }

  /// Opens the Google Play listing (not the quota-limited review prompt).
  static Future<void> openStoreListing() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.openStoreListing();
    }
  }
}
