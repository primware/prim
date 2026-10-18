import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/views/Home/dashboard/dashboard_view.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/glass_switch.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/footer.dart';
import '../../../shared/shimmer_list.dart';
import 'close_cash_detail.dart';
import 'close_cash_dates.dart';
import '../../../shared/format_amount.dart';
import '../../../API/pos.api.dart';
import 'report_funtions.dart';

class CloseCashPage extends StatefulWidget {
  const CloseCashPage({super.key});

  @override
  State<CloseCashPage> createState() => _CloseCashPageState();
}

class _CloseCashPageState extends State<CloseCashPage> {
  bool _isLoading = true, onlyMyRecords = true;

  List<Map<String, dynamic>> _records = [];
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

  // Pill que muestra el estado del documento (DocStatus) en español
  Widget _buildDocStatusPill(Map<String, dynamic> record) {
    final String? statusCode = record['DocStatus'] as String?;
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

  Widget _buildRecordsList(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return Center(child: Text(AppLocale.errorNoRecords.getString(context)));
    }
    return Column(
      children: records.map((record) {
        return GestureDetector(
          onTap: () async {
            final refreshed = await Navigator.push(context, MaterialPageRoute(builder: (_) => CloseCashDetailPage(record: record)));

            if (refreshed == true) {
              _fetchRecords();
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _recordField(
                    Icons.point_of_sale_outlined,
                    AppLocale.terminal.getString(context),
                    record['C_POS_ID']?['name']?.toString() ?? '---',
                    prominent: true,
                  ),
                  const SizedBox(height: 10),
                  _recordField(
                    Icons.person_outline,
                    AppLocale.user.getString(context),
                    record['SalesRep_ID']?['name']?.toString() ?? '---',
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final from = _dateBlock(AppLocale.closeCashFrom.getString(context), record['DateFrom']);
                      final until = _dateBlock(AppLocale.closeCashUntil.getString(context), record['DateTrx']);
                      if (constraints.maxWidth < 420) {
                        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [from, const SizedBox(height: 8), until]);
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: from),
                          const SizedBox(width: 12),
                          Expanded(child: until),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildDocStatusPill(record),
                      Text(
                        '${AppLocale.orders.getString(context)}: ${record['TotalOrders'] ?? 0}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(AppLocale.total.getString(context), style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '${POS.currencySymbol ?? '\$'}${formatAmount(num.tryParse(record['GrandTotal']?.toString() ?? ''))}',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _recordField(IconData icon, String label, String value, {bool prominent = false}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(
                value,
                style: (prominent ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)?.copyWith(
                  fontWeight: prominent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateBlock(String label, dynamic value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(formatCloseCashDateUI(value?.toString() ?? ''), style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);

    final result = await fetchRecords(context: context, onlyMyRecords: onlyMyRecords);
    setState(() {
      _records = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocale.mycloseCashs.getString(context))),
        drawer: MenuDrawer(),

        bottomNavigationBar: CustomFooter(),
        body: SingleChildScrollView(
          child: Center(
            child: CustomContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocale.onlyMyRecords.getString(context),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      GlassSwitch(
                        value: onlyMyRecords,
                        onChanged: (newValue) {
                          setState(() {
                            onlyMyRecords = newValue;
                            _fetchRecords();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isLoading ? ShimmerList(separation: CustomSpacer.medium) : _buildRecordsList(_records),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
