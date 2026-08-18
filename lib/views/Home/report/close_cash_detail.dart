// lib/views/Home/report/close_cash_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/button.widget.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/shared/toast_message.dart';
import '../../../API/endpoint.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/footer.dart';
import '../../../shared/loading_container.dart';
import 'report_print.dart';
import 'report_funtions.dart';
import 'close_cash_print_pos_funtions.dart';
import 'close_cash_print_carta_funtions.dart';
import 'package:printing/printing.dart';

class CloseCashDetailPage extends StatefulWidget {
  final Map<String, dynamic> record;

  const CloseCashDetailPage({super.key, required this.record});

  @override
  State<CloseCashDetailPage> createState() => _CloseCashDetailPageState();
}

class _CloseCashDetailPageState extends State<CloseCashDetailPage> {
  static const Map<String, Map<String, Object>> _docStatusMap = {
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

  bool _loading = true;
  String? _warning;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dynamic rawId = widget.record['id'] ?? widget.record['Record_ID'];
    final int? id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    if (id == null || id <= 0) {
      setState(() {
        _loading = false;
        _warning = 'No se pudo determinar el ID del cierre de caja.';
      });
      return;
    }

    try {
      final res = await fetchCloseCash(context: context, closeCashId: id);

      if (!mounted) return;

      setState(() {
        _detail = res;
        _loading = false;
        if (res == null) {
          _warning = 'No se pudo cargar el detalle completo. Mostrando información básica.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _warning = 'Error cargando detalle. Mostrando información básica.';
      });
    }
  }

  Future<void> _showCloseCashDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocale.closeCash.getString(context), style: Theme.of(context).textTheme.bodyLarge),

              content: Text('¿Desea realizar el cierre de caja?'),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancelar')),

                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      _loading = true;
                    });
                    final res = await updateCloseCashStatus(cdsCloseCashID: widget.record['id'] ?? widget.record['Record_ID']);
                    if (res['success'] == true) {
                      await _load();
                    } else {
                      if (!mounted) return;
                      ToastMessage.show(context: context, message: 'Error al cerrar el cierre de caja.', type: ToastType.failure);

                      setState(() {
                        _loading = false;
                      });
                    }
                  },
                  child: const Text('Si'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _printTicketConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocale.confirmPrintTicket.getString(context)),
        content: Text(AppLocale.printTicketMessage.getString(context)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    final Map<String, dynamic> data = _detail ?? widget.record;

    final terminal = (data['C_POS_ID']?['name'] ?? '---').toString();
    final rep = (data['SalesRep_ID']?['name'] ?? '---').toString();
    final String dateTrx = (data['DateTrx'] ?? '').toString();
    final String dateFrom = (data['DateFrom'] ?? '').toString();
    final int totalOrders = (data['QtyOrders'] ?? 0) as int;

    final double taxBase = _toDouble(data['TaxBaseAmt'] ?? 0);
    final double taxAmt = _toDouble(data['TaxAmt'] ?? 0);
    final double exemptAmt = _toDouble(data['ExemptAmt'] ?? 0);
    final double totalOrdersAmt = _toDouble(data['TotalOrdersAmt'] ?? 0);
    final double grandTotal = _toDouble(data['GrandTotal'] ?? 0);

    // devoluciones
    final int totalReturns = (data['QtyReturns'] ?? 0) as int;
    final double returnTaxBase = _toDouble(data['ReturnTaxBaseAmt'] ?? 0);
    final double returnTaxAmt = _toDouble(data['ReturnTaxAmt'] ?? 0);
    final double returnExemptAmt = _toDouble(data['ReturnExemptAmt'] ?? 0);
    final double totalReturnsAmt = _toDouble(data['TotalReturnsAmt'] ?? 0);

    // flags
    final bool processed = (data['Processed'] ?? false) == true;

    final List<dynamic> payments = (data['payments'] ?? []) as List<dynamic>;
    final String? docStatus = (data['DocStatus'] as String?)?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.closeCash.getString(context)),
      ),
      drawer: MenuDrawer(),
      bottomNavigationBar: CustomFooter(),
      body: Center(
        child: _loading
            ? LoadingContainer()
            : CustomContainer(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_warning != null) ...[Text(_warning!, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 8)],

                      _buildHeader(context: context, isMobile: isMobile, terminal: terminal, rep: rep, dateTrx: dateTrx.isEmpty ? '---' : dateTrx, dateFrom: dateFrom.isEmpty ? '---' : dateFrom, docStatus: docStatus, processed: processed),
                      const SizedBox(height: CustomSpacer.large),

                      Text("Resumen", style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: CustomSpacer.small),

                      isMobile
                          ? Column(
                              children: [
                                _buildTotalsCard(context: context, title: "Órdenes", rows: [_kv("Cantidad de órdenes", "$totalOrders"), _kv("Total base del impuesto", _money(taxBase)), _kv("Total impuesto", _money(taxAmt)), _kv("Total exento", _money(exemptAmt)), _kv("Total órdenes", _money(totalOrdersAmt)), _kv("Gran Total", _money(grandTotal))]),
                                const SizedBox(height: 12),
                                _buildTotalsCard(context: context, title: "Devoluciones", rows: [_kv("Cantidad de devoluciones", "$totalReturns"), _kv("Total base del impuesto (devolución)", _money(returnTaxBase)), _kv("Total impuesto (devolución)", _money(returnTaxAmt)), _kv("Total exento (devolución)", _money(returnExemptAmt)), _kv("Total devoluciones", _money(totalReturnsAmt))]),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTotalsCard(context: context, title: "Órdenes", rows: [_kv("Cantidad de órdenes", "$totalOrders"), _kv("Total base del impuesto", _money(taxBase)), _kv("Total impuesto", _money(taxAmt)), _kv("Total exento", _money(exemptAmt)), _kv("Total órdenes", _money(totalOrdersAmt))]),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTotalsCard(context: context, title: "Devoluciones", rows: [_kv("Cantidad de devoluciones", "$totalReturns"), _kv("Total base del impuesto (devolución)", _money(returnTaxBase)), _kv("Total impuesto (devolución)", _money(returnTaxAmt)), _kv("Total exento (devolución)", _money(returnExemptAmt)), _kv("Total devoluciones", _money(totalReturnsAmt))]),
                                ),
                              ],
                            ),

                      const SizedBox(height: CustomSpacer.small),

                      _buildGrandTotalBanner(context: context, amount: grandTotal),

                      const SizedBox(height: CustomSpacer.large),

                      Text(AppLocale.paymentMethods.getString(context), style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: CustomSpacer.small),

                      if (payments.isEmpty)
                        Text(AppLocale.noData.getString(context), style: Theme.of(context).textTheme.bodySmall)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: payments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final p = payments[index] as Map<String, dynamic>;

                            final dynamic tenderField = p['C_POSTenderType_ID'] ?? p['TenderType'] ?? p['tender'] ?? p['PaymentMethod'];

                            final String tenderName = (tenderField is Map) ? (tenderField['identifier'] ?? tenderField['name'] ?? '---').toString() : tenderField?.toString() ?? '---';

                            final double amt = _toDouble(p['PayAmt'] ?? p['Amount'] ?? p['Amt'] ?? 0);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.25), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(tenderName, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(_money(amt), style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            );
                          },
                        ),
                      if (!processed) ...[const SizedBox(height: CustomSpacer.large), ButtonPrimary(texto: 'Cerrar Caja', fullWidth: true, icono: Icons.lock_outline, onPressed: _showCloseCashDialog)],
                      const SizedBox(height: CustomSpacer.large),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.print, size: 20, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Imprimir Cierre de Caja',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ButtonPrimary(
                                    texto: 'Carta',
                                    icono: Icons.print_outlined,
                                    onPressed: () async {
                                      final confirm = await _printTicketConfirmation(context);
                                      if (confirm == true) {
                                        if (!mounted) return;
                                        final Map<String, dynamic> data = _detail ?? widget.record;
                                        final cartaBytes = await generateCloseCashCartaTicket(data);
                                        await Printing.sharePdf(bytes: cartaBytes, filename: 'Cierre de Caja_${widget.record['id'] ?? widget.record['Record_ID']}.pdf');
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ButtonPrimary(
                                    texto: 'POS 80mm',
                                    icono: Icons.receipt_long,
                                    onPressed: () async {
                                      final confirm = await _printTicketConfirmation(context);
                                      if (confirm == true) {
                                        if (!mounted) return;
                                        final Map<String, dynamic> data = _detail ?? widget.record;
                                        final ticketBytes = await generateCloseCashPOSTicket(data);
                                        await Printing.sharePdf(bytes: ticketBytes, filename: 'Cierre de Caja_${widget.record['id'] ?? widget.record['Record_ID']}.pdf');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ---------------- UI Helpers ----------------

  Widget _buildHeader({required BuildContext context, required bool isMobile, required String terminal, required String rep, required String dateTrx, required String dateFrom, required String? docStatus, required bool processed}) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconLine(context: context, icon: Icons.point_of_sale_outlined, label: "Terminal PDV", value: terminal, isMobile: isMobile),
        const SizedBox(height: 10),
        _iconLine(context: context, icon: Icons.event_outlined, label: "Desde Fecha", value: dateFrom.isEmpty ? "---" : dateFrom, isMobile: isMobile),
        const SizedBox(height: 10),
        _flagPill(context: context, icon: processed ? Icons.check_circle_outline : Icons.radio_button_unchecked, label: processed ? "Procesado" : "No procesado", color: processed ? Colors.green : Colors.grey),
      ],
    );

    final right = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        _iconLine(context: context, icon: Icons.badge_outlined, label: "Representante Compañía", value: rep, isMobile: isMobile, alignEnd: !isMobile),
        const SizedBox(height: 10),
        _iconLine(context: context, icon: Icons.schedule_outlined, label: "Fecha Transacción", value: dateTrx.isEmpty ? "---" : dateTrx, isMobile: isMobile, alignEnd: !isMobile),
        const SizedBox(height: 10),
        if (docStatus != null && docStatus.isNotEmpty) _buildDocStatusPill(context, docStatus),
      ],
    );

    if (isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 12), right]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildTotalsCard({required BuildContext context, required String title, required List<MapEntry<String, String>> rows}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...rows.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(e.key, style: Theme.of(context).textTheme.bodySmall)),
                  const SizedBox(width: 12),
                  Text(e.value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalBanner({required BuildContext context, required double amount}) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.primary.withOpacity(0.10);
    final border = theme.colorScheme.primary.withOpacity(0.25);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Gran Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Text(
            _money(amount),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDocStatusPill(BuildContext context, String statusCode) {
    final meta = _docStatusMap[statusCode] ?? {'label': statusCode, 'color': Theme.of(context).colorScheme.primary, 'icon': Icons.flag_outlined};

    final Color baseColor = (meta['color'] as Color?) ?? Theme.of(context).colorScheme.primary;
    final Color bgColor = baseColor.withOpacity(0.12);
    final String label = meta['label'] as String? ?? statusCode;
    final IconData icon = (meta['icon'] as IconData?) ?? Icons.flag_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Widget _flagPill({required BuildContext context, required IconData icon, required String label, required Color color}) {
    final Color bg = color.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _iconLine({required BuildContext context, required IconData icon, required String label, required String value, required bool isMobile, bool alignEnd = false, double iconGap = 10}) {
    final textAlign = alignEnd ? TextAlign.right : TextAlign.left;

    final labelWidget = Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      textAlign: textAlign,
    );

    final valueWidget = Text(value, style: Theme.of(context).textTheme.bodyMedium, textAlign: textAlign);

    if (alignEnd) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: isMobile ? 18 : 22),
                SizedBox(width: iconGap),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [labelWidget, const SizedBox(height: 2), valueWidget]),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(icon, size: isMobile ? 18 : 22),
        SizedBox(width: iconGap),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [labelWidget, const SizedBox(height: 2), valueWidget]),
        ),
      ],
    );
  }

  // ---------------- Data Helpers ----------------

  static MapEntry<String, String> _kv(String k, String v) => MapEntry(k, v);

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '');
    return double.tryParse(s) ?? 0.0;
  }

  static String _money(double v) => "\$${v.toStringAsFixed(2)}";
}
