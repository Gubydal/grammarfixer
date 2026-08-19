import 'package:shared_preferences/shared_preferences.dart';

class DraftRepository {
  DraftRepository({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _keyDraftPersistenceEnabled = 'save_draft_locally_enabled';
  static const String _keyDraftContent = 'editor_saved_draft';

  bool get isPersistenceEnabled => _prefs.getBool(_keyDraftPersistenceEnabled) ?? false;

  Future<bool> setPersistenceEnabled(bool enabled) async {
    final success = await _prefs.setBool(_keyDraftPersistenceEnabled, enabled);
    if (!enabled) {
      await clearDraft();
    }
    return success;
  }

  String? getDraft() {
    if (!isPersistenceEnabled) return null;
    return _prefs.getString(_keyDraftContent);
  }

  Future<bool> saveDraft(String text) async {
    if (!isPersistenceEnabled) return false;
    return _prefs.setString(_keyDraftContent, text);
  }

  Future<bool> clearDraft() async {
    return _prefs.remove(_keyDraftContent);
  }
}
