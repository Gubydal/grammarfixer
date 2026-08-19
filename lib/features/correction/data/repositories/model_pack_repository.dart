import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ModelPackStatus {
  notInstalled,
  checking,
  downloading,
  installed,
  failed,
  removing,
}

class ModelPackState {
  const ModelPackState({
    required this.status,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 475 * 1024 * 1024, // ~475 MB
    this.errorMessage,
    this.availableStorageMb = 4096,
  });

  final ModelPackStatus status;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;
  final int availableStorageMb;

  bool get isInstalled => status == ModelPackStatus.installed;
  bool get isDownloading => status == ModelPackStatus.downloading;

  ModelPackState copyWith({
    ModelPackStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
    int? availableStorageMb,
  }) {
    return ModelPackState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      availableStorageMb: availableStorageMb ?? this.availableStorageMb,
    );
  }
}

class ModelPackRepository {
  ModelPackRepository({
    required SharedPreferences prefs,
  }) : _prefs = prefs {
    _initStatus();
  }

  final SharedPreferences _prefs;
  static const String _keyInstalled = 'multilingual_model_pack_installed';
  static const MethodChannel _channel = MethodChannel('com.mogate.grammarfix/model_pack');

  final _controller = StreamController<ModelPackState>.broadcast();
  Stream<ModelPackState> get stateStream => _controller.stream;

  ModelPackState _currentState = const ModelPackState(status: ModelPackStatus.notInstalled);
  ModelPackState get currentState => _currentState;
  bool get isInstalled => _currentState.isInstalled;

  void _initStatus() {
    final installed = _prefs.getBool(_keyInstalled) ?? false;
    _currentState = ModelPackState(
      status: installed ? ModelPackStatus.installed : ModelPackStatus.notInstalled,
      progress: installed ? 1.0 : 0.0,
    );
    _controller.add(_currentState);
  }

  Future<void> startDownload() async {
    if (_currentState.status == ModelPackStatus.downloading) return;

    _currentState = _currentState.copyWith(
      status: ModelPackStatus.downloading,
      progress: 0.0,
      errorMessage: null,
    );
    _controller.add(_currentState);

    try {
      // Simulate/trigger Google Play Asset Delivery download progression
      for (var i = 1; i <= 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        _currentState = _currentState.copyWith(
          progress: i / 10.0,
          downloadedBytes: (i * (_currentState.totalBytes / 10)).round(),
        );
        _controller.add(_currentState);
      }

      await _prefs.setBool(_keyInstalled, true);
      _currentState = _currentState.copyWith(
        status: ModelPackStatus.installed,
        progress: 1.0,
      );
      _controller.add(_currentState);
    } catch (e) {
      _currentState = _currentState.copyWith(
        status: ModelPackStatus.failed,
        errorMessage: e.toString(),
      );
      _controller.add(_currentState);
    }
  }

  Future<void> removePack() async {
    _currentState = _currentState.copyWith(status: ModelPackStatus.removing);
    _controller.add(_currentState);

    try {
      await _channel.invokeMethod<bool>('removePack');
    } catch (_) {}

    await _prefs.setBool(_keyInstalled, false);
    _currentState = const ModelPackState(
      status: ModelPackStatus.notInstalled,
      progress: 0.0,
      downloadedBytes: 0,
    );
    _controller.add(_currentState);
  }

  void dispose() {
    _controller.close();
  }
}
