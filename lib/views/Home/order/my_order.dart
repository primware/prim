import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/shared/custom_textfield.dart';
import 'package:primware/shared/shimmer_list.dart';
import 'package:primware/shared/toast_message.dart';
import 'package:primware/views/Home/dashboard/dashboard_view.dart';
import 'package:primware/views/Home/order/order_funtions.dart';
import 'package:primware/views/Home/order/my_order_detail.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
import 'package:printing/printing.dart';
import '../../../API/pos.api.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/format_date.dart';
import '../../../shared/footer.dart';
import 'my_order_print_generator.dart';
import '../../../shared/doc_type_chip.dart';
import '../invoice/invoice_details.dart';
import '../invoice/invoice_funtions.dart';
import '../invoice/invoice_payment_print_generator.dart';
import '../invoice/invoice_payment_receipt.dart';
import 'history_search_criteria.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  static const _paymentFilterLabel = 'Pagos a facturas';
  static const _sourcePageSize = 50;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _orders = [];
  List<InvoicePaymentReceipt> _invoicePaymentReceipts = [];
  bool _isLoadingReceipts = true;
  bool _isLoading = true, isSearchLoading = false;
  String? selectedDocTypeFilter;
  HistorySearchCriteria _appliedCriteria = const HistorySearchCriteria();
  HistorySearchCriteria _pendingCriteria = const HistorySearchCriteria();
  final TextEditingController _customerSearchController = TextEditingController();
  final TextEditingController _documentSearchController = TextEditingController();
  final TextEditingController _localFilterController = TextEditingController();
  final Map<int, UnifiedHistoryPage> _pageCache = {};
  int _currentPage = 0;
  int _totalRecords = 0;
  String _localFilter = '';

  // Mapa de estados de documento (DocStatus) a nombre en español y color
  final Map<String, Map<String, dynamic>> _docStatusMap = {
    'DR': {'label': 'Borrador', 'color': Colors.grey, 'icon': Icons.edit_note},
    'CO': {'label': 'Completado', 'color': Colors.green, 'icon': Icons.check_circle_outline},
    'CL': {'label': 'Cerrado', 'color': Colors.blueGrey, 'icon': Icons.lock_outline},
    'VO': {'label': 'Anulado', 'color': Colors.red, 'icon': Icons.cancel_outlined},
    'IP': {'label': 'En proceso', 'color': Colors.orange, 'icon': Icons.hourglass_bottom},
    'PR': {'label': 'Preparado', 'color': Colors.orange, 'icon': Icons.hourglass_bottom},
    'WC': {'label': 'Esperando completar', 'color': Colors.orangeAccent, 'icon': Icons.hourglass_top},
    'AP': {'label': 'Aprobado', 'color': Colors.blue, 'icon': Icons.thumb_up_outlined},
    'RJ': {'label': 'Rechazado', 'color': Colors.redAccent, 'icon': Icons.thumb_down_outlined},
  };

  // Confirmación para imprimir ticket
  Future<bool?> _printTicketConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Column(
          children: [
            Icon(Icons.print_rounded, size: 45, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              AppLocale.confirmPrintTicket.getString(context),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(AppLocale.printTicketMessage.getString(context), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  // Confirmación para convertir a Nota de Crédito
  Future<bool?> _refundConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 45, color: Colors.redAccent),
            SizedBox(height: 10),
            Text(
              AppLocale.confirmCreditNoteTitle.getString(context),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocale.confirmCreditNoteBody.getString(context), textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Text(
              AppLocale.cannotUndoWarning.getString(context),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red, // Texto en rojo
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly, // Centra y separa los botones
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  Future<bool?> _completeConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Column(
          children: [
            Icon(Icons.check, size: 45, color: Colors.green),
            SizedBox(height: 10),
            Text(
              AppLocale.completeOrderTitle.getString(context),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(AppLocale.completeOrderBody.getString(context), textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  // Imprimir ticket directamente desde la lista
  Future<void> _printTicket(Map<String, dynamic> order) async {
    final bool? confirm = await _printTicketConfirmation(context);
    if (confirm == true) {
      try {
        final pdfBytes = POS.isPOS == true ? await generatePOSTicket(order) : await generateOrderTicket(order);

        try {
          final printers = await Printing.listPrinters();
          final defaultPrinter = printers.firstWhere(
            (p) => p.isDefault,
            orElse: () => printers.isNotEmpty ? printers.first : throw Exception('No hay impresoras disponibles'),
          );

          await Printing.directPrintPdf(printer: defaultPrinter, usePrinterSettings: true, dynamicLayout: true, onLayout: (_) => pdfBytes);
        } catch (e) {
          await Printing.sharePdf(bytes: pdfBytes, filename: 'Order_${order['DocumentNo']}.pdf');
        }
      } catch (e) {
        // Último fallback silencioso: intentar compartir PDF genérico
        try {
          final pdfBytes = await generateOrderTicket(order);
          await Printing.sharePdf(bytes: pdfBytes, filename: 'Order_${order['DocumentNo']}.pdf');
        } catch (_) {}
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory(initialLoad: true);
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _documentSearchController.dispose();
    _localFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool initialLoad = false, int page = 0, bool resetCache = false}) async {
    if (!mounted) return;
    if (!resetCache && _pageCache[page] != null) {
      final cached = _pageCache[page]!;
      setState(() {
        _currentPage = page;
        _totalRecords = cached.totalCount;
        _assignHistoryItems(cached.items);
      });
      return;
    }
    setState(() {
      _isLoading = initialLoad;
      _isLoadingReceipts = initialLoad;
      isSearchLoading = !initialLoad;
    });
    try {
      final results = await Future.wait<dynamic>([
        fetchOrdersPage(context: context, criteria: _pendingCriteria, top: _sourcePageSize, skip: page * _sourcePageSize),
        fetchInvoicePaymentReceiptsPage(context: context, criteria: _pendingCriteria, top: _sourcePageSize, skip: page * _sourcePageSize),
      ]);
      if (!mounted) return;
      final orderPage = results[0] as PagedResult<Map<String, dynamic>>;
      final receiptPage = results[1] as PagedResult<InvoicePaymentReceipt>;
      final items = <Object>[...orderPage.records, ...receiptPage.records]
        ..sort((left, right) => _historyDate(right).compareTo(_historyDate(left)));
      final unified = UnifiedHistoryPage(items: items, totalCount: orderPage.rowCount + receiptPage.rowCount, pageIndex: page);
      setState(() {
        if (resetCache) _pageCache.clear();
        _pageCache[page] = unified;
        _assignHistoryItems(items);
        _currentPage = page;
        _totalRecords = unified.totalCount;
        _appliedCriteria = _pendingCriteria;
        _isLoading = false;
        _isLoadingReceipts = false;
        isSearchLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingReceipts = false;
        isSearchLoading = false;
      });
      ToastMessage.show(context: context, message: 'No se pudo actualizar el historial. $error', type: ToastType.failure);
    }
  }

  void _assignHistoryItems(List<Object> items) {
    _orders = items.whereType<Map<String, dynamic>>().toList();
    _invoicePaymentReceipts = items.whereType<InvoicePaymentReceipt>().toList();
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    return _orders.where((order) {
      final query = _localFilter.trim().toLowerCase();
      final matchesLocal =
          query.isEmpty ||
          (order['DocumentNo'] ?? '').toString().toLowerCase().contains(query) ||
          (order['bpartner']?['name'] ?? '').toString().toLowerCase().contains(query);
      final matchesDocType = selectedDocTypeFilter == null || order['doctypetarget']?['name'] == selectedDocTypeFilter;
      return matchesLocal && matchesDocType;
    }).toList();
  }

  List<InvoicePaymentReceipt> _getFilteredReceipts() {
    if (selectedDocTypeFilter != null && selectedDocTypeFilter != _paymentFilterLabel) {
      return const [];
    }
    final query = _localFilter.trim().toLowerCase();
    return _invoicePaymentReceipts.where((receipt) {
      return query.isEmpty || receipt.customerName.toLowerCase().contains(query) || receipt.displayDocumentNo.toLowerCase().contains(query);
    }).toList();
  }

  List<Object> _getUnifiedHistory() {
    final items = <Object>[..._getFilteredOrders(), ..._getFilteredReceipts()];
    items.sort((left, right) => _historyDate(right).compareTo(_historyDate(left)));
    return items;
  }

  DateTime _historyDate(Object item) {
    if (item is InvoicePaymentReceipt) return item.date;
    if (item is Map) {
      return DateTime.tryParse((item['DateOrdered'] ?? item['Created'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _stageCriteria(HistorySearchCriteria criteria) {
    setState(() {
      _pendingCriteria = criteria;
      if (_customerSearchController.text != criteria.customerText) {
        _customerSearchController.text = criteria.customerText;
      }
      if (_documentSearchController.text != criteria.documentText) {
        _documentSearchController.text = criteria.documentText;
      }
    });
  }

  void _updatePendingTextCriteria() {
    setState(() {
      _pendingCriteria = _pendingCriteria.copyWith(
        customerText: _customerSearchController.text.trim(),
        documentText: _documentSearchController.text.trim(),
      );
    });
  }

  void _clearPendingCriteria() {
    FocusScope.of(context).unfocus();
    _customerSearchController.clear();
    _documentSearchController.clear();
    _stageCriteria(const HistorySearchCriteria());
  }

  void _resetSearchDraft() {
    _customerSearchController.text = _appliedCriteria.customerText;
    _documentSearchController.text = _appliedCriteria.documentText;
    setState(() => _pendingCriteria = _appliedCriteria);
  }

  Future<void> _applyDrawerSearch() async {
    Navigator.of(context).pop();
    await _loadHistory(page: 0, resetCache: true);
  }

  Widget _buildSearchDrawer() {
    final criteria = _pendingCriteria;
    return Drawer(
      width: MediaQuery.of(context).size.width.clamp(320, 460).toDouble(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.manage_search_rounded, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Búsqueda avanzada', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () {
                      _resetSearchDraft();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextfieldTheme(
                        controlador: _customerSearchController,
                        texto: 'Cliente o identificación',
                        icono: Icons.person_search_outlined,
                        maxLines: 1,
                        fillColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).cardColor,
                        onChanged: (_) => _updatePendingTextCriteria(),
                        onSubmitted: (_) {
                          if (!isSearchLoading) _applyDrawerSearch();
                        },
                      ),
                      const SizedBox(height: 14),
                      TextfieldTheme(
                        controlador: _documentSearchController,
                        texto: 'N.º de orden, recibo o factura',
                        icono: Icons.receipt_long_outlined,
                        maxLines: 1,
                        fillColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).cardColor,
                        onChanged: (_) => _updatePendingTextCriteria(),
                        onSubmitted: (_) {
                          if (!isSearchLoading) _applyDrawerSearch();
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String?>(
                        value: criteria.docStatus,
                        decoration: InputDecoration(
                          labelText: 'Estado del documento',
                          prefixIcon: const Icon(Icons.fact_check_outlined),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Todos los estados')),
                          ..._docStatusMap.entries.map(
                            (entry) => DropdownMenuItem<String?>(value: entry.key, child: Text(entry.value['label'].toString())),
                          ),
                        ],
                        onChanged: (value) =>
                            _stageCriteria(value == null ? criteria.copyWith(clearDocStatus: true) : criteria.copyWith(docStatus: value)),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Solo mis movimientos'),
                        subtitle: const Text('Órdenes y pagos registrados a mi nombre'),
                        value: criteria.onlyMyMovements,
                        onChanged: (value) => _stageCriteria(criteria.copyWith(onlyMyMovements: value)),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                children: [
                  TextButton(
                    onPressed: isSearchLoading
                        ? null
                        : () {
                            _clearPendingCriteria();
                            _applyDrawerSearch();
                          },
                    child: const Text('Limpiar'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _resetSearchDraft();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isSearchLoading ? null : _applyDrawerSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalFilterField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtrar esta página', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextfieldTheme(
            controlador: _localFilterController,
            texto: 'Cliente, orden o recibo',
            icono: Icons.filter_alt_outlined,
            maxLines: 1,
            fillColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).cardColor,
            onChanged: (value) {
              setState(() => _localFilter = value.trim().toLowerCase());
            },
          ),
          const SizedBox(height: 12),
          Text('Tipo de documento:', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (_orders.isNotEmpty || _invoicePaymentReceipts.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Todos'),
                      selected: selectedDocTypeFilter == null,
                      selectedColor: Theme.of(context).primaryColor,
                      checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                      onSelected: (_) {
                        setState(() => selectedDocTypeFilter = null);
                      },
                    ),
                  ),
                  if (_invoicePaymentReceipts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: const Icon(Icons.payments_outlined, size: 17),
                        label: const Text(_paymentFilterLabel),
                        selected: selectedDocTypeFilter == _paymentFilterLabel,
                        selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                        onSelected: (selected) {
                          setState(() {
                            selectedDocTypeFilter = selected ? _paymentFilterLabel : null;
                          });
                        },
                      ),
                    ),
                  ..._orders
                      .map((order) => order['doctypetarget']?['name']?.toString() ?? '')
                      .where((name) => name.isNotEmpty)
                      .toSet()
                      .map(
                        (docName) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(docName),
                            selected: selectedDocTypeFilter == docName,
                            selectedColor: Theme.of(context).primaryColor,
                            checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                            onSelected: (selected) {
                              setState(() {
                                selectedDocTypeFilter = selected ? docName : null;
                              });
                            },
                          ),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final visibleCount = _getUnifiedHistory().length;
    final loadedCount = _orders.length + _invoicePaymentReceipts.length;
    final totalPages = _totalRecords == 0 ? 1 : (_totalRecords / (_sourcePageSize * 2)).ceil();
    final hasLocalFilter = _localFilter.isNotEmpty || selectedDocTypeFilter != null;
    final start = _totalRecords == 0 ? 0 : (_currentPage * _sourcePageSize * 2) + 1;
    final end = (start + loadedCount - 1).clamp(0, _totalRecords);
    return Column(
      children: [
        Text(
          hasLocalFilter
              ? 'Mostrando $visibleCount de $loadedCount cargados en esta página · $_totalRecords resultados de búsqueda'
              : 'Mostrando $start–$end de $_totalRecords movimientos',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _currentPage > 0 && !isSearchLoading ? () => _loadHistory(page: _currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Anterior'),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Página ${_currentPage + 1} de $totalPages')),
            OutlinedButton.icon(
              onPressed: _currentPage + 1 < totalPages && !isSearchLoading ? () => _loadHistory(page: _currentPage + 1) : null,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Siguiente'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _printInvoicePaymentReceipt(InvoicePaymentReceipt receipt) async {
    final confirm = await _printTicketConfirmation(context);
    if (confirm != true) return;
    try {
      final pdfBytes = POS.isPOS ? await generateInvoicePaymentPOSTicket(receipt) : await generateInvoicePaymentReceipt(receipt);
      try {
        final printers = await Printing.listPrinters();
        final defaultPrinter = printers.firstWhere(
          (printer) => printer.isDefault,
          orElse: () => printers.isNotEmpty ? printers.first : throw Exception('No hay impresoras disponibles'),
        );
        await Printing.directPrintPdf(printer: defaultPrinter, usePrinterSettings: true, dynamicLayout: true, onLayout: (_) => pdfBytes);
      } catch (_) {
        await Printing.sharePdf(bytes: pdfBytes, filename: 'Recibo_Pago_${receipt.displayDocumentNo}.pdf');
      }
    } catch (_) {}
  }

  Widget _buildInvoicePaymentCard(InvoicePaymentReceipt receipt) {
    final green = Colors.green.shade700;
    final contentColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);
    final cardColor = Color.alphaBlend(
      Colors.green.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.07),
      Theme.of(context).cardColor,
    );
    Widget chip(String label, IconData icon, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePaymentDetailsPage(receipt: receipt))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: green.withOpacity(0.18)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(color: green.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(Icons.person, color: green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Recibo #${receipt.displayDocumentNo}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppLocale.printTicket.getString(context),
                  onPressed: () => _printInvoicePaymentReceipt(receipt),
                  icon: const Icon(Icons.print_outlined, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: green.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payments_outlined, color: contentColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        AppLocale.summary.getString(context),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: contentColor, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today_outlined, color: contentColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        formatDateUI(receipt.date.toIso8601String()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: contentColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: contentColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Monto: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: contentColor, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'B/.${receipt.totalApplied.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: contentColor, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 0.5)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chip('Pago a facturas', Icons.receipt_long_outlined, green),
                chip('Completado', Icons.check_circle_outline, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onOrderAction(String action, Map<String, dynamic> order) async {
    switch (action) {
      case 'duplicate':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderNewPage(
              isRefund: false,
              doctypeID: order['doctypetarget']?['id'] ?? POS.docTypeID,
              orderName: order['doctypetarget']?['name'] ?? POS.docTypeName,
              sourceOrderId: order['id'],
            ),
          ),
        );
        break;
      case 'convert':
        if (POS.docTypesComplete.isEmpty) {
          ToastMessage.show(context: context, message: AppLocale.noDocTypesAvailable.getString(context), type: ToastType.help);
          return;
        }

        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (BuildContext context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocale.documentType.getString(context),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    ...POS.docTypesComplete.map((doc) {
                      final dynamic rawId = doc['id'];
                      final int? docTypeId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
                      final String docName = (doc['name'] ?? doc['Name'] ?? 'Documento').toString();

                      if (doc['DocSubTypeSO'] == 'RM' || docTypeId == POS.docTypeRefundID || docTypeId == order['doctypetarget']?['id']) {
                        return const SizedBox.shrink();
                      }

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.transform_outlined, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(docName, style: Theme.of(context).textTheme.bodyLarge),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderNewPage(isRefund: false, doctypeID: docTypeId, orderName: docName, sourceOrderId: order['id']),
                            ),
                          ).then((value) {
                            if (value == true) {
                              _loadHistory(page: _currentPage, resetCache: true);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
        break;
      case 'refund':
        final bool? confirm = await _refundConfirmation(context);

        if (confirm == true) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderNewPage(
                isRefund: true,
                doctypeID: POS.docTypeRefundID,
                orderName: POS.docTypeRefundName,
                sourceOrderId: order['id'] ?? order['C_Order_ID'] ?? order['record_id'],
              ),
            ),
          );
        }
        break;
      case 'convertQuote':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderNewPage(
              isRefund: false,
              doctypeID: POS.docTypeID,
              orderName: POS.docTypeName,
              sourceOrderId: order['id'] ?? order['C_Order_ID'] ?? order['record_id'],
            ),
          ),
        );
        break;
      case 'printTicket':
        _printTicket(order);
        break;
      case 'arc':
        final bool? confirmArc = await _refundConfirmation(context);
        if (confirmArc == true) {
          final bool creditMemoSucces = await createCreditMemo(cInvoiceID: order['C_Invoice']?[0]?['id']);
          if (creditMemoSucces) {
            _loadHistory(page: _currentPage, resetCache: true);
          }
        }
        break;
      case 'docComplete':
        final bool? confirmDocComplete = await _completeConfirmation(context);
        if (confirmDocComplete == true) {
          final docCompleteSucces = await docComplete(cOrderID: order['id']);
          if (docCompleteSucces["success"] == true && docCompleteSucces["isError"] == false) {
            _loadHistory(page: _currentPage, resetCache: true);
          } else if (docCompleteSucces["success"] == true && docCompleteSucces["isError"] == true) {
            if (mounted) {
              ToastMessage.show(context: context, message: docCompleteSucces["summary"], type: ToastType.failure);
            }
          } else {
            if (mounted) {
              ToastMessage.show(context: context, message: AppLocale.noDocComplete.getString(context), type: ToastType.failure);
            }
          }
        }
        break;
      default:
        break;
    }
  }

  Widget _buildSubtypePill(Map<String, dynamic> order) {
    final sub = order['doctypetarget']?['subtype']?['id'];
    final bool isReturn = (sub == 'RM') || (order['doctypetarget']?['id'] == POS.docTypeRefundID);
    final String? docName = order['doctypetarget']?['name'];

    return DocTypeChip(docTypeName: docName, isReturn: isReturn);
  }

  Widget _buildCreditMemoPill() {
    final Color baseColor = Colors.red;
    final Color bgColor = baseColor.withOpacity(0.12);
    final String label = AppLocale.creditNote.getString(context);
    final IconData icon = Icons.receipt_long_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: baseColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: baseColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: baseColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDocStatusPill(Map<String, dynamic> order) {
    final String? statusCode = order['DocStatus'] as String?;
    if (statusCode == null) {
      return const SizedBox.shrink();
    }

    final meta =
        _docStatusMap[statusCode] ?? {'label': statusCode, 'color': Theme.of(context).colorScheme.primary, 'icon': Icons.flag_outlined};

    final Color baseColor = meta['color'] as Color;
    final Color bgColor = baseColor.withOpacity(0.12);
    final String label = meta['label'] as String;
    final IconData icon = meta['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: baseColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: baseColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: baseColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountItem({required String label, required String value, required IconData icon, bool highlight = false}) {
    final Color accentColor = highlight ? Theme.of(context).colorScheme.secondary : Theme.of(context).primaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 6),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: highlight ? accentColor : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final bool isComplete = (order['DocStatus'] == 'CO');
    final bool isReturn = (order['doctypetarget']?['id'] == POS.docTypeRefundID);
    final double totalLines = double.tryParse(order['TotalLines']?.toString() ?? '0') ?? 0;
    final double grandTotal = double.tryParse(order['GrandTotal']?.toString() ?? '0') ?? 0;
    final double taxAmount = grandTotal - totalLines;

    final List invoices = order['C_Invoice'] ?? [];
    final bool hasCreditNote = invoices.any((inv) {
      return inv['RelatedInvoice_ID'] != null;
    });

    return GestureDetector(
      onTap: () async {
        final refreshed = await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(order: order)));
        if (refreshed == true) {
          _loadHistory(page: _currentPage, resetCache: true);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.person, color: Theme.of(context).primaryColor, size: 20),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['bpartner']['name'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order['doctypetarget']['name']} #${order['DocumentNo']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                // Menú de opciones de la orden
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) => _onOrderAction(value, order),
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'printTicket',
                        child: Row(
                          children: [
                            const Icon(Icons.print_outlined, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(AppLocale.printTicket.getString(context)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(AppLocale.duplicate.getString(context)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'convert',
                        child: Row(
                          children: [
                            Icon(Icons.transform_outlined, color: Colors.purple.shade400),
                            const SizedBox(width: 8),
                            Text(AppLocale.copyToNewDocument.getString(context)),
                          ],
                        ),
                      ),
                      if (order['DocStatus'] == 'DR')
                        PopupMenuItem<String>(
                          value: 'docComplete',
                          child: Row(
                            children: [
                              const Icon(Icons.check, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(AppLocale.complete.getString(context)),
                            ],
                          ),
                        ),
                    ];
                    if (isReturn == false && POS.isPOS == true && !hasCreditNote) {
                      items.add(
                        PopupMenuItem<String>(
                          value: 'refund',
                          child: Row(
                            children: [
                              const Icon(Icons.undo, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(AppLocale.refund.getString(context)),
                            ],
                          ),
                        ),
                      );
                    }
                    if (POS.isPOS == false && isComplete == true && !hasCreditNote && invoices.isNotEmpty) {
                      items.add(
                        PopupMenuItem<String>(
                          value: 'arc',
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(AppLocale.arc.getString(context)),
                            ],
                          ),
                        ),
                      );
                    }
                    return items;
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payments_outlined, color: Theme.of(context).colorScheme.secondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        AppLocale.summary.getString(context),
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today_outlined, color: Colors.grey.shade500, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        formatDateUI(order['DateOrdered']),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _buildAmountItem(
                        label: AppLocale.subtotal.getString(context),
                        value: totalLines.toStringAsFixed(2),
                        icon: Icons.receipt_long_outlined,
                      ),
                      _buildAmountItem(
                        label: AppLocale.taxes.getString(context),
                        value: taxAmount.toStringAsFixed(2),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      _buildAmountItem(
                        label: AppLocale.total.getString(context),
                        value: grandTotal.toStringAsFixed(2),
                        icon: Icons.payments_rounded,
                        highlight: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 0.5)),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [_buildSubtypePill(order), _buildDocStatusPill(order), if (hasCreditNote) _buildCreditMemoPill()],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
        return Future.value(false);
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(AppLocale.myOrders.getString(context)),
          actions: [
            IconButton(
              tooltip: 'Búsqueda avanzada',
              onPressed: () {
                _resetSearchDraft();
                _scaffoldKey.currentState?.openEndDrawer();
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.tune_rounded),
                  if (!_appliedCriteria.isEmpty)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        drawer: MenuDrawer(),
        endDrawer: _buildSearchDrawer(),
        floatingActionButton: POS.docTypeID != null
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OrderNewPage(doctypeID: POS.docTypeID, orderName: POS.docTypeName, isRefund: POS.docSubType == 'RM'),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: CustomFooter(),
        body: SafeArea(
          child: Center(
            child: CustomContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocalFilterField(),

                  if (isSearchLoading) ...[const SizedBox(height: 4), const LinearProgressIndicator(), const SizedBox(height: 8)],

                  const SizedBox(height: CustomSpacer.medium),

                  Expanded(
                    child: _isLoading || _isLoadingReceipts
                        ? ShimmerList(separation: CustomSpacer.medium)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _getUnifiedHistory().isEmpty ? 2 : _getUnifiedHistory().length + 1,
                            itemBuilder: (context, index) {
                              if (_getUnifiedHistory().isEmpty && index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text(
                                      'No hay coincidencias en esta página.',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }
                              final footerIndex = _getUnifiedHistory().isEmpty ? 1 : _getUnifiedHistory().length;
                              if (index == footerIndex) {
                                return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: _buildPagination());
                              }
                              final item = _getUnifiedHistory()[index];
                              return item is InvoicePaymentReceipt
                                  ? _buildInvoicePaymentCard(item)
                                  : _buildOrderCard(item as Map<String, dynamic>);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
