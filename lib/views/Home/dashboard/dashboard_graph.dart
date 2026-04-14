// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';
import '../../../API/pos.api.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/toast_message.dart';
import '../order/my_order.dart';
import '../order/my_order_new.dart';
import 'package:fl_chart/fl_chart.dart';

typedef ChartDataLoader = Future<Map<String, double>> Function({required BuildContext context});

class GraphicBarMetricCard extends StatefulWidget {
  final String Function(BuildContext) titleBuilder;
  final ChartDataLoader dataLoader;
  final bool showRefresh;
  final bool showTotal;
  final String? subtitle;
  final Map<String, double> initialData;

  const GraphicBarMetricCard({
    super.key,
    required this.titleBuilder,
    required this.dataLoader,
    this.showRefresh = true,
    this.showTotal = false,
    this.subtitle,
    this.initialData = const {},
  });

  @override
  State<GraphicBarMetricCard> createState() => _GraphicBarMetricCardState();
}

class _GraphicBarMetricCardState extends State<GraphicBarMetricCard> {
  Map<String, double> rawChartData = {};
  bool isLoading = true;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();

    if (widget.initialData.isNotEmpty) {
      rawChartData = Map<String, double>.from(widget.initialData);
      isLoading = false;
    } else {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant GraphicBarMetricCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialData != widget.initialData && widget.initialData.isNotEmpty) {
      setState(() {
        rawChartData = Map<String, double>.from(widget.initialData);
        isLoading = false;
      });
    }
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    rawChartData = await widget.dataLoader(context: context);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _reload() => _load();

  double _totalValue() {
    if (rawChartData.isEmpty) return 0;
    return rawChartData.values.fold(0.0, (sum, value) => sum + value);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalFmt = NumberFormat('#,##0.00', 'en_US');

    final entries = rawChartData.entries.toList();
    final double maxY = rawChartData.isEmpty ? 100 : rawChartData.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              if (widget.showRefresh) const SizedBox(width: 48),

              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.titleBuilder(context),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (widget.subtitle != null && widget.subtitle!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.subtitle!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        ),
                      ),
                  ],
                ),
              ),

              if (widget.showRefresh)
                SizedBox(
                  width: 48,
                  child: IconButton(
                    tooltip: 'Refrescar',
                    icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade500),
                    onPressed: isLoading ? null : _reload,
                  ),
                ),
            ],
          ),
          if (widget.showTotal)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                'Total: ${POS.currencySymbol} ${totalFmt.format(_totalValue())}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: primaryColor),
              ),
            ),
          const SizedBox(height: CustomSpacer.large),
          SizedBox(
            height: 300,
            child: isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!.withOpacity(0.5),
                    highlightColor: Colors.grey[100]!.withOpacity(0.5),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                : rawChartData.isEmpty
                ? Center(
                    child: Text(
                      AppLocale.noDataForFilter.getString(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => isDark ? Colors.grey.shade800 : Colors.blueGrey.shade900,
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${entries[group.x].key}\n',
                                Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '${POS.currencySymbol} ${totalFmt.format(rod.toY)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              );
                            },
                          ),
                          touchCallback: (FlTouchEvent event, barTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                            });
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < entries.length) {
                                  bool showLabel = entries.length < 10 || value.toInt() % (entries.length ~/ 6 + 1) == 0;
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      showLabel ? entries[value.toInt()].key : '',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w500),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              getTitlesWidget: (value, meta) {
                                if (value == 0 || value == maxY) return const SizedBox.shrink();
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    NumberFormat.compact().format(value),
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 5 > 0 ? maxY / 5 : 1, // Previene divisiones entre 0
                          getDrawingHorizontalLine: (value) {
                            return FlLine(color: Theme.of(context).dividerColor.withOpacity(0.1), strokeWidth: 1, dashArray: [4, 4]);
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(entries.length, (index) {
                          final isTouched = index == touchedIndex;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: entries[index].value,
                                width: isTouched ? 22 : 16,
                                gradient: LinearGradient(
                                  colors: isTouched
                                      ? [secondaryColor, secondaryColor.withOpacity(0.7)]
                                      : [primaryColor, primaryColor.withOpacity(0.6)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxY,
                                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 150),
                      swapAnimationCurve: Curves.easeInOut,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class GraphicPieMetricCard extends StatefulWidget {
  final String Function(BuildContext) titleBuilder;
  final ChartDataLoader dataLoader;
  final bool showRefresh;
  final bool showTotal;
  final String? subtitle;
  final Map<String, double> initialData;

  const GraphicPieMetricCard({
    super.key,
    required this.titleBuilder,
    required this.dataLoader,
    this.showRefresh = true,
    this.showTotal = false,
    this.subtitle,
    this.initialData = const {},
  });

  @override
  State<GraphicPieMetricCard> createState() => _GraphicPieMetricCardState();
}

class _GraphicPieMetricCardState extends State<GraphicPieMetricCard> {
  Map<String, double> rawChartData = {};
  bool isLoading = true;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();

    if (widget.initialData.isNotEmpty) {
      rawChartData = Map<String, double>.from(widget.initialData);
      isLoading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    rawChartData = await widget.dataLoader(context: context);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _reload() {
    _load();
  }

  @override
  void didUpdateWidget(covariant GraphicPieMetricCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialData != widget.initialData && widget.initialData.isNotEmpty) {
      setState(() {
        rawChartData = Map<String, double>.from(widget.initialData);
        isLoading = false;
      });
    }
  }

  List<Map<String, Object>> _chartRows() {
    return rawChartData.entries.where((entry) => entry.value > 0).map((entry) => {'category': entry.key, 'value': entry.value}).toList();
  }

  double _totalValue() {
    if (rawChartData.isEmpty) return 0;
    return rawChartData.values.fold(0.0, (sum, value) => sum + value);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _chartRows();
    final colors = <Color>[
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.redAccent,
      Colors.indigo,
    ];
    final totalFmt = NumberFormat('#,##0.00', 'en_US');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              if (widget.showRefresh) const SizedBox(width: 48),

              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.titleBuilder(context),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (widget.subtitle != null && widget.subtitle!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.subtitle!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        ),
                      ),
                  ],
                ),
              ),

              if (widget.showRefresh)
                SizedBox(
                  width: 48,
                  child: IconButton(
                    tooltip: 'Refrescar',
                    icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade500),
                    onPressed: isLoading ? null : _reload,
                  ),
                ),
            ],
          ),
          if (widget.showTotal)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                'Total: ${POS.currencySymbol} ${totalFmt.format(_totalValue())}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
              ),
            ),
          const SizedBox(height: CustomSpacer.large),
          SizedBox(
            height: 320,
            child: isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!.withOpacity(0.5),
                    highlightColor: Colors.grey[100]!.withOpacity(0.5),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                : rows.isEmpty
                ? Center(
                    child: Text(
                      AppLocale.noDataForFilter.getString(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                centerSpaceRadius: 44,
                                sectionsSpace: 2,
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        touchedIndex = -1;
                                        return;
                                      }

                                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sections: List.generate(rows.length, (index) {
                                  final row = rows[index];
                                  final color = colors[index % colors.length];
                                  final value = (row['value'] as num).toDouble();
                                  final total = _totalValue();
                                  final percent = total > 0 ? (value / total) * 100 : 0.0;
                                  final isTouched = index == touchedIndex;

                                  return PieChartSectionData(
                                    color: color,
                                    value: value,
                                    radius: isTouched ? 112 : 98,
                                    title: '${percent.toStringAsFixed(0)}%',
                                    titleStyle: TextStyle(fontSize: isTouched ? 14 : 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  );
                                }),
                              ),
                              swapAnimationDuration: const Duration(milliseconds: 180),
                              swapAnimationCurve: Curves.easeInOut,
                            ),
                            if (touchedIndex >= 0 && touchedIndex < rows.length)
                              Positioned(
                                top: 20,
                                child: IgnorePointer(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade800
                                          : Colors.blueGrey.shade900,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        final row = rows[touchedIndex];
                                        final value = (row['value'] as num).toDouble();
                                        final percent = _totalValue() > 0 ? (value / _totalValue()) * 100 : 0.0;

                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              row['category'].toString(),
                                              textAlign: TextAlign.center,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontWeight: FontWeight.bold) ??
                                                  const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${POS.currencySymbol} ${totalFmt.format(value)}',
                                              textAlign: TextAlign.center,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700) ??
                                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${percent.toStringAsFixed(1)}%',
                                              textAlign: TextAlign.center,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.w500) ??
                                                  const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: List.generate(rows.length, (index) {
                          final row = rows[index];
                          final color = colors[index % colors.length];
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                              ),
                              const SizedBox(width: 6),
                              Text(row['category'].toString(), style: Theme.of(context).textTheme.bodySmall),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class EmptyMetricState extends StatelessWidget {
  final bool showActions;
  const EmptyMetricState({super.key, this.showActions = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      height: 440,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.query_stats_rounded, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
                    const SizedBox(height: 24),

                    Text(
                      "Sin ordenes registradas",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      "¿Listo para realizar tu primera orden?",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),

                    if (showActions) ...[
                      const SizedBox(height: 40),

                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: Icon(Icons.add_shopping_cart, size: 20, color: Theme.of(context).colorScheme.primary),
                                label: Text(
                                  AppLocale.newOrder.getString(context),
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                onPressed: () {
                                  if (POS.docTypesComplete.isEmpty) {
                                    ToastMessage.show(
                                      context: context,
                                      message: AppLocale.noDocTypesAvailable.getString(context),
                                      type: ToastType.help,
                                    );
                                    return;
                                  }

                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Theme.of(context).cardColor,
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                    builder: (BuildContext modalContext) {
                                      final availableDocs = POS.docTypesComplete.where((doc) {
                                        final dynamic rawId = doc['id'];
                                        final int? docTypeId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

                                        return doc['DocSubTypeSO'] != 'RM' && docTypeId != POS.docTypeRefundID;
                                      }).toList();

                                      if (availableDocs.isEmpty) {
                                        return SafeArea(
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Text(
                                              AppLocale.noDocTypesAvailable.getString(context),
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context).textTheme.bodyLarge,
                                            ),
                                          ),
                                        );
                                      }

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
                                              ...availableDocs.map((doc) {
                                                final dynamic rawId = doc['id'];
                                                final int? docTypeId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
                                                final String docName = (doc['name'] ?? doc['Name'] ?? 'Documento').toString();

                                                return ListTile(
                                                  leading: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(Icons.add_shopping_cart, color: Theme.of(context).primaryColor),
                                                  ),
                                                  title: Text(docName, style: Theme.of(context).textTheme.bodyLarge),
                                                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                                  onTap: () {
                                                    Navigator.pop(modalContext);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            OrderNewPage(isRefund: false, doctypeID: docTypeId, orderName: docName),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 12),

                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: Icon(Icons.list_alt, size: 20, color: Theme.of(context).colorScheme.secondary),
                                label: Text(
                                  AppLocale.myOrders.getString(context),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderListPage()));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
