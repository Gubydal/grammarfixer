import 'package:shared_preferences/shared_preferences.dart';

class CustomDictionaryRepository {
  CustomDictionaryRepository({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;
  static const String _key = 'user_custom_dictionary';

  List<String> getWords() {
    final list = _prefs.getStringList(_key) ?? [];
    return List<String>.unmodifiable(list..sort());
  }

  Future<bool> addWord(String word) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return false;
    final current = _prefs.getStringList(_key) ?? [];
    if (!current.any((w) => w.toLowerCase() == trimmed.toLowerCase())) {
      current.add(trimmed);
      return _prefs.setStringList(_key, current);
    }
    return true;
  }

  Future<bool> removeWord(String word) async {
    final current = _prefs.getStringList(_key) ?? [];
    current.removeWhere((w) => w.toLowerCase() == word.trim().toLowerCase());
    return _prefs.setStringList(_key, current);
  }

  Future<bool> clear() async {
    return _prefs.remove(_key);
  }
}
