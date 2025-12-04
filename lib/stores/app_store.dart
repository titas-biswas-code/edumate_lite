import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'app_store.g.dart';

class AppStore = AppStoreBase with _$AppStore;

abstract class AppStoreBase with Store {
  @observable
  ThemeMode themeMode = ThemeMode.system;

  @observable
  bool isModelsDownloaded = false;

  @observable
  bool isEmbeddingModelReady = false;

  @observable
  bool isInferenceModelReady = false;

  @observable
  bool devModeEnabled = false;

  @action
  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
  }

  @action
  void setModelsDownloaded(bool value) {
    isModelsDownloaded = value;
  }

  @action
  void setEmbeddingModelReady(bool value) {
    isEmbeddingModelReady = value;
  }

  @action
  void setInferenceModelReady(bool value) {
    isInferenceModelReady = value;
  }

  @action
  void setDevModeEnabled(bool value) {
    devModeEnabled = value;
  }

  @computed
  bool get isAppReady => isEmbeddingModelReady && isInferenceModelReady;
}

