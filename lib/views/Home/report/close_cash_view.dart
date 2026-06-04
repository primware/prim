import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/views/Home/dashboard/dashboard_view.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_checkbox.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/footer.dart';
import '../../../shared/shimmer_list.dart';
import 'close_cash_detail.dart';
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
    'CO': {
      'label': 'Completado',
      'color': Colors.green,
      'icon': Icons.check_circle_outline,
    },
    'CL': {
      'label': 'Cerrado',
      'color': Colors.blueGrey,
      'icon': Icons.lock_outline,
    },
    'VO': {
      'label': 'Anulado',
      'color': Colors.red,
      'icon': Icons.cancel_outlined,
    },
    'IP': {
      'label': 'En proceso',
      'color': Colors.orange,
      'icon': Icons.hourglass_bottom,
    },
    'PR': {
      'label': 'Preparado',
      'color': Colors.orange,
      'icon': Icons.hourglass_bottom,
    },
    'WC': {
      'label': 'Esperando completar',
      'color': Colors.orangeAccent,
      'icon': Icons.hourglass_top,
    },
    'AP': {
      'label': 'Aprobado',
      'color': Colors.blue,
      'icon': Icons.thumb_up_outlined,
    },
    'RJ': {
      'label': 'Rechazado',
      'color': Colors.redAccent,
      'icon': Icons.thumb_down_outlined,
    },
  };

  // Pill que muestra el estado del documento (DocStatus) en español
  Widget _buildDocStatusPill(Map<String, dynamic> record) {
    final String? statusCode = record['DocStatus'] as String?;
    if (statusCode == null) {
      return const SizedBox.shrink();
    }

    final meta =
        _docStatusMap[statusCode] ??
        {
          'label': statusCode,
          'color': Theme.of(context).colorScheme.primary,
          'icon': Icons.flag_outlined,
        };

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
            style: TextStyle(
              fontSize: 12,
              color: baseColor,
              fontWeight: FontWeight.w600,
            ),
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
            final refreshed = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CloseCashDetailPage(record: record),
              ),
            );

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
            child: ListTile(
              title: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: CustomSpacer.small),
                  Expanded(
                    child: Text(
                      '${record['SalesRep_ID']['name'] ?? ''} - ${record['C_POS_ID']['name']} (# ${record['TotalOrders']})',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      Expanded(
                        child: Text(
                          record['GrandTotal'].toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      Expanded(
                        child: Text(
                          '${record['DateTrx'] ?? ''} /  ${record['DateFrom'] ?? ''}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildDocStatusPill(record),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);

    final result = await fetchRecords(
      context: context,
      onlyMyRecords: onlyMyRecords,
    );
    setState(() {
      _records = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
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
                  CustomCheckbox(
                    value: onlyMyRecords,
                    text: AppLocale.onlyMyRecords.getString(context),
                    onChanged: (newValue) {
                      setState(() {
                        onlyMyRecords = newValue;
                        _fetchRecords();
                      });
                    },
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isLoading
                      ? ShimmerList(separation: CustomSpacer.medium)
                      : _buildRecordsList(_records),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
