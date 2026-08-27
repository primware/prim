import 'package:flutter_test/flutter_test.dart';
import 'package:primware/views/Home/order/history_search_criteria.dart';

void main() {
  test('empty criteria represents the unfiltered recent history', () {
    expect(const HistorySearchCriteria().isEmpty, isTrue);
  });

  test('criteria supports combined remote search values', () {
    const criteria = HistorySearchCriteria(
      customerText: 'María',
      documentText: 'FAC-100',
      docStatus: 'CO',
      onlyMyMovements: true,
    );

    expect(criteria.isEmpty, isFalse);
    expect(criteria.copyWith(customerText: ''), isNot(criteria));
    expect(criteria.copyWith(clearDocStatus: true).docStatus, isNull);
  });

  test('OData values escape apostrophes', () {
    expect(escapeODataText("D'Angelo"), "D''Angelo");
  });

  test('paged results preserve API pagination metadata', () {
    const result = PagedResult<int>(
      records: [1, 2],
      rowCount: 238,
      recordsSize: 2,
      skipRecords: 50,
    );

    expect(result.records, [1, 2]);
    expect(result.rowCount, 238);
    expect(result.skipRecords, 50);
  });

  test('unified page keeps combined total and page index', () {
    const page = UnifiedHistoryPage(
      items: <Object>['orden', 'recibo'],
      totalCount: 120,
      pageIndex: 1,
    );

    expect(page.items, hasLength(2));
    expect(page.totalCount, 120);
    expect(page.pageIndex, 1);
  });
}
