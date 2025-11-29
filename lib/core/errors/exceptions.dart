/// Base exception for app-specific errors
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Storage exceptions
class StorageException extends AppException {
  StorageException(super.message, {super.code});
}

/// Model exceptions
class ModelException extends AppException {
  ModelException(super.message, {super.code});
}

/// Processing exceptions
class ProcessingException extends AppException {
  ProcessingException(super.message, {super.code});
}

/// Network exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

/// File operation exceptions
class FileException extends AppException {
  FileException(super.message, {super.code});
}

