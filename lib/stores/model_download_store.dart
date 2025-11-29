import 'package:mobx/mobx.dart';

part 'model_download_store.g.dart';

class ModelDownloadStore = ModelDownloadStoreBase with _$ModelDownloadStore;

enum ModelDownloadStatus {
  notStarted,
  checkingStorage,
  downloading,
  paused,
  failed,
  completed,
  initializing,
}

abstract class ModelDownloadStoreBase with Store {
  @observable
  ModelDownloadStatus embeddingStatus = ModelDownloadStatus.notStarted;

  @observable
  ModelDownloadStatus inferenceStatus = ModelDownloadStatus.notStarted;

  @observable
  double embeddingProgress = 0.0;

  @observable
  double inferenceProgress = 0.0;

  @observable
  String? embeddingError;

  @observable
  String? inferenceError;

  @observable
  int? embeddingBytesDownloaded;

  @observable
  int? embeddingTotalBytes;

  @observable
  int? inferenceBytesDownloaded;

  @observable
  int? inferenceTotalBytes;

  @action
  void setEmbeddingStatus(ModelDownloadStatus status) {
    embeddingStatus = status;
  }

  @action
  void setInferenceStatus(ModelDownloadStatus status) {
    inferenceStatus = status;
  }

  @action
  void setEmbeddingProgress(double progress) {
    embeddingProgress = progress;
  }

  @action
  void setInferenceProgress(double progress) {
    inferenceProgress = progress;
  }

  @action
  void setEmbeddingError(String? error) {
    embeddingError = error;
  }

  @action
  void setInferenceError(String? error) {
    inferenceError = error;
  }

  @action
  void updateEmbeddingBytes(int downloaded, int total) {
    embeddingBytesDownloaded = downloaded;
    embeddingTotalBytes = total;
  }

  @action
  void updateInferenceBytes(int downloaded, int total) {
    inferenceBytesDownloaded = downloaded;
    inferenceTotalBytes = total;
  }

  @computed
  bool get isEmbeddingComplete =>
      embeddingStatus == ModelDownloadStatus.completed;

  @computed
  bool get isInferenceComplete =>
      inferenceStatus == ModelDownloadStatus.completed;

  @computed
  bool get areAllModelsReady => isEmbeddingComplete && isInferenceComplete;

  @computed
  String get embeddingProgressText {
    if (embeddingBytesDownloaded != null && embeddingTotalBytes != null) {
      final mb = embeddingBytesDownloaded! / (1024 * 1024);
      final totalMb = embeddingTotalBytes! / (1024 * 1024);
      return '${mb.toStringAsFixed(1)}MB / ${totalMb.toStringAsFixed(1)}MB';
    }
    return '${(embeddingProgress * 100).toInt()}%';
  }

  @computed
  String get inferenceProgressText {
    if (inferenceBytesDownloaded != null && inferenceTotalBytes != null) {
      final mb = inferenceBytesDownloaded! / (1024 * 1024);
      final totalMb = inferenceTotalBytes! / (1024 * 1024);
      return '${mb.toStringAsFixed(1)}MB / ${totalMb.toStringAsFixed(1)}MB';
    }
    return '${(inferenceProgress * 100).toInt()}%';
  }
}

