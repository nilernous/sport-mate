/// Shared JSON helpers and the paged list envelope used by the API.
typedef Json = Map<String, dynamic>;

double toDouble(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

int toInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

DateTime toDate(Object? v) => DateTime.tryParse('$v') ?? DateTime.fromMillisecondsSinceEpoch(0);

DateTime? toDateOrNull(Object? v) => v == null ? null : DateTime.tryParse('$v');

List<T> toList<T>(Object? v, T Function(Json) fromJson) =>
    v is List ? v.map((e) => fromJson(e as Json)).toList() : <T>[];

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name.toLowerCase() == '$name'.toLowerCase()) return value;
  }
  return fallback;
}

class Paged<T> {
  const Paged({required this.items, required this.page, required this.pageSize, required this.totalItems, required this.totalPages});

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory Paged.fromJson(Json json, T Function(Json) fromJson) => Paged(
        items: toList(json['items'], fromJson),
        page: toInt(json['page']),
        pageSize: toInt(json['pageSize']),
        totalItems: toInt(json['totalItems']),
        totalPages: toInt(json['totalPages']),
      );
}

/// Result of a delete that may fall back to deactivation.
class DeleteResult {
  const DeleteResult(this.action, this.message);

  final String action;
  final String message;

  bool get deleted => action == 'Deleted';

  factory DeleteResult.fromJson(Json json) => DeleteResult('${json['action']}', '${json['message']}');
}
