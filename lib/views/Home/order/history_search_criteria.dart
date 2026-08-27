class HistorySearchCriteria {
  const HistorySearchCriteria({
    this.customerText = '',
    this.documentText = '',
    this.docStatus,
    this.onlyMyMovements = false,
  });

  final String customerText;
  final String documentText;
  final String? docStatus;
  final bool onlyMyMovements;

  bool get isEmpty =>
      customerText.trim().isEmpty &&
      documentText.trim().isEmpty &&
      docStatus == null &&
      !onlyMyMovements;

  HistorySearchCriteria copyWith({
    String? customerText,
    String? documentText,
    String? docStatus,
    bool clearDocStatus = false,
    bool? onlyMyMovements,
  }) {
    return HistorySearchCriteria(
      customerText: customerText ?? this.customerText,
      documentText: documentText ?? this.documentText,
      docStatus: clearDocStatus ? null : docStatus ?? this.docStatus,
      onlyMyMovements: onlyMyMovements ?? this.onlyMyMovements,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistorySearchCriteria &&
          other.customerText.trim() == customerText.trim() &&
          other.documentText.trim() == documentText.trim() &&
          other.docStatus == docStatus &&
          other.onlyMyMovements == onlyMyMovements;

  @override
  int get hashCode => Object.hash(
    customerText.trim(),
    documentText.trim(),
    docStatus,
    onlyMyMovements,
  );
}

String escapeODataText(String value) => value.trim().replaceAll("'", "''");

class PagedResult<T> {
  const PagedResult({
    required this.records,
    required this.rowCount,
    required this.recordsSize,
    required this.skipRecords,
  });

  final List<T> records;
  final int rowCount;
  final int recordsSize;
  final int skipRecords;
}

class UnifiedHistoryPage {
  const UnifiedHistoryPage({
    required this.items,
    required this.totalCount,
    required this.pageIndex,
  });

  final List<Object> items;
  final int totalCount;
  final int pageIndex;
}
