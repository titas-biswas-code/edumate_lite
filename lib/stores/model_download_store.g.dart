// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_download_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ModelDownloadStore on ModelDownloadStoreBase, Store {
  Computed<bool>? _$isEmbeddingCompleteComputed;

  @override
  bool get isEmbeddingComplete =>
      (_$isEmbeddingCompleteComputed ??= Computed<bool>(
        () => super.isEmbeddingComplete,
        name: 'ModelDownloadStoreBase.isEmbeddingComplete',
      )).value;
  Computed<bool>? _$isInferenceCompleteComputed;

  @override
  bool get isInferenceComplete =>
      (_$isInferenceCompleteComputed ??= Computed<bool>(
        () => super.isInferenceComplete,
        name: 'ModelDownloadStoreBase.isInferenceComplete',
      )).value;
  Computed<bool>? _$areAllModelsReadyComputed;

  @override
  bool get areAllModelsReady => (_$areAllModelsReadyComputed ??= Computed<bool>(
    () => super.areAllModelsReady,
    name: 'ModelDownloadStoreBase.areAllModelsReady',
  )).value;
  Computed<String>? _$embeddingProgressTextComputed;

  @override
  String get embeddingProgressText =>
      (_$embeddingProgressTextComputed ??= Computed<String>(
        () => super.embeddingProgressText,
        name: 'ModelDownloadStoreBase.embeddingProgressText',
      )).value;
  Computed<String>? _$inferenceProgressTextComputed;

  @override
  String get inferenceProgressText =>
      (_$inferenceProgressTextComputed ??= Computed<String>(
        () => super.inferenceProgressText,
        name: 'ModelDownloadStoreBase.inferenceProgressText',
      )).value;

  late final _$embeddingStatusAtom = Atom(
    name: 'ModelDownloadStoreBase.embeddingStatus',
    context: context,
  );

  @override
  ModelDownloadStatus get embeddingStatus {
    _$embeddingStatusAtom.reportRead();
    return super.embeddingStatus;
  }

  @override
  set embeddingStatus(ModelDownloadStatus value) {
    _$embeddingStatusAtom.reportWrite(value, super.embeddingStatus, () {
      super.embeddingStatus = value;
    });
  }

  late final _$inferenceStatusAtom = Atom(
    name: 'ModelDownloadStoreBase.inferenceStatus',
    context: context,
  );

  @override
  ModelDownloadStatus get inferenceStatus {
    _$inferenceStatusAtom.reportRead();
    return super.inferenceStatus;
  }

  @override
  set inferenceStatus(ModelDownloadStatus value) {
    _$inferenceStatusAtom.reportWrite(value, super.inferenceStatus, () {
      super.inferenceStatus = value;
    });
  }

  late final _$embeddingProgressAtom = Atom(
    name: 'ModelDownloadStoreBase.embeddingProgress',
    context: context,
  );

  @override
  double get embeddingProgress {
    _$embeddingProgressAtom.reportRead();
    return super.embeddingProgress;
  }

  @override
  set embeddingProgress(double value) {
    _$embeddingProgressAtom.reportWrite(value, super.embeddingProgress, () {
      super.embeddingProgress = value;
    });
  }

  late final _$inferenceProgressAtom = Atom(
    name: 'ModelDownloadStoreBase.inferenceProgress',
    context: context,
  );

  @override
  double get inferenceProgress {
    _$inferenceProgressAtom.reportRead();
    return super.inferenceProgress;
  }

  @override
  set inferenceProgress(double value) {
    _$inferenceProgressAtom.reportWrite(value, super.inferenceProgress, () {
      super.inferenceProgress = value;
    });
  }

  late final _$embeddingErrorAtom = Atom(
    name: 'ModelDownloadStoreBase.embeddingError',
    context: context,
  );

  @override
  String? get embeddingError {
    _$embeddingErrorAtom.reportRead();
    return super.embeddingError;
  }

  @override
  set embeddingError(String? value) {
    _$embeddingErrorAtom.reportWrite(value, super.embeddingError, () {
      super.embeddingError = value;
    });
  }

  late final _$inferenceErrorAtom = Atom(
    name: 'ModelDownloadStoreBase.inferenceError',
    context: context,
  );

  @override
  String? get inferenceError {
    _$inferenceErrorAtom.reportRead();
    return super.inferenceError;
  }

  @override
  set inferenceError(String? value) {
    _$inferenceErrorAtom.reportWrite(value, super.inferenceError, () {
      super.inferenceError = value;
    });
  }

  late final _$embeddingBytesDownloadedAtom = Atom(
    name: 'ModelDownloadStoreBase.embeddingBytesDownloaded',
    context: context,
  );

  @override
  int? get embeddingBytesDownloaded {
    _$embeddingBytesDownloadedAtom.reportRead();
    return super.embeddingBytesDownloaded;
  }

  @override
  set embeddingBytesDownloaded(int? value) {
    _$embeddingBytesDownloadedAtom.reportWrite(
      value,
      super.embeddingBytesDownloaded,
      () {
        super.embeddingBytesDownloaded = value;
      },
    );
  }

  late final _$embeddingTotalBytesAtom = Atom(
    name: 'ModelDownloadStoreBase.embeddingTotalBytes',
    context: context,
  );

  @override
  int? get embeddingTotalBytes {
    _$embeddingTotalBytesAtom.reportRead();
    return super.embeddingTotalBytes;
  }

  @override
  set embeddingTotalBytes(int? value) {
    _$embeddingTotalBytesAtom.reportWrite(value, super.embeddingTotalBytes, () {
      super.embeddingTotalBytes = value;
    });
  }

  late final _$inferenceBytesDownloadedAtom = Atom(
    name: 'ModelDownloadStoreBase.inferenceBytesDownloaded',
    context: context,
  );

  @override
  int? get inferenceBytesDownloaded {
    _$inferenceBytesDownloadedAtom.reportRead();
    return super.inferenceBytesDownloaded;
  }

  @override
  set inferenceBytesDownloaded(int? value) {
    _$inferenceBytesDownloadedAtom.reportWrite(
      value,
      super.inferenceBytesDownloaded,
      () {
        super.inferenceBytesDownloaded = value;
      },
    );
  }

  late final _$inferenceTotalBytesAtom = Atom(
    name: 'ModelDownloadStoreBase.inferenceTotalBytes',
    context: context,
  );

  @override
  int? get inferenceTotalBytes {
    _$inferenceTotalBytesAtom.reportRead();
    return super.inferenceTotalBytes;
  }

  @override
  set inferenceTotalBytes(int? value) {
    _$inferenceTotalBytesAtom.reportWrite(value, super.inferenceTotalBytes, () {
      super.inferenceTotalBytes = value;
    });
  }

  late final _$ModelDownloadStoreBaseActionController = ActionController(
    name: 'ModelDownloadStoreBase',
    context: context,
  );

  @override
  void setEmbeddingStatus(ModelDownloadStatus status) {
    final _$actionInfo = _$ModelDownloadStoreBaseActionController.startAction(
      name: 'ModelDownloadStoreBase.setEmbeddingStatus',
    );
    try {
      return super.setEmbeddingStatus(status);
    } finally {
      _$ModelDownloadStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setInferenceStatus(ModelDownloadStatus status) {
    final _$actionInfo = _$ModelDownloadStoreBaseActionController.startAction(
      name: 'ModelDownloadStoreBase.setInferenceStatus',
    );
    try {
      return super.setInferenceStatus(status);
    } finally {
      _$ModelDownloadStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEmbeddingProgress(double progress) {
    final _$actionInfo = _$ModelDownloadStoreBaseActionController.startAction(
      name: 'ModelDownloadStoreBase.setEmbeddingProgress',
    );
    try {
      return super.setEmbeddingProgress(progress);
    } finally {
      _$ModelDownloadStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setInferenceProgress(double progress) {
    final _$actionInfo = _$ModelDownloadStoreBaseActionController.startAction(
      name: 'ModelDownloadStoreBase.setInferenceProgress',
    );
    try {
      return super.setInferenceProgress(progress);
    } finally {
      _$ModelDownloadStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEmbeddingError(String? error) {
    final _$actionInfo = _$ModelDownloadStoreBaseActionController.startAction(
      name: 'ModelDownloadStoreBase.setEmbeddingError',
    );
    try {
      return super.setEmbeddingError(error);
    } finally {
      _$ModelDownloadStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setInferenceError(String? error) {
    final _$actionInfo = _$ModelDownloadStoreBaseActionController.startAction(
      name: 'ModelDownloadStoreBase.setInferenceError',
    );
    try {
      return super.setInferenceError(error);
    } finally {
      _$ModelDownloadStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateEmbeddingBytes(int downloaded, int total) {
    final _$actionInfo = _$ModelDownloadStoreBaseActionController.startAction(
      name: 'ModelDownloadStoreBase.updateEmbeddingBytes',
    );
    try {
      return super.updateEmbeddingBytes(downloaded, total);
    } finally {
      _$ModelDownloadStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateInferenceBytes(int downloaded, int total) {
    final _$actionInfo = _$ModelDownloadStoreBaseActionController.startAction(
      name: 'ModelDownloadStoreBase.updateInferenceBytes',
    );
    try {
      return super.updateInferenceBytes(downloaded, total);
    } finally {
      _$ModelDownloadStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
embeddingStatus: ${embeddingStatus},
inferenceStatus: ${inferenceStatus},
embeddingProgress: ${embeddingProgress},
inferenceProgress: ${inferenceProgress},
embeddingError: ${embeddingError},
inferenceError: ${inferenceError},
embeddingBytesDownloaded: ${embeddingBytesDownloaded},
embeddingTotalBytes: ${embeddingTotalBytes},
inferenceBytesDownloaded: ${inferenceBytesDownloaded},
inferenceTotalBytes: ${inferenceTotalBytes},
isEmbeddingComplete: ${isEmbeddingComplete},
isInferenceComplete: ${isInferenceComplete},
areAllModelsReady: ${areAllModelsReady},
embeddingProgressText: ${embeddingProgressText},
inferenceProgressText: ${inferenceProgressText}
    ''';
  }
}
