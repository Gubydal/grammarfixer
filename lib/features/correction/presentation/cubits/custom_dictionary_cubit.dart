import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/custom_dictionary_repository.dart';

class CustomDictionaryState {
  const CustomDictionaryState({
    required this.words,
    this.searchQuery = '',
  });

  final List<String> words;
  final String searchQuery;

  List<String> get filteredWords {
    if (searchQuery.trim().isEmpty) return words;
    return words.where((w) => w.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }
}

class CustomDictionaryCubit extends Cubit<CustomDictionaryState> {
  CustomDictionaryCubit({
    required CustomDictionaryRepository repository,
  })  : _repo = repository,
        super(CustomDictionaryState(words: repository.getWords()));

  final CustomDictionaryRepository _repo;

  void loadWords() {
    emit(CustomDictionaryState(
      words: _repo.getWords(),
      searchQuery: state.searchQuery,
    ));
  }

  void search(String query) {
    emit(CustomDictionaryState(
      words: state.words,
      searchQuery: query,
    ));
  }

  Future<void> addWord(String word) async {
    await _repo.addWord(word);
    loadWords();
  }

  Future<void> removeWord(String word) async {
    await _repo.removeWord(word);
    loadWords();
  }

  Future<void> clearAll() async {
    await _repo.clear();
    loadWords();
  }
}
