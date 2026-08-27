import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/API/user.api.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/localization/app_locale.dart';
import 'package:primware/shared/button.widget.dart';
import 'package:primware/shared/custom_app_menu.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_dropdown.dart';
import 'package:primware/shared/custom_searchfield.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/shared/custom_textfield.dart';
import 'package:primware/shared/footer.dart';
import 'package:primware/shared/logo.dart';
import 'package:primware/shared/toast_message.dart';
import 'package:primware/views/Home/order/order_funtions.dart';

import 'invoice_funtions.dart';

class InvoicePaymentPage extends StatefulWidget {
  const InvoicePaymentPage({super.key});

  @override
  State<InvoicePaymentPage> createState() => _InvoicePaymentPageState();
}

class _InvoicePaymentPageState extends State<InvoicePaymentPage> {
  final _customerController = TextEditingController();
  final _customerFieldController = CustomSearchFieldController();
  final Map<int, TextEditingController> _paymentControllers = {};

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _salesReps = [];
  final Map<int, Map<String, dynamic>> _selectedInvoices = {};

  int? _selectedCustomerId;
  int? _selectedSalesRepId;
  String? _selectedCustomerName;
  bool _loadingCustomers = false;
  bool _loadingInvoices = false;
  bool _loadingPayments = true;
  bool _loadingSalesReps = true;
  bool _processingPayments = false;
  String? _invoiceError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
      _loadPaymentMethods();
      _loadSalesReps();
    });
  }

  @override
  void dispose() {
    _customerController.dispose();
    for (final controller in _paymentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _money(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  double get _selectedValue => _selectedInvoices.values.fold<double>(0.0, (sum, invoice) => sum + _money(invoice['grandTotal']));

  double get _allocatedValue => _selectedInvoices.values.fold<double>(0.0, (sum, invoice) => sum + _money(invoice['amountToPay']));

  double get _paymentValue => _paymentControllers.values.fold<double>(0.0, (sum, controller) => sum + _money(controller.text));

  double get _historicalPaidValue => _selectedInvoices.values.fold<double>(0.0, (sum, invoice) => sum + _money(invoice['totalPaid']));

  double get _outstandingDebtValue =>
      _selectedInvoices.values.fold<double>(0.0, (sum, invoice) => sum + _money(invoice['outstandingDebt']));

  double get _historicalPaymentProgress => _selectedValue <= 0 ? 0.0 : (_historicalPaidValue / _selectedValue).clamp(0.0, 1.0).toDouble();

  List<Map<String, dynamic>> get _usedPaymentMethods =>
      _paymentMethods.where((method) => _money(_paymentControllers[method['id']]?.text) > 0).toList();

  bool get _paymentTotalsMatch => invoicePaymentAmountsMatch(_allocatedValue, _paymentValue);

  bool get _usedMethodsHaveTenderType =>
      _usedPaymentMethods.every((method) => (method['tenderTypeID']?.toString().trim() ?? '').isNotEmpty);

  bool get _canProcessPayments =>
      !_processingPayments &&
      !_loadingSalesReps &&
      _selectedSalesRepId != null &&
      _selectedCustomerId != null &&
      _selectedInvoices.isNotEmpty &&
      _allocatedValue > 0 &&
      _paymentValue > 0 &&
      _paymentTotalsMatch &&
      POS.bankAccountID != null &&
      _usedMethodsHaveTenderType;

  int? _defaultSalesRepId() {
    return selectDefaultSalesRepId(_salesReps, UserData.id);
  }

  Future<void> _loadSalesReps() async {
    if (!mounted) return;
    setState(() => _loadingSalesReps = true);
    final result = await fetctSalesRep();
    if (!mounted) return;
    setState(() {
      _salesReps = result;
      _selectedSalesRepId = _defaultSalesRepId();
      _loadingSalesReps = false;
    });
  }

  Future<void> _loadCustomers() async {
    if (!mounted) return;
    setState(() => _loadingCustomers = true);
    final result = await fetchBPartner(context: context, searchTerm: _customerController.text.trim());
    if (!mounted) return;
    setState(() {
      _customers = result;
      _loadingCustomers = false;
    });
  }

  Future<void> _loadPaymentMethods() async {
    final result = await fetchPaymentMethods();
    if (!mounted) return;
    setState(() {
      _paymentMethods = result.where((method) => method['isDiscount'] != true).toList();
      for (final method in _paymentMethods) {
        final id = method['id'] as int?;
        if (id != null) {
          _paymentControllers.putIfAbsent(id, TextEditingController.new);
        }
      }
      _loadingPayments = false;
    });
  }

  Future<void> _selectCustomer(Map<String, dynamic> customer) async {
    final id = customer['id'] as int?;
    if (id == null) return;
    setState(() {
      _selectedCustomerId = id;
      _selectedCustomerName = (customer['name'] ?? '').toString();
      _customerController.text = _selectedCustomerName!;
      _invoices = [];
      _selectedInvoices.clear();
      _invoiceError = null;
      _loadingInvoices = true;
    });
    for (final controller in _paymentControllers.values) {
      controller.clear();
    }

    try {
      final result = await fetchCompletedCustomerInvoices(context: context, bPartnerId: id);
      if (!mounted || _selectedCustomerId != id) return;
      setState(() {
        _invoices = result;
        _loadingInvoices = false;
      });
    } catch (_) {
      if (!mounted || _selectedCustomerId != id) return;
      setState(() {
        _invoiceError = AppLocale.invoiceLoadError.getString(context);
        _loadingInvoices = false;
      });
    }
  }

  void _clearCustomerSelection() {
    setState(() {
      _selectedCustomerId = null;
      _selectedCustomerName = null;
      _customerController.clear();
      _invoices.clear();
      _selectedInvoices.clear();
      _invoiceError = null;
    });
    for (final controller in _paymentControllers.values) {
      controller.clear();
    }
  }

  Future<void> _processPayments() async {
    if (!_canProcessPayments) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        title: Text(AppLocale.process.getString(dialogContext)),
        content: Text(AppLocale.confirmProcessInvoicePayments.getString(dialogContext)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppLocale.cancel.getString(dialogContext))),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(AppLocale.confirm.getString(dialogContext))),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final customerId = _selectedCustomerId!;
    final salesRepId = _selectedSalesRepId!;
    final bankAccountId = POS.bankAccountID!;
    final organizationId = Token.organitation;
    if (organizationId == null || organizationId <= 0) return;

    final payments = _usedPaymentMethods.map((method) {
      final methodId = method['id'] as int;
      return {...method, 'amount': _money(_paymentControllers[methodId]?.text)};
    }).toList();
    final invoices = _selectedInvoices.values.toList();

    setState(() => _processingPayments = true);
    final result = await postInvoicePaymentBatch(
      context: context,
      bankAccountId: bankAccountId,
      organizationId: organizationId,
      bPartnerId: customerId,
      salesRepId: salesRepId,
      posId: POS.cPosID,
      payments: payments,
      invoices: invoices,
    );

    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _processingPayments = false;
        _selectedCustomerId = null;
        _selectedCustomerName = null;
        _customerController.clear();
        _invoices.clear();
        _selectedInvoices.clear();
        _invoiceError = null;
        _selectedSalesRepId = _defaultSalesRepId();
        for (final controller in _paymentControllers.values) {
          controller.clear();
        }
      });
      ToastMessage.show(context: context, message: AppLocale.invoicePaymentsCreated.getString(context), type: ToastType.success);
      return;
    }

    setState(() => _processingPayments = false);
    ToastMessage.show(
      context: context,
      message: (result['message'] ?? AppLocale.invoicePaymentsPartialError.getString(context)).toString(),
      type: ToastType.failure,
    );
  }

  Future<void> _showInvoiceDialog(Map<String, dynamic> invoice) async {
    if (_processingPayments) return;
    final id = invoice['id'] as int?;
    if (id == null) return;
    final current = _selectedInvoices[id];
    final result = await showDialog<double>(
      context: context,
      useSafeArea: true,
      builder: (_) => _InvoicePaymentDialog(invoice: invoice, initialAmount: current == null ? null : _money(current['amountToPay'])),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedInvoices[id] = {...invoice, 'amountToPay': result};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppLocale.user.getString(context)}: ${UserData.name ?? ''}',
              style: TextStyle(fontSize: mobile ? 12 : 14, fontWeight: FontWeight.w400, color: Colors.white70),
            ),
            Text(AppLocale.invoicePayment.getString(context)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: CustomSpacer.medium),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Logo(width: mobile ? 45 : 60),
              ),
            ),
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      bottomNavigationBar: CustomFooter(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [_buildInvoicePicker(), _buildPaymentMethods(), _buildSummary()],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoicePicker() {
    return CustomContainer(
      maxWidthContainer: 360,
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocale.customerInvoices.getString(context), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: CustomSpacer.medium),
          if (_loadingSalesReps)
            const LinearProgressIndicator()
          else if (_salesReps.isEmpty) ...[
            _InlineWarning(text: AppLocale.salesRepLoadError.getString(context)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _processingPayments ? null : _loadSalesReps, child: Text(AppLocale.refresh.getString(context))),
            ),
          ] else
            SearchableDropdown<int>(
              value: _selectedSalesRepId,
              options: _salesReps,
              showSearchBox: false,
              labelText: AppLocale.seller.getString(context),
              isEnabled: !_processingPayments,
              onChanged: (value) {
                setState(() => _selectedSalesRepId = value);
              },
            ),
          const SizedBox(height: CustomSpacer.medium),
          if (_loadingCustomers) const LinearProgressIndicator(),
          Row(
            children: [
              Expanded(
                child: CustomSearchField(
                  options: _customers,
                  controller: _customerController,
                  fieldController: _customerFieldController,
                  labelText: AppLocale.customer.getString(context),
                  searchBy: 'TaxID',
                  searchByText: 'Cédula',
                  enabled: !_processingPayments,
                  onSubmit: (_) => _loadCustomers(),
                  onItemSelected: _selectCustomer,
                  onChanged: (value) {
                    if (_selectedCustomerId != null && value != _selectedCustomerName) {
                      _clearCustomerSelection();
                    }
                  },
                  suffixIcon: _selectedCustomerId == null
                      ? IconButton(tooltip: AppLocale.refresh.getString(context), onPressed: _loadCustomers, icon: const Icon(Icons.search))
                      : IconButton(
                          tooltip: AppLocale.close.getString(context),
                          onPressed: _processingPayments ? null : _clearCustomerSelection,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CustomSpacer.medium),
          if (_selectedCustomerId == null)
            _EmptyState(icon: Icons.person_search_outlined, text: AppLocale.selectCustomerForInvoices.getString(context))
          else if (_loadingInvoices)
            const Center(
              child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()),
            )
          else if (_invoiceError != null)
            _EmptyState(
              icon: Icons.error_outline,
              text: _invoiceError!,
              action: TextButton.icon(
                onPressed: () => _selectCustomer({'id': _selectedCustomerId, 'name': _customerController.text}),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocale.refresh.getString(context)),
              ),
            )
          else if (_invoices.isEmpty)
            _EmptyState(icon: Icons.receipt_long_outlined, text: AppLocale.noCompletedInvoices.getString(context))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 430),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _invoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final invoice = _invoices[index];
                  final selected = _selectedInvoices.containsKey(invoice['id']);
                  return Material(
                    color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.10) : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.25)),
                      ),
                      leading: Icon(selected ? Icons.check_circle : Icons.receipt_outlined, color: Theme.of(context).colorScheme.primary),
                      title: Text('${AppLocale.invoice.getString(context)} ${invoice['documentNo']}'),
                      subtitle: Text(
                        '${AppLocale.outstandingDebt.getString(context)}: '
                        '\$${_money(invoice['outstandingDebt']).toStringAsFixed(2)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _processingPayments ? null : () => _showInvoiceDialog(invoice),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return CustomContainer(
      maxWidthContainer: 320,
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocale.paymentMethods.getString(context), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: CustomSpacer.medium),
          if (_loadingPayments)
            const Center(child: CircularProgressIndicator())
          else if (_paymentMethods.isEmpty)
            _EmptyState(icon: Icons.payments_outlined, text: AppLocale.noPaymentMethods.getString(context))
          else
            ..._paymentMethods.map(
              (method) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextfieldTheme(
                        controlador: _paymentControllers[method['id']],
                        texto: method['name']?.toString(),
                        readOnly: _processingPayments,
                        inputType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: AppLocale.fillWithRemaining.getString(context),
                      onPressed: _processingPayments
                          ? null
                          : () {
                              final methodId = method['id'];
                              final otherAmounts = _paymentControllers.entries
                                  .where((entry) => entry.key != methodId)
                                  .map((entry) => _money(entry.value.text));
                              final remaining = calculateRemainingInvoicePayment(_allocatedValue, otherAmounts);
                              final controller = _paymentControllers[methodId];
                              controller?.text = remaining.toStringAsFixed(2);
                              if (controller != null) {
                                controller.selection = TextSelection.collapsed(offset: controller.text.length);
                              }
                              setState(() {});
                            },
                      icon: const Icon(Icons.attach_money_rounded),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final difference = _allocatedValue - _paymentValue;
    return CustomContainer(
      maxWidthContainer: 360,
      margin: const EdgeInsets.only(top: 24, bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Text(AppLocale.summary.getString(context), style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: CustomSpacer.medium),
          if (_selectedInvoices.isEmpty)
            _EmptyState(icon: Icons.playlist_add_outlined, text: AppLocale.noSelectedInvoices.getString(context))
          else ...[
            ..._selectedInvoices.values.map(
              (invoice) => _SelectedInvoiceCard(
                invoice: invoice,
                onEdit: () => _showInvoiceDialog(invoice),
                onDelete: () {
                  if (!_processingPayments) {
                    setState(() => _selectedInvoices.remove(invoice['id']));
                  }
                },
              ),
            ),
            const Divider(height: 28),
          ],
          _InfoRow(label: AppLocale.selectedInvoices.getString(context), value: '${_selectedInvoices.length}'),
          _InfoRow(label: AppLocale.selectedInvoiceValue.getString(context), value: '\$${_selectedValue.toStringAsFixed(2)}'),
          _InfoRow(label: AppLocale.allocatedPayment.getString(context), value: '\$${_allocatedValue.toStringAsFixed(2)}'),
          _InfoRow(label: AppLocale.paymentMethodTotal.getString(context), value: '\$${_paymentValue.toStringAsFixed(2)}'),
          _InfoRow(label: AppLocale.paymentDifference.getString(context), value: '\$${difference.toStringAsFixed(2)}', emphasized: true),
          const SizedBox(height: CustomSpacer.medium),
          _PaymentStatusBlock(
            totalPaid: _historicalPaidValue,
            outstandingDebt: _outstandingDebtValue,
            progress: _historicalPaymentProgress,
          ),
          const SizedBox(height: CustomSpacer.large),
          if (!_loadingSalesReps && _selectedSalesRepId == null)
            _InlineWarning(text: AppLocale.salesRepRequired.getString(context))
          else if (POS.bankAccountID == null)
            _InlineWarning(text: AppLocale.paymentBankAccountRequired.getString(context))
          else if (_paymentValue > 0 && !_paymentTotalsMatch)
            _InlineWarning(text: AppLocale.invoicePaymentTotalsMismatch.getString(context))
          else if (_usedPaymentMethods.isNotEmpty && !_usedMethodsHaveTenderType)
            _InlineWarning(text: AppLocale.paymentTenderTypeRequired.getString(context)),
          const SizedBox(height: CustomSpacer.small),
          if (_processingPayments)
            const ButtonLoading(fullWidth: true)
          else
            ButtonPrimary(
              fullWidth: true,
              texto: AppLocale.process.getString(context),
              enable: _canProcessPayments,
              onPressed: _canProcessPayments ? _processPayments : null,
            ),
        ],
      ),
    );
  }
}

class _InvoicePaymentDialog extends StatefulWidget {
  const _InvoicePaymentDialog({required this.invoice, this.initialAmount});

  final Map<String, dynamic> invoice;
  final double? initialAmount;

  @override
  State<_InvoicePaymentDialog> createState() => _InvoicePaymentDialogState();
}

class _InvoicePaymentDialogState extends State<_InvoicePaymentDialog> {
  late final TextEditingController _amountController;
  String? _errorText;

  double _money(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmount?.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = _money(_amountController.text);
    final outstandingDebt = _money(widget.invoice['outstandingDebt']);
    if (amount <= 0 || amount > outstandingDebt) {
      setState(() {
        _errorText = AppLocale.invalidInvoicePaymentAmount.getString(context);
      });
      return;
    }
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lines = (widget.invoice['lines'] as List?) ?? const [];
    final total = _money(widget.invoice['grandTotal']);
    final paid = _money(widget.invoice['totalPaid']);
    final debt = _money(widget.invoice['outstandingDebt']);
    final progress = _money(widget.invoice['paymentProgress']);

    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('${AppLocale.invoice.getString(context)} ${widget.invoice['documentNo']}')),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 620, maxHeight: MediaQuery.sizeOf(context).height * 0.72),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light ? Colors.white : colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.outlineVariant),
                  boxShadow: [BoxShadow(color: colors.shadow.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 3))],
                ),
                child: Column(
                  children: [
                    _InfoRow(label: AppLocale.invoiceValue.getString(context), value: '\$${total.toStringAsFixed(2)}', emphasized: true),
                    _PaymentStatusBlock(
                      totalPaid: paid,
                      outstandingDebt: debt,
                      progress: progress,
                      compact: true,
                      highlightOutstanding: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CustomSpacer.large),
              Text(
                AppLocale.invoiceDetail.getString(context),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: CustomSpacer.small),
              if (lines.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(AppLocale.noInvoiceLines.getString(context)))
              else
                _InvoiceLinesTable(lines: lines),
              const SizedBox(height: CustomSpacer.medium),
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: AppLocale.amountToPayInvoice.getString(context),
                  prefixText: '\$ ',
                  helperText: '${AppLocale.outstandingDebt.getString(context)}: \$${debt.toStringAsFixed(2)}',
                  helperStyle: TextStyle(color: colors.error, fontWeight: FontWeight.w600),
                  errorText: _errorText,
                  border: const OutlineInputBorder(),
                  filled: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocale.cancel.getString(context))),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: Icon(widget.initialAmount == null ? Icons.add_rounded : Icons.save),
          label: Text(widget.initialAmount == null ? AppLocale.add.getString(context) : AppLocale.edit.getString(context)),
        ),
      ],
    );
  }
}

class _InvoiceLinesTable extends StatelessWidget {
  const _InvoiceLinesTable({required this.lines});

  final List<dynamic> lines;

  double _money(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _cell(BuildContext context, String text, {TextAlign align = TextAlign.left, bool header = false, bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Text(
        text,
        textAlign: align,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: header || emphasized ? FontWeight.w700 : FontWeight.w400,
          color: header ? Theme.of(context).colorScheme.onSecondaryContainer : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedLines = lines.map((rawLine) => Map<String, dynamic>.from(rawLine as Map)).toList();

    Widget table(double width) {
      return SizedBox(
        width: width,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Table(
            columnWidths: const {0: FlexColumnWidth(), 1: FixedColumnWidth(76), 2: FixedColumnWidth(94), 3: FixedColumnWidth(104)},
            border: TableBorder(horizontalInside: BorderSide(color: colors.outlineVariant)),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(color: colors.secondaryContainer),
                children: [
                  _cell(context, AppLocale.product.getString(context), header: true),
                  _cell(context, AppLocale.quantityShort.getString(context), header: true, align: TextAlign.right),
                  _cell(context, AppLocale.price.getString(context), header: true, align: TextAlign.right),
                  _cell(context, AppLocale.subtotal.getString(context), header: true, align: TextAlign.right),
                ],
              ),
              ...normalizedLines.indexed.map((entry) {
                final index = entry.$1;
                final line = entry.$2;
                final quantity = _money(line['quantity']);
                final price = _money(line['price']);
                return TableRow(
                  decoration: BoxDecoration(
                    color: index.isOdd
                        ? colors.primary.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.08 : 0.16)
                        : Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : colors.surfaceContainerLow,
                  ),
                  children: [
                    _cell(context, (line['productName'] ?? 'Producto').toString(), emphasized: true),
                    _cell(context, quantity.toStringAsFixed(2), align: TextAlign.right),
                    _cell(context, '\$${price.toStringAsFixed(2)}', align: TextAlign.right),
                    _cell(context, '\$${(quantity * price).toStringAsFixed(2)}', align: TextAlign.right, emphasized: true),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: table(560));
  }
}

class _SelectedInvoiceCard extends StatelessWidget {
  const _SelectedInvoiceCard({required this.invoice, required this.onEdit, required this.onDelete});

  final Map<String, dynamic> invoice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  double _money(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLocale.invoice.getString(context)} ${invoice['documentNo']}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(tooltip: AppLocale.edit.getString(context), onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
                IconButton(
                  tooltip: AppLocale.remove.getString(context),
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
            _InfoRow(label: AppLocale.invoiceValue.getString(context), value: '\$${_money(invoice['grandTotal']).toStringAsFixed(2)}'),
            _InfoRow(
              label: AppLocale.amountToPayInvoice.getString(context),
              value: '\$${_money(invoice['amountToPay']).toStringAsFixed(2)}',
              emphasized: true,
            ),
            const SizedBox(height: 8),
            _PaymentStatusBlock(
              totalPaid: _money(invoice['totalPaid']),
              outstandingDebt: _money(invoice['outstandingDebt']),
              progress: _money(invoice['paymentProgress']),
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentStatusBlock extends StatelessWidget {
  const _PaymentStatusBlock({
    required this.totalPaid,
    required this.outstandingDebt,
    required this.progress,
    this.compact = false,
    this.highlightOutstanding = false,
  });

  final double totalPaid;
  final double outstandingDebt;
  final double progress;
  final bool compact;
  final bool highlightOutstanding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(label: AppLocale.totalPaid.getString(context), value: '\$${totalPaid.toStringAsFixed(2)}'),
        if (highlightOutstanding)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).colorScheme.error, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocale.outstandingDebt.getString(context),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.error),
                  ),
                ),
                Text(
                  '\$${outstandingDebt.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          )
        else
          _InfoRow(
            label: AppLocale.outstandingDebt.getString(context),
            value: '\$${outstandingDebt.toStringAsFixed(2)}',
            emphasized: true,
            color: Theme.of(context).colorScheme.error,
          ),
        SizedBox(height: compact ? 6 : 10),
        Semantics(
          label: AppLocale.paymentProgress.getString(context),
          value: '${(progress * 100).toStringAsFixed(0)}%',
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.35),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).brightness == Brightness.light ? Colors.green.shade700 : Colors.greenAccent.shade400,
            ),
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text('${(progress * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.emphasized = false, this.color});

  final String label;
  final String value;
  final bool emphasized;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final baseStyle = emphasized
        ? Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    final style = baseStyle?.copyWith(color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
