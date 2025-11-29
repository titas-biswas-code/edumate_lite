import 'package:equatable/equatable.dart';

/// Base class for all failures in the app
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Storage related failures
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

/// Model related failures
class ModelFailure extends Failure {
  const ModelFailure(super.message, {super.code});
}

/// Processing related failures
class ProcessingFailure extends Failure {
  const ProcessingFailure(super.message, {super.code});
}

/// Network related failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// File operation failures
class FileFailure extends Failure {
  const FileFailure(super.message, {super.code});
}

/// Vector search failures
class VectorSearchFailure extends Failure {
  const VectorSearchFailure(super.message, {super.code});
}

