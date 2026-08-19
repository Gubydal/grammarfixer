// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'GrammarFix';

  @override
  String get home => 'تصحيح';

  @override
  String get profile => 'الحساب';

  @override
  String get settings => 'الإعدادات';

  @override
  String get upgrade => 'ترقية';

  @override
  String get upgradeToPro => 'الترقية إلى برو';

  @override
  String get goPro => 'اشترك في برو';

  @override
  String get youArePro => 'أنت مشترك في برو';

  @override
  String get freePlan => 'الخطة المجانية';

  @override
  String get proPlan => 'خطة برو';

  @override
  String get currentPlan => 'الخطة الحالية';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get close => 'إغلاق';

  @override
  String get or => 'أو';

  @override
  String get loading => 'جار التحميل…';

  @override
  String get loadingOffers => 'جار تحميل العروض…';

  @override
  String get signInWithEmail => 'تسجيل الدخول بالبريد';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get forgotPasswordTitle => 'استعادة كلمة المرور';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني…';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get registerNow => 'أنشئ حساباً الآن';

  @override
  String get signUpWithEmail => 'إنشاء حساب بالبريد';

  @override
  String get createAccountTitle => 'إنشاء حسابك';

  @override
  String createAccountSubtitle(String app) {
    return 'ابدأ استخدام $app في ثوانٍ.';
  }

  @override
  String get name => 'الاسم';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get loginNow => 'تسجيل الدخول';

  @override
  String get loginTagline => 'كتابتك تبقى دائماً على جهازك.';

  @override
  String get pleaseCompleteFields => 'يرجى ملء جميع الحقول المطلوبة.';

  @override
  String get completeAllFields => 'يرجى ملء جميع الحقول!';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين!';

  @override
  String get passwordResetEmailSent =>
      'تم إرسال رابط استعادة كلمة المرور إلى بريدك.';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get chooseNewPassword => 'اختر كلمة مرور جديدة';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get updatePassword => 'تحديث كلمة المرور';

  @override
  String get passwordUpdated => 'تم تحديث كلمة المرور بنجاح.';

  @override
  String get fillBothPasswordFields => 'يرجى ملء حقلي كلمة المرور.';

  @override
  String get couldNotOpenLink => 'تعذر فتح الرابط.';

  @override
  String homeGreeting(String app) {
    return 'مرحباً بك في $app';
  }

  @override
  String get homeReadyTitle => 'تصحيح خصوصي فوري';

  @override
  String get homeReadyMessage =>
      'كل النصوص تعالج محلياً على جهازك دون اتصال بالسحابة.';

  @override
  String get homeFeatureTitle => 'المصحح اللغوي المحلي';

  @override
  String get homeFeatureMessage => 'الصق أو اكتب النص وصححه بضغطة زر واحدة.';

  @override
  String homeSignedInAs(String email) {
    return 'مسجل كـ $email';
  }

  @override
  String get homeGetStarted => 'ابدأ الآن';

  @override
  String get homeStepOne => 'اختر لغة النص أو دع المصحح يكتشفها تلقائياً.';

  @override
  String get homeStepTwo => 'اضغط على تصحيح لرؤية التغييرات فوراً.';

  @override
  String get homeStepThree => 'طبق التعديلات أو انسخ النص بضغطة زر.';

  @override
  String get proCardFreeMessage => 'تخلص من الإعلانات تماماً.';

  @override
  String get proCardProMessage => 'تمت إزالة الإعلانات بنجاح.';

  @override
  String get proCardCta => 'ترقية';

  @override
  String paywallTitle(String app) {
    return 'ترقية $app';
  }

  @override
  String paywallSubtitle(String app) {
    return 'استمتع بتجربة كتابة خالية تماماً من الإعلانات.';
  }

  @override
  String get benefitNoAds => 'بدون إعلانات';

  @override
  String get benefitPremiumFeatures => 'دعم التطوير المحلي';

  @override
  String get benefitFutureFeatures => 'سرعة فائقة';

  @override
  String get benefitPrioritySupport => 'دعم مستمر';

  @override
  String get monthly => 'شهرياً';

  @override
  String get annual => 'سنوياً';

  @override
  String get bestValue => 'أفضل قيمة';

  @override
  String get perMonth => '/month';

  @override
  String get perYear => '/year';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get startPro => 'ابدأ برو';

  @override
  String get restorePurchases => 'استعادة المشتريات';

  @override
  String get purchasesRestored => 'تمت استعادة المشتريات بنجاح.';

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
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get proActiveTitle => 'You\'re Pro';

  @override
  String get proActiveMessage =>
      'Ads are off and premium features are unlocked. Thank you for your support!';

  @override
  String get sendFeedback => 'إرسال ملاحظات';

  @override
  String feedbackPrompt(String app) {
    return 'كيف ترى تجربة $app؟';
  }

  @override
  String get feedbackHint => 'شاركنا رأيك أو اقتراحاتك…';

  @override
  String get feedbackEmpty => 'يرجى كتابة رسالة قبل الإرسال.';

  @override
  String get feedbackSending => 'جار إرسال الملاحظات…';

  @override
  String get feedbackThanks => 'شكراً جزيلاً لملاحظاتك!';

  @override
  String get feedbackError => 'تعذر إرسال الملاحظات. حاول لاحقاً.';

  @override
  String get rateOnGooglePlay => 'Rate on Google Play';

  @override
  String get deleteAccountOnWeb => 'Delete account on web';

  @override
  String get logout => 'Logout';

  @override
  String get logoutTitle => 'Logout?';

  @override
  String get deleteAccount => 'حذف الحساب';

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
