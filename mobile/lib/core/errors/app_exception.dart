import 'package:dio/dio.dart';

/// Error shown to the user. Built from the API's Problem Details response
/// or from a network failure, so screens never display raw exceptions.
class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;

  /// Validation messages keyed by camelCase field name.
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isNetwork => statusCode == null;

  String? fieldError(String field) {
    final errors = fieldErrors[field];
    return errors == null || errors.isEmpty ? null : errors.first;
  }

  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is DioException) return AppException.fromDio(error);
    return const AppException('Something went wrong. Please try again.');
  }

  factory AppException.fromDio(DioException e) {
    final inner = e.error;
    if (inner is AppException) return inner;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException('The server is taking too long to respond. Please try again.');
      case DioExceptionType.connectionError:
        return const AppException('Cannot reach the server. Check your connection and try again.');
      default:
        break;
    }

    final response = e.response;
    if (response == null) {
      return const AppException('Cannot reach the server. Check your connection and try again.');
    }

    final status = response.statusCode;
    final data = response.data;
    var message = _defaultMessage(status);
    final fieldErrors = <String, List<String>>{};

    if (data is Map) {
      final detail = data['detail'];
      final title = data['title'];
      final errors = data['errors'];
      if (errors is Map) {
        errors.forEach((key, value) {
          final field = _camel(key.toString());
          fieldErrors[field] = value is List ? value.map((v) => v.toString()).toList() : [value.toString()];
        });
      }
      if (detail is String && detail.isNotEmpty) {
        message = detail;
      } else if (fieldErrors.isNotEmpty) {
        message = fieldErrors.values.first.first;
      } else if (title is String && title.isNotEmpty && status != 401 && status != 403) {
        message = title;
      }
    }
    return AppException(message, statusCode: status, fieldErrors: fieldErrors);
  }

  static String _defaultMessage(int? status) => switch (status) {
        400 => 'Some information is invalid.',
        401 => 'Your session has expired. Please sign in again.',
        403 => 'You do not have permission to do this.',
        404 => 'The requested item was not found.',
        409 => 'This action conflicts with the current state. Please refresh and try again.',
        _ => 'Something went wrong. Please try again.',
      };

  // ASP.NET may report "$.FieldName" or "FieldName"; screens use camelCase.
  static String _camel(String key) {
    final name = key.startsWith(r'$.') ? key.substring(2) : key;
    return name.isEmpty ? name : name[0].toLowerCase() + name.substring(1);
  }

  @override
  String toString() => message;
}
