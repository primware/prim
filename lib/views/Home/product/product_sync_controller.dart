import 'dart:async';

import 'package:flutter/foundation.dart';

import 'product_repository.dart';

class ProductSyncController extends ChangeNotifier {
  ProductSyncController._();
  static final ProductSyncController instance = ProductSyncController._();

  bool isRunning = false;
  bool isStopping = false;
  int processed = 0;
  int total = 0;
  int currentPage = 0;
  int failedPages = 0;
  String? error;
  int? _partnerPriceListID;
  bool _stopRequested = false;
  String? _contextKey;

  double get progress => total <= 0 ? 0 : (processed / total).clamp(0, 1);

  Future<void> start({int? partnerPriceListID}) async {
    if (isRunning) return;
    final nextContext = await ProductRepository.instance.syncContextKey(
      partnerPriceListID,
    );
    final canResume =
        _contextKey == nextContext &&
        (isStopping || error != null || (total > 0 && processed < total));
    if (!canResume) {
      processed = 0;
      total = 0;
      currentPage = 0;
      failedPages = 0;
    }
    _contextKey = nextContext;
    isRunning = true;
    isStopping = false;
    error = null;
    _partnerPriceListID = partnerPriceListID;
    _stopRequested = false;
    notifyListeners();

    try {
      var hasMore = true;
      while (hasMore && !_stopRequested) {
        try {
          final page = await ProductRepository.instance.refreshPage(
            pageIndex: currentPage,
            partnerPriceListID: _partnerPriceListID,
            includeStock: true,
            waitForStock: true,
          );
          total = page.rowCount;
          processed = ((currentPage + 1) * productPageSize).clamp(0, total);
          hasMore = page.hasMore;
          currentPage++;
          error = null;
        } catch (exception) {
          failedPages++;
          error = exception.toString();
          hasMore = false;
        }
        notifyListeners();
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      isRunning = false;
      isStopping = false;
      notifyListeners();
    }
  }

  void stop() {
    if (!isRunning) return;
    _stopRequested = true;
    isStopping = true;
    notifyListeners();
  }

  Future<void> stopAndWait() async {
    stop();
    while (isRunning) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  void cancelForSessionChange() {
    _stopRequested = true;
    isStopping = isRunning;
    ProductRepository.instance.clearMemory();
    notifyListeners();
  }
}
