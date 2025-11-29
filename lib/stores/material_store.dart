import 'package:mobx/mobx.dart';
import '../domain/entities/material.dart';
import '../domain/services/material_processor.dart';
import '../infrastructure/database/objectbox.dart';
import '../config/service_locator.dart';

part 'material_store.g.dart';

class MaterialStore = MaterialStoreBase with _$MaterialStore;

abstract class MaterialStoreBase with Store {
  final MaterialProcessor _materialProcessor = getIt<MaterialProcessor>();
  final ObjectBoxManager _objectBox = getIt<ObjectBoxManager>();

  @observable
  ObservableList<Material> materials = ObservableList<Material>();

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @action
  void clearError() {
    error = null;
  }

  @observable
  ProcessingProgress? currentProgress;

  @observable
  Material? processingMaterial;

  @action
  Future<void> loadMaterials() async {
    isLoading = true;
    error = null;

    try {
      final allMaterials = _objectBox.materialBox.getAll();
      materials = ObservableList.of(allMaterials);
      isLoading = false;
    } catch (e) {
      error = 'Failed to load materials: $e';
      isLoading = false;
    }
  }

  @action
  Future<void> processMaterial(MaterialInput input) async {
    isLoading = true;
    error = null;
    currentProgress = null;
    processingMaterial = null;

    try {
      // Process in background - don't block UI
      _materialProcessor.process(input).listen(
        (progress) {
          currentProgress = progress;
          processingMaterial = progress.material;

          if (progress.error != null) {
            error = progress.error;
            isLoading = false;
            currentProgress = null;
            return;
          }

          if (progress.isComplete && progress.result != null) {
            // Add to list
            final existingIndex = materials.indexWhere((m) => m.id == progress.result!.id);
            if (existingIndex >= 0) {
              materials[existingIndex] = progress.result!;
            } else {
              materials.add(progress.result!);
            }
            
            isLoading = false;
            currentProgress = null;
            processingMaterial = null;
          }
        },
        onError: (e) {
          error = 'Processing failed: $e';
          isLoading = false;
          currentProgress = null;
        },
        cancelOnError: false,
      );
      
      // Return immediately - processing continues in background
    } catch (e) {
      error = 'Processing failed: $e';
      isLoading = false;
      currentProgress = null;
    }
  }

  @action
  Future<void> deleteMaterial(int materialId) async {
    isLoading = true;
    error = null;

    final result = await _materialProcessor.deleteMaterial(materialId);

    result.fold(
      (failure) {
        error = failure.message;
        isLoading = false;
      },
      (_) {
        materials.removeWhere((m) => m.id == materialId);
        isLoading = false;
      },
    );
  }

  @action
  Future<void> reprocessMaterial(int materialId) async {
    isLoading = true;
    error = null;
    currentProgress = null;

    try {
      await for (final progress in _materialProcessor.reprocess(materialId)) {
        currentProgress = progress;

        if (progress.error != null) {
          error = progress.error;
          isLoading = false;
          return;
        }

        if (progress.isComplete && progress.result != null) {
          final index = materials.indexWhere((m) => m.id == progress.result!.id);
          if (index >= 0) {
            materials[index] = progress.result!;
          }
          
          isLoading = false;
          currentProgress = null;
          return;
        }
      }
    } catch (e) {
      error = 'Reprocessing failed: $e';
      isLoading = false;
      currentProgress = null;
    }
  }

  @computed
  List<Material> get completedMaterials =>
      materials.where((m) => m.status == 'completed').toList();

  @computed
  List<Material> get failedMaterials =>
      materials.where((m) => m.status == 'failed').toList();

  @computed
  List<Material> get processingMaterials =>
      materials.where((m) => m.status == 'processing').toList();

  @computed
  int get totalChunks =>
      materials.fold(0, (sum, m) => sum + m.chunkCount);
}

