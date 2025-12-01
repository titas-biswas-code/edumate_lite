import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages installed embedding models (similar to flutter_gemma)
class EmbeddingModelManager {
  static EmbeddingModelManager? _instance;
  static EmbeddingModelManager get instance =>
      _instance ??= EmbeddingModelManager._();

  EmbeddingModelManager._();

  static const String _keyActiveModelPath = 'embedding_gemma_active_model';
  static const String _keyActiveTokenizerPath =
      'embedding_gemma_active_tokenizer';
  static const String _keyModelDimension = 'embedding_gemma_dimension';

  /// Get storage directory for embedding models
  Future<Directory> getModelDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/embedding_models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  /// Set the active embedding model
  Future<void> setActiveModel({
    required String modelPath,
    required String tokenizerPath,
    required int dimensions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveModelPath, modelPath);
    await prefs.setString(_keyActiveTokenizerPath, tokenizerPath);
    await prefs.setInt(_keyModelDimension, dimensions);
  }

  /// Get the active embedding model paths
  Future<Map<String, dynamic>?> getActiveModel() async {
    final prefs = await SharedPreferences.getInstance();
    final modelPath = prefs.getString(_keyActiveModelPath);
    final tokenizerPath = prefs.getString(_keyActiveTokenizerPath);
    final dimensions = prefs.getInt(_keyModelDimension);

    if (modelPath == null || tokenizerPath == null || dimensions == null) {
      return null;
    }

    // Verify files still exist
    if (!File(modelPath).existsSync() || !File(tokenizerPath).existsSync()) {
      return null;
    }

    return {
      'modelPath': modelPath,
      'tokenizerPath': tokenizerPath,
      'dimensions': dimensions,
    };
  }

  /// Check if a model is installed
  Future<bool> hasActiveModel() async {
    final active = await getActiveModel();
    return active != null;
  }

  /// Clear active model
  Future<void> clearActiveModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveModelPath);
    await prefs.remove(_keyActiveTokenizerPath);
    await prefs.remove(_keyModelDimension);
  }
}


