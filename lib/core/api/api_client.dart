/// Thrown for any non-2xx response. [code] mirrors the HTTP status.
class ApiException implements Exception {
  final int code;
  final String message;
  const ApiException(this.code, this.message);

  @override
  String toString() => 'ApiException($code): $message';
}

/// Transport abstraction. The app only talks to this interface, so the mock
/// can be swapped for a real HTTP client (see README) without touching UI code.
abstract class ApiClient {
  Future<Map<String, dynamic>> get(String path, {Map<String, String> query});
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body});
}
