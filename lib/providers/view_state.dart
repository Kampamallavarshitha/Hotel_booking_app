import '../core/api/api_client.dart';

enum ViewState { idle, loading, success, error }

/// Converts any thrown object into a message that is safe to show to users.
String errorMessage(Object e) =>
    e is ApiException ? e.message : 'Something went wrong. Please try again.';
