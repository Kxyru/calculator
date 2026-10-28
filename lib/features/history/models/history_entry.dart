class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.expression,
    required this.result,
    required this.createdAt,
  });

  final String id;
  final String expression;
  final double result;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'id': id,
    'expression': expression,
    'result': result,
    'createdAt': createdAt.toIso8601String(),
  };

  static HistoryEntry? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final expression = value['expression'];
    final result = value['result'];
    final createdAt = value['createdAt'];
    if (id is! String ||
        expression is! String ||
        result is! num ||
        !result.toDouble().isFinite ||
        createdAt is! String) {
      return null;
    }
    final parsedDate = DateTime.tryParse(createdAt);
    if (parsedDate == null) return null;
    return HistoryEntry(
      id: id,
      expression: expression,
      result: result.toDouble(),
      createdAt: parsedDate,
    );
  }
}
