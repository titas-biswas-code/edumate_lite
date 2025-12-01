import 'dart:io';
import 'package:flutter/services.dart';
import 'model_manager.dart';

/// Fluent builder for embedding model installation
class EmbeddingInstallationBuilder {
  String? _modelAssetPath;
  String? _tokenizerAssetPath;
  int _dimensions = 768;
  void Function(double progress)? _onProgress;

  EmbeddingInstallationBuilder modelFromAsset(String assetPath) {
    _modelAssetPath = assetPath;
    return this;
  }

  EmbeddingInstallationBuilder tokenizerFromAsset(String assetPath) {
    _tokenizerAssetPath = assetPath;
    return this;
  }

  EmbeddingInstallationBuilder withProgress(void Function(double progress) onProgress) {
    _onProgress = onProgress;
    return this;
  }

  /// Execute installation - copies assets to app storage
  Future<EmbeddingInstallation> install() async {
    if (_modelAssetPath == null || _tokenizerAssetPath == null) {
      throw StateError(
        'Both model and tokenizer required. Use modelFromAsset() and tokenizerFromAsset().',
      );
    }

    final manager = EmbeddingModelManager.instance;
    final modelDir = await manager.getModelDirectory();

    final modelFileName = _modelAssetPath!.split('/').last;
    final tokenizerFileName = _tokenizerAssetPath!.split('/').last;

    final modelPath = '${modelDir.path}/$modelFileName';
    final tokenizerPath = '${modelDir.path}/$tokenizerFileName';

    print('[EmbeddingGemma] Installing models to: ${modelDir.path}');
    
    // Install model (80% of progress)
    if (!File(modelPath).existsSync()) {
      await _copyAssetToFile(_modelAssetPath!, modelPath, (p) {
        _onProgress?.call(p * 0.8);
      });
    } else {
      _onProgress?.call(0.8);
    }

    // Install tokenizer (20% of progress)
    if (!File(tokenizerPath).existsSync()) {
      await _copyAssetToFile(_tokenizerAssetPath!, tokenizerPath, (p) {
        _onProgress?.call(0.8 + (p * 0.2));
      });
    } else {
      _onProgress?.call(1.0);
    }

    // Set as active model
    await manager.setActiveModel(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      dimensions: _dimensions,
    );
    
    _onProgress?.call(1.0);

    return EmbeddingInstallation(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      dimensions: _dimensions,
    );
  }

  Future<void> _copyAssetToFile(
    String assetPath,
    String destPath,
    void Function(double progress) onProgress,
  ) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    
    final file = File(destPath);
    await file.parent.create(recursive: true);
    
    final outputSink = file.openWrite();
    const chunkSize = 1024 * 1024; // 1MB chunks
    
    for (int i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      outputSink.add(bytes.sublist(i, end));
      onProgress(end / bytes.length);
    }
    
    await outputSink.close();
    onProgress(1.0);
  }
}

/// Result of embedding model installation
class EmbeddingInstallation {
  final String modelPath;
  final String tokenizerPath;
  final int dimensions;

  EmbeddingInstallation({
    required this.modelPath,
    required this.tokenizerPath,
    required this.dimensions,
  });
}
