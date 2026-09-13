import 'package:intl/intl.dart';

import '../constants/app_config.dart';

final _vnd = NumberFormat.decimalPattern('vi_VN');
final _dateTime = DateFormat('dd/MM/yyyy HH:mm');
final _date = DateFormat('dd/MM/yyyy');
final _apiDate = DateFormat('yyyy-MM-dd');

/// 3519000 -> "3.519.000 ₫"
String formatVnd(num amount) => '${_vnd.format(amount)} ₫';

String formatDateTime(DateTime value) => _dateTime.format(value.toLocal());

String formatDate(DateTime value) => _date.format(value.toLocal());

/// Calendar date for report/query parameters.
String formatApiDate(DateTime value) => _apiDate.format(value);

/// Uploaded images are returned as server-relative paths; external images are absolute.
String? resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  return '${AppConfig.apiOrigin}${url.startsWith('/') ? '' : '/'}$url';
}

/// "BankTransfer" -> "Bank Transfer"
String humanize(String value) =>
    value.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ');
