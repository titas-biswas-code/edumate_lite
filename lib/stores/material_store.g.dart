// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MaterialStore on MaterialStoreBase, Store {
  Computed<List<Material>>? _$completedMaterialsComputed;

  @override
  List<Material> get completedMaterials =>
      (_$completedMaterialsComputed ??= Computed<List<Material>>(
        () => super.completedMaterials,
        name: 'MaterialStoreBase.completedMaterials',
      )).value;
  Computed<List<Material>>? _$failedMaterialsComputed;

  @override
  List<Material> get failedMaterials =>
      (_$failedMaterialsComputed ??= Computed<List<Material>>(
        () => super.failedMaterials,
        name: 'MaterialStoreBase.failedMaterials',
      )).value;
  Computed<List<Material>>? _$processingMaterialsComputed;

  @override
  List<Material> get processingMaterials =>
      (_$processingMaterialsComputed ??= Computed<List<Material>>(
        () => super.processingMaterials,
        name: 'MaterialStoreBase.processingMaterials',
      )).value;
  Computed<int>? _$totalChunksComputed;

  @override
  int get totalChunks => (_$totalChunksComputed ??= Computed<int>(
    () => super.totalChunks,
    name: 'MaterialStoreBase.totalChunks',
  )).value;

  late final _$materialsAtom = Atom(
    name: 'MaterialStoreBase.materials',
    context: context,
  );

  @override
  ObservableList<Material> get materials {
    _$materialsAtom.reportRead();
    return super.materials;
  }

  @override
  set materials(ObservableList<Material> value) {
    _$materialsAtom.reportWrite(value, super.materials, () {
      super.materials = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: 'MaterialStoreBase.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'MaterialStoreBase.error',
    context: context,
  );

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$currentProgressAtom = Atom(
    name: 'MaterialStoreBase.currentProgress',
    context: context,
  );

  @override
  ProcessingProgress? get currentProgress {
    _$currentProgressAtom.reportRead();
    return super.currentProgress;
  }

  @override
  set currentProgress(ProcessingProgress? value) {
    _$currentProgressAtom.reportWrite(value, super.currentProgress, () {
      super.currentProgress = value;
    });
  }

  late final _$processingMaterialAtom = Atom(
    name: 'MaterialStoreBase.processingMaterial',
    context: context,
  );

  @override
  Material? get processingMaterial {
    _$processingMaterialAtom.reportRead();
    return super.processingMaterial;
  }

  @override
  set processingMaterial(Material? value) {
    _$processingMaterialAtom.reportWrite(value, super.processingMaterial, () {
      super.processingMaterial = value;
    });
  }

  late final _$loadMaterialsAsyncAction = AsyncAction(
    'MaterialStoreBase.loadMaterials',
    context: context,
  );

  @override
  Future<void> loadMaterials() {
    return _$loadMaterialsAsyncAction.run(() => super.loadMaterials());
  }

  late final _$processMaterialAsyncAction = AsyncAction(
    'MaterialStoreBase.processMaterial',
    context: context,
  );

  @override
  Future<void> processMaterial(MaterialInput input) {
    return _$processMaterialAsyncAction.run(() => super.processMaterial(input));
  }

  late final _$deleteMaterialAsyncAction = AsyncAction(
    'MaterialStoreBase.deleteMaterial',
    context: context,
  );

  @override
  Future<void> deleteMaterial(int materialId) {
    return _$deleteMaterialAsyncAction.run(
      () => super.deleteMaterial(materialId),
    );
  }

  late final _$reprocessMaterialAsyncAction = AsyncAction(
    'MaterialStoreBase.reprocessMaterial',
    context: context,
  );

  @override
  Future<void> reprocessMaterial(int materialId) {
    return _$reprocessMaterialAsyncAction.run(
      () => super.reprocessMaterial(materialId),
    );
  }

  late final _$MaterialStoreBaseActionController = ActionController(
    name: 'MaterialStoreBase',
    context: context,
  );

  @override
  void clearError() {
    final _$actionInfo = _$MaterialStoreBaseActionController.startAction(
      name: 'MaterialStoreBase.clearError',
    );
    try {
      return super.clearError();
    } finally {
      _$MaterialStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
materials: ${materials},
isLoading: ${isLoading},
error: ${error},
currentProgress: ${currentProgress},
processingMaterial: ${processingMaterial},
completedMaterials: ${completedMaterials},
failedMaterials: ${failedMaterials},
processingMaterials: ${processingMaterials},
totalChunks: ${totalChunks}
    ''';
  }
}
