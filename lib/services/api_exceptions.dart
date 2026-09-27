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

/// Login rejected because the credentials are wrong (401, code
/// INVALID_CREDENTIALS) — carries how many tries are left before the lock,
/// when the backend says so. An unknown username returns this same shape
/// with attemptsRemaining at the max, so the response never reveals whether
/// the account exists.
class InvalidCredentialsException extends UnauthorizedException {
  final int? attemptsRemaining;
  final int? maxAttempts;
  const InvalidCredentialsException(super.statusCode, super.message,
      {this.attemptsRemaining, this.maxAttempts});
}

/// Login refused because the account is locked, or the whole network
/// address is being throttled (429, code ACCOUNT_LOCKED or
/// TOO_MANY_REQUESTS) — not a wrong-PIN answer. A request made while locked
/// returns this immediately and does not count as another attempt or
/// extend the lock.
class AccountLockedException extends ApiException {
  final int? retryAfterSeconds;
  final String? code;
  const AccountLockedException(super.statusCode, super.message,
      {this.retryAfterSeconds, this.code});

  bool get isIpThrottle => code == 'TOO_MANY_REQUESTS';

  /// Headline for the banner, without the countdown.
  String get headline => isIpThrottle ? message : 'Account temporarily locked.';
}

/// One line for a failed login, for screens that just show text.
String loginFailureText(ApiException e) {
  if (e is AccountLockedException) {
    final s = e.retryAfterSeconds;
    return s == null
        ? (e.isIpThrottle ? e.message : '${e.headline} Try again later.')
        : '${e.headline} Try again in ${formatMmSs(s)}';
  }
  if (e is InvalidCredentialsException && e.attemptsRemaining != null) {
    final n = e.attemptsRemaining!;
    return 'Invalid credentials. $n attempt${n == 1 ? '' : 's'} remaining '
        'before temporary lock.';
  }
  return e.message;
}

/// 299 -> "04:59".
String formatMmSs(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final m = (s ~/ 60).toString().padLeft(2, '0');
  final r = (s % 60).toString().padLeft(2, '0');
  return '$m:$r';
}

/// 404 on GET /api/products/barcode/{barcode} — unrecognized barcode.
class ProductNotFoundException extends ApiException {
  const ProductNotFoundException(super.statusCode, super.message);
}

/// 409 on GET /api/products/barcode/{barcode} — product exists but isn't
/// currently sellable/active.
class ProductNotSellableException extends ApiException {
  const ProductNotSellableException(super.statusCode, super.message);
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
