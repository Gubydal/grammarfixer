import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/language.dart';
import '../../domain/entities/writing_style_profile.dart';

/// Repository managing on-device personal style learning and privacy settings.
///
/// CRITICAL PRIVACY INVARIANT:
/// 1. Stored exclusively in local SharedPreferences. Zero remote telemetry.
/// 2. In Private Mode, no style decisions are recorded.
class PersonalStyleRepository {
  static const _profileKey = 'grammarfix_writing_style_profile';
  static const _privateModeKey = 'grammarfix_private_mode_enabled';
  static const _autoFixKey = 'grammarfix_autofix_obvious_mistakes';

  final SharedPreferences _prefs;
  WritingStyleProfile _cachedProfile;
  bool _isPrivateMode;
  bool _isAutoFixEnabled;

  PersonalStyleRepository(this._prefs)
      : _cachedProfile = const WritingStyleProfile(),
        _isPrivateMode = false,
        _isAutoFixEnabled = false {
    _init();
  }

  void _init() {
    final rawJson = _prefs.getString(_profileKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      _cachedProfile = WritingStyleProfile.fromJson(rawJson);
    }
    _isPrivateMode = _prefs.getBool(_privateModeKey) ?? false;
    _isAutoFixEnabled = _prefs.getBool(_autoFixKey) ?? false;
  }

  WritingStyleProfile get profile => _cachedProfile;
  bool get isPrivateMode => _isPrivateMode;
  bool get isAutoFixEnabled => _isAutoFixEnabled;

  Future<void> setPrivateMode(bool enabled) async {
    _isPrivateMode = enabled;
    await _prefs.setBool(_privateModeKey, enabled);
  }

  Future<void> setAutoFixEnabled(bool enabled) async {
    _isAutoFixEnabled = enabled;
    await _prefs.setBool(_autoFixKey, enabled);
  }

  Future<void> updateDialect(EnglishDialect dialect) async {
    _cachedProfile = _cachedProfile.copyWith(dialect: dialect);
    await _saveProfile();
  }

  Future<void> setPreferredTerm(String original, String preferred) async {
    if (_isPrivateMode) return; // Do not learn in private mode

    final updated = Map<String, String>.from(_cachedProfile.preferredTerms);
    updated[original.toLowerCase().trim()] = preferred.trim();
    _cachedProfile = _cachedProfile.copyWith(preferredTerms: updated);
    await _saveProfile();
  }

  Future<void> recordStyleDecision({
    required String original,
    required String suggestion,
    required bool isAccepted,
  }) async {
    if (_isPrivateMode) return; // Paused in Private Mode

    final patternKey = '${original.toLowerCase().trim()}->${suggestion.toLowerCase().trim()}';
    final accepted = Set<String>.from(_cachedProfile.acceptedStylePatterns);
    final rejected = Set<String>.from(_cachedProfile.rejectedStylePatterns);

    if (isAccepted) {
      accepted.add(patternKey);
      rejected.remove(patternKey);
    } else {
      rejected.add(patternKey);
      accepted.remove(patternKey);
    }

    _cachedProfile = _cachedProfile.copyWith(
      acceptedStylePatterns: accepted,
      rejectedStylePatterns: rejected,
    );
    await _saveProfile();
  }

  Future<void> resetProfile() async {
    _cachedProfile = const WritingStyleProfile();
    await _prefs.remove(_profileKey);
  }

  Future<void> _saveProfile() async {
    await _prefs.setString(_profileKey, _cachedProfile.toJson());
  }
}
