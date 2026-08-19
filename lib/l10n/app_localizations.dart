import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'GrammarFix'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @goPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get goPro;

  /// No description provided for @youArePro.
  ///
  /// In en, this message translates to:
  /// **'You are Pro'**
  String get youArePro;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get freePlan;

  /// No description provided for @proPlan.
  ///
  /// In en, this message translates to:
  /// **'Pro Plan'**
  String get proPlan;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @loadingOffers.
  ///
  /// In en, this message translates to:
  /// **'Loading offers…'**
  String get loadingOffers;

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Email'**
  String get signInWithEmail;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email…'**
  String get enterEmail;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get registerNow;

  /// No description provided for @signUpWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign Up with Email'**
  String get signUpWithEmail;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccountTitle;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start using {app} in seconds.'**
  String createAccountSubtitle(String app);

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @loginNow.
  ///
  /// In en, this message translates to:
  /// **'Login now'**
  String get loginNow;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Your account, your data, your app.'**
  String get loginTagline;

  /// No description provided for @pleaseCompleteFields.
  ///
  /// In en, this message translates to:
  /// **'Please enter both email & password.'**
  String get pleaseCompleteFields;

  /// No description provided for @completeAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all fields!'**
  String get completeAllFields;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match!'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Check your inbox'**
  String get passwordResetEmailSent;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @chooseNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get chooseNewPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated. You can now sign in.'**
  String get passwordUpdated;

  /// No description provided for @fillBothPasswordFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both password fields.'**
  String get fillBothPasswordFields;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get couldNotOpenLink;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {app}'**
  String homeGreeting(String app);

  /// No description provided for @homeReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to build'**
  String get homeReadyTitle;

  /// No description provided for @homeReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'This shell is ready for your app\'s main feature. Auth, Supabase, ads, and subscriptions are already wired up.'**
  String get homeReadyMessage;

  /// No description provided for @homeFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Your main feature goes here'**
  String get homeFeatureTitle;

  /// No description provided for @homeFeatureMessage.
  ///
  /// In en, this message translates to:
  /// **'Replace this section with your app\'s primary feature. The design system, state management, and services are ready.'**
  String get homeFeatureMessage;

  /// No description provided for @homeSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String homeSignedInAs(String email);

  /// No description provided for @homeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get homeGetStarted;

  /// No description provided for @homeStepOne.
  ///
  /// In en, this message translates to:
  /// **'Add your feature screens under lib/features.'**
  String get homeStepOne;

  /// No description provided for @homeStepTwo.
  ///
  /// In en, this message translates to:
  /// **'Set your plan and benefit copy in the paywall content.'**
  String get homeStepTwo;

  /// No description provided for @homeStepThree.
  ///
  /// In en, this message translates to:
  /// **'Fill dart_defines with your app\'s real service keys.'**
  String get homeStepThree;

  /// No description provided for @proCardFreeMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove ads and unlock premium features.'**
  String get proCardFreeMessage;

  /// No description provided for @proCardProMessage.
  ///
  /// In en, this message translates to:
  /// **'Ads are removed and premium features are unlocked.'**
  String get proCardProMessage;

  /// No description provided for @proCardCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get proCardCta;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock {app} Pro'**
  String paywallTitle(String app);

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get the most out of {app}.'**
  String paywallSubtitle(String app);

  /// No description provided for @benefitNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get benefitNoAds;

  /// No description provided for @benefitPremiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Premium features'**
  String get benefitPremiumFeatures;

  /// No description provided for @benefitFutureFeatures.
  ///
  /// In en, this message translates to:
  /// **'Future feature access'**
  String get benefitFutureFeatures;

  /// No description provided for @benefitPrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get benefitPrioritySupport;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @annual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annual;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get bestValue;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get perYear;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @startPro.
  ///
  /// In en, this message translates to:
  /// **'Start Pro'**
  String get startPro;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @purchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get purchasesRestored;

  /// No description provided for @noUpgradeAvailable.
  ///
  /// In en, this message translates to:
  /// **'No upgrade available'**
  String get noUpgradeAvailable;

  /// No description provided for @noUpgradeMessage.
  ///
  /// In en, this message translates to:
  /// **'Configure an offering in RevenueCat to enable Pro.'**
  String get noUpgradeMessage;

  /// No description provided for @autoRenewNote.
  ///
  /// In en, this message translates to:
  /// **'Auto-renewable. Switch plans or cancel anytime.'**
  String get autoRenewNote;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @proActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re Pro'**
  String get proActiveTitle;

  /// No description provided for @proActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Ads are off and premium features are unlocked. Thank you for your support!'**
  String get proActiveMessage;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @feedbackPrompt.
  ///
  /// In en, this message translates to:
  /// **'How is {app} working for you?'**
  String feedbackPrompt(String app);

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Share what you like or what could improve…'**
  String get feedbackHint;

  /// No description provided for @feedbackEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please write a short message.'**
  String get feedbackEmpty;

  /// No description provided for @feedbackSending.
  ///
  /// In en, this message translates to:
  /// **'Sending feedback…'**
  String get feedbackSending;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get feedbackThanks;

  /// No description provided for @feedbackError.
  ///
  /// In en, this message translates to:
  /// **'Could not send feedback. Please try again.'**
  String get feedbackError;

  /// No description provided for @rateOnGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Rate on Google Play'**
  String get rateOnGooglePlay;

  /// No description provided for @deleteAccountOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Delete account on web'**
  String get deleteAccountOnWeb;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout?'**
  String get logoutTitle;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and data. This cannot be undone.'**
  String get deleteAccountMessage;

  /// No description provided for @deleteAccountWebMessage.
  ///
  /// In en, this message translates to:
  /// **'You can also delete your account on the web at {url}.'**
  String deleteAccountWebMessage(String url);

  /// No description provided for @profileDataNote.
  ///
  /// In en, this message translates to:
  /// **'Your profile data is stored in your app\'s Supabase schema with row-level security.'**
  String get profileDataNote;

  /// No description provided for @profileManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get profileManage;

  /// No description provided for @errorSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorSomethingWentWrong;

  /// No description provided for @adBannerLabel.
  ///
  /// In en, this message translates to:
  /// **'Advertisement'**
  String get adBannerLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
