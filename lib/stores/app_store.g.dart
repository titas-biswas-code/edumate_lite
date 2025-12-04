// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AppStore on AppStoreBase, Store {
  Computed<bool>? _$isAppReadyComputed;

  @override
  bool get isAppReady => (_$isAppReadyComputed ??= Computed<bool>(
    () => super.isAppReady,
    name: 'AppStoreBase.isAppReady',
  )).value;

  late final _$themeModeAtom = Atom(
    name: 'AppStoreBase.themeMode',
    context: context,
  );

  @override
  ThemeMode get themeMode {
    _$themeModeAtom.reportRead();
    return super.themeMode;
  }

  @override
  set themeMode(ThemeMode value) {
    _$themeModeAtom.reportWrite(value, super.themeMode, () {
      super.themeMode = value;
    });
  }

  late final _$isModelsDownloadedAtom = Atom(
    name: 'AppStoreBase.isModelsDownloaded',
    context: context,
  );

  @override
  bool get isModelsDownloaded {
    _$isModelsDownloadedAtom.reportRead();
    return super.isModelsDownloaded;
  }

  @override
  set isModelsDownloaded(bool value) {
    _$isModelsDownloadedAtom.reportWrite(value, super.isModelsDownloaded, () {
      super.isModelsDownloaded = value;
    });
  }

  late final _$isEmbeddingModelReadyAtom = Atom(
    name: 'AppStoreBase.isEmbeddingModelReady',
    context: context,
  );

  @override
  bool get isEmbeddingModelReady {
    _$isEmbeddingModelReadyAtom.reportRead();
    return super.isEmbeddingModelReady;
  }

  @override
  set isEmbeddingModelReady(bool value) {
    _$isEmbeddingModelReadyAtom.reportWrite(
      value,
      super.isEmbeddingModelReady,
      () {
        super.isEmbeddingModelReady = value;
      },
    );
  }

  late final _$isInferenceModelReadyAtom = Atom(
    name: 'AppStoreBase.isInferenceModelReady',
    context: context,
  );

  @override
  bool get isInferenceModelReady {
    _$isInferenceModelReadyAtom.reportRead();
    return super.isInferenceModelReady;
  }

  @override
  set isInferenceModelReady(bool value) {
    _$isInferenceModelReadyAtom.reportWrite(
      value,
      super.isInferenceModelReady,
      () {
        super.isInferenceModelReady = value;
      },
    );
  }

  late final _$devModeEnabledAtom = Atom(
    name: 'AppStoreBase.devModeEnabled',
    context: context,
  );

  @override
  bool get devModeEnabled {
    _$devModeEnabledAtom.reportRead();
    return super.devModeEnabled;
  }

  @override
  set devModeEnabled(bool value) {
    _$devModeEnabledAtom.reportWrite(value, super.devModeEnabled, () {
      super.devModeEnabled = value;
    });
  }

  late final _$AppStoreBaseActionController = ActionController(
    name: 'AppStoreBase',
    context: context,
  );

  @override
  void setThemeMode(ThemeMode mode) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
      name: 'AppStoreBase.setThemeMode',
    );
    try {
      return super.setThemeMode(mode);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setModelsDownloaded(bool value) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
      name: 'AppStoreBase.setModelsDownloaded',
    );
    try {
      return super.setModelsDownloaded(value);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEmbeddingModelReady(bool value) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
      name: 'AppStoreBase.setEmbeddingModelReady',
    );
    try {
      return super.setEmbeddingModelReady(value);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setInferenceModelReady(bool value) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
      name: 'AppStoreBase.setInferenceModelReady',
    );
    try {
      return super.setInferenceModelReady(value);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDevModeEnabled(bool value) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
      name: 'AppStoreBase.setDevModeEnabled',
    );
    try {
      return super.setDevModeEnabled(value);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
themeMode: ${themeMode},
isModelsDownloaded: ${isModelsDownloaded},
isEmbeddingModelReady: ${isEmbeddingModelReady},
isInferenceModelReady: ${isInferenceModelReady},
devModeEnabled: ${devModeEnabled},
isAppReady: ${isAppReady}
    ''';
  }
}
