import 'package:flutter/widgets.dart';
import 'package:app_starter/l10n/app_localizations.dart';

extension L10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
