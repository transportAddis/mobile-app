// ─────────────────────────────────────────────────────────────────────────────
// ApiException
//
// Thrown by every service method on any non-2xx HTTP response, network error,
// or malformed JSON. Callers catch this type and surface [message] to the UI.
// ─────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode});

  /// Human-readable description safe to show in a SnackBar or error widget.
  final String message;

  /// HTTP status code (null for network/timeout/parse errors).
  final int? statusCode;

  @override
  String toString() => statusCode != null
      ? 'ApiException($statusCode): $message'
      : 'ApiException: $message';

  // ── Named constructors for common error classes ───────────────────────────

  factory ApiException.unauthorized() => const ApiException(
    message: 'Session expired. Please log in again.',
    statusCode: 401,
  );

  factory ApiException.forbidden() => const ApiException(
    message: 'You do not have permission to perform this action.',
    statusCode: 403,
  );

  factory ApiException.notFound(String resource) =>
      ApiException(message: '$resource not found.', statusCode: 404);

  factory ApiException.server() => const ApiException(
    message: 'A server error occurred. Please try again later.',
    statusCode: 500,
  );

  factory ApiException.network() => const ApiException(
    message: 'Network error. Check your connection and try again.',
  );

  factory ApiException.parse() =>
      const ApiException(message: 'Unexpected response format from server.');

  /// Build from any HTTP status code and an optional server-provided message.
  factory ApiException.fromStatus(int statusCode, [String? serverMessage]) {
    return switch (statusCode) {
      400 => ApiException(
        message: serverMessage ?? 'Bad request.',
        statusCode: 400,
      ),
      401 => ApiException.unauthorized(),
      403 => ApiException.forbidden(),
      404 => ApiException.notFound(serverMessage ?? 'Resource'),
      >= 500 => ApiException.server(),
      _ => ApiException(
        message: serverMessage ?? 'Unexpected error (HTTP $statusCode).',
        statusCode: statusCode,
      ),
    };
  }
}
