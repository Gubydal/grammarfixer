import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/model_pack_repository.dart';

class ModelPackCubit extends Cubit<ModelPackState> {
  ModelPackCubit({
    required ModelPackRepository repository,
  })  : _repo = repository,
        super(repository.currentState) {
    _subscription = _repo.stateStream.listen(emit);
  }

  final ModelPackRepository _repo;
  StreamSubscription<ModelPackState>? _subscription;

  Future<void> downloadPack() async {
    await _repo.startDownload();
  }

  Future<void> removePack() async {
    await _repo.removePack();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
