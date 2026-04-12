abstract class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  final int? statusCode;

  NetworkException(super.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'NetworkException: $message (Status: $statusCode)';
    }
    return 'NetworkException: $message';
  }
}

class ParsingException extends AppException {
  ParsingException(super.message);

  @override
  String toString() => 'ParsingException: $message';
}
