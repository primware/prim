class HistorySearchCriteria {
  const HistorySearchCriteria({
    this.customerText = '',
    this.documentText = '',
    this.docStatus,
    this.onlyMyMovements = false,
    this.organizationId,
  });

  final String customerText;
  final String documentText;
  final String? docStatus;
  final bool onlyMyMovements;
  final int? organizationId;

  bool get isEmpty =>
      customerText.trim().isEmpty &&
      documentText.trim().isEmpty &&
      docStatus == null &&
      !onlyMyMovements &&
      organizationId == null;

  HistorySearchCriteria copyWith({
    String? customerText,
    String? documentText,
    String? docStatus,
    bool clearDocStatus = false,
    bool? onlyMyMovements,
    int? organizationId,
    bool clearOrganization = false,
  }) {
    return HistorySearchCriteria(
      customerText: customerText ?? this.customerText,
      documentText: documentText ?? this.documentText,
      docStatus: clearDocStatus ? null : docStatus ?? this.docStatus,
      onlyMyMovements: onlyMyMovements ?? this.onlyMyMovements,
      organizationId: clearOrganization
          ? null
          : organizationId ?? this.organizationId,
    );
  }

  Map<String, dynamic> toJson() => {
    'customerText': customerText.trim(),
    'documentText': documentText.trim(),
    'docStatus': docStatus,
    'onlyMyMovements': onlyMyMovements,
    'organizationId': organizationId,
  };

  factory HistorySearchCriteria.fromJson(Map<String, dynamic> json) {
    final rawOrganizationId = json['organizationId'];
    return HistorySearchCriteria(
      customerText: (json['customerText'] ?? '').toString(),
      documentText: (json['documentText'] ?? '').toString(),
      docStatus: json['docStatus']?.toString(),
      onlyMyMovements: json['onlyMyMovements'] == true,
      organizationId: rawOrganizationId is num
          ? rawOrganizationId.toInt()
          : int.tryParse(rawOrganizationId?.toString() ?? ''),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistorySearchCriteria &&
          other.customerText.trim() == customerText.trim() &&
          other.documentText.trim() == documentText.trim() &&
          other.docStatus == docStatus &&
          other.onlyMyMovements == onlyMyMovements &&
          other.organizationId == organizationId;

  @override
  int get hashCode => Object.hash(
    customerText.trim(),
    documentText.trim(),
    docStatus,
    onlyMyMovements,
    organizationId,
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
