// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'GrammarFix';

  @override
  String get home => 'Correct';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get goPro => 'Go Pro';

  @override
  String get youArePro => 'You are Pro';

  @override
  String get freePlan => 'Free Plan';

  @override
  String get proPlan => 'Pro Plan';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get or => 'or';

  @override
  String get loading => 'Loading…';

  @override
  String get loadingOffers => 'Loading offers…';

  @override
  String get signInWithEmail => 'Sign In with Email';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get forgotPasswordTitle => 'Forgot Password?';

  @override
  String get enterEmail => 'Enter email…';

  @override
  String get reset => 'Reset';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get registerNow => 'Register now';

  @override
  String get signUpWithEmail => 'Sign Up with Email';

  @override
  String get createAccountTitle => 'Create your account';

  @override
  String createAccountSubtitle(String app) {
    return 'Start using $app in seconds.';
  }

  @override
  String get name => 'Name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginNow => 'Login now';

  @override
  String get loginTagline => 'Your account, your data, your app.';

  @override
  String get pleaseCompleteFields => 'Please enter both email & password.';

  @override
  String get completeAllFields => 'Please complete all fields!';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match!';

  @override
  String get passwordResetEmailSent =>
      'Password reset email sent! Check your inbox';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get chooseNewPassword => 'Choose a new password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordUpdated => 'Password updated. You can now sign in.';

  @override
  String get fillBothPasswordFields => 'Please fill in both password fields.';

  @override
  String get couldNotOpenLink => 'Could not open the link.';

  @override
  String homeGreeting(String app) {
    return 'Welcome to $app';
  }

  @override
  String get homeReadyTitle => 'Ready to build';

  @override
  String get homeReadyMessage =>
      'This shell is ready for your app\'s main feature. Auth, Supabase, ads, and subscriptions are already wired up.';

  @override
  String get homeFeatureTitle => 'Your main feature goes here';

  @override
  String get homeFeatureMessage =>
      'Replace this section with your app\'s primary feature. The design system, state management, and services are ready.';

  @override
  String homeSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get homeGetStarted => 'Get started';

  @override
  String get homeStepOne => 'Add your feature screens under lib/features.';

  @override
  String get homeStepTwo =>
      'Set your plan and benefit copy in the paywall content.';

  @override
  String get homeStepThree =>
      'Fill dart_defines with your app\'s real service keys.';

  @override
  String get proCardFreeMessage => 'Remove ads and unlock premium features.';

  @override
  String get proCardProMessage =>
      'Ads are removed and premium features are unlocked.';

  @override
  String get proCardCta => 'Upgrade';

  @override
  String paywallTitle(String app) {
    return 'Unlock $app Pro';
  }

  @override
  String paywallSubtitle(String app) {
    return 'Get the most out of $app.';
  }

  @override
  String get benefitNoAds => 'No ads';

  @override
  String get benefitPremiumFeatures => 'Premium features';

  @override
  String get benefitFutureFeatures => 'Future feature access';

  @override
  String get benefitPrioritySupport => 'Priority support';

  @override
  String get monthly => 'Monthly';

  @override
  String get annual => 'Annual';

  @override
  String get bestValue => 'Best value';

  @override
  String get perMonth => '/month';

  @override
  String get perYear => '/year';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get startPro => 'Start Pro';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get purchasesRestored => 'Purchases restored.';

  @override
  String get noUpgradeAvailable => 'No upgrade available';

  @override
  String get noUpgradeMessage =>
      'Configure an offering in RevenueCat to enable Pro.';

  @override
  String get autoRenewNote => 'Auto-renewable. Switch plans or cancel anytime.';

  @override
  String get terms => 'Terms';

  @override
  String get privacy => 'Privacy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get proActiveTitle => 'You\'re Pro';

  @override
  String get proActiveMessage =>
      'Ads are off and premium features are unlocked. Thank you for your support!';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String feedbackPrompt(String app) {
    return 'How is $app working for you?';
  }

  @override
  String get feedbackHint => 'Share what you like or what could improve…';

  @override
  String get feedbackEmpty => 'Please write a short message.';

  @override
  String get feedbackSending => 'Sending feedback…';

  @override
  String get feedbackThanks => 'Thank you for your feedback!';

  @override
  String get feedbackError => 'Could not send feedback. Please try again.';

  @override
  String get rateOnGooglePlay => 'Rate on Google Play';

  @override
  String get deleteAccountOnWeb => 'Delete account on web';

  @override
  String get logout => 'Logout';

  @override
  String get logoutTitle => 'Logout?';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete Account?';

  @override
  String get deleteAccountMessage =>
      'This permanently deletes your account and data. This cannot be undone.';

  @override
  String deleteAccountWebMessage(String url) {
    return 'You can also delete your account on the web at $url.';
  }

  @override
  String get profileDataNote =>
      'Your profile data is stored in your app\'s Supabase schema with row-level security.';

  @override
  String get profileManage => 'Manage';

  @override
  String get errorSomethingWentWrong => 'Something went wrong.';

  @override
  String get adBannerLabel => 'Advertisement';
}
