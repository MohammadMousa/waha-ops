/// Base class for any non-2xx response. `message` is the backend's own
/// human-readable string — display it, don't parse it.
sealed class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// 401 — bad username/PIN, disabled employee, or expired/invalid token.
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.statusCode, super.message);
}

/// Any other non-2xx we didn't specifically anticipate.
class UnknownApiException extends ApiException {
  const UnknownApiException(super.statusCode, super.message);
}

/// Network-level failure — no response at all.
class NetworkException implements Exception {
  final Object cause;
  const NetworkException(this.cause);

  @override
  String toString() => 'Network error: $cause';
}
