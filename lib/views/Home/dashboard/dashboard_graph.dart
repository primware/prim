// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';
import '../../../API/pos.api.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/custom_spacer.dart';
import 'package:graphic/graphic.dart';
import '../order/my_order.dart';
import '../order/my_order_new.dart';
import 'package:fl_chart/fl_chart.dart';

typedef ChartDataLoader = Future<Map<String, double>> Function({required BuildContext context});

class GraphicBarMetricCard extends StatefulWidget {
  final String Function(BuildContext) titleBuilder;
  final ChartDataLoader dataLoader;
  final bool showRefresh;
  final bool showTotal;

  const GraphicBarMetricCard({super.key, required this.titleBuilder, required this.dataLoader, this.showRefresh = true, this.showTotal = false});

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
    _load();
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
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // 👇 1. Centramos los elementos de la columna
        children: [
          Row(
            children: [
              if (widget.showRefresh) const SizedBox(width: 48),

              Expanded(
                child: Text(
                  widget.titleBuilder(context),
                  textAlign: TextAlign.center, // 👇 2. Centramos el texto del título
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                textAlign: TextAlign.center, // 👇 3. Centramos el texto del Total
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
                    child: Text(AppLocale.noDataForFilter.getString(context), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
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
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '${POS.currencySymbol} ${totalFmt.format(rod.toY)}',
                                    style: TextStyle(color: secondaryColor, fontWeight: FontWeight.w600, fontSize: 14),
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
                                  child: Text(NumberFormat.compact().format(value), style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
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
                                gradient: LinearGradient(colors: isTouched ? [secondaryColor, secondaryColor.withOpacity(0.7)] : [primaryColor, primaryColor.withOpacity(0.6)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                                backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY, color: Theme.of(context).dividerColor.withOpacity(0.05)),
                              ),
                            ],
                          );
                        }),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 350),
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

  const GraphicPieMetricCard({super.key, required this.titleBuilder, required this.dataLoader, this.showRefresh = true});

  @override
  State<GraphicPieMetricCard> createState() => _GraphicPieMetricCardState();
}

class _GraphicPieMetricCardState extends State<GraphicPieMetricCard> {
  Map<String, double> rawChartData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  List<Map<String, Object>> _chartRows() {
    return rawChartData.entries.where((entry) => entry.value > 0).map((entry) => {'category': entry.key, 'value': entry.value}).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _chartRows();
    final colors = <Color>[Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.tertiary, Colors.orange, Colors.teal, Colors.purple, Colors.redAccent, Colors.indigo];

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
          Text(
            widget.titleBuilder(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (widget.showRefresh)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [IconButton(tooltip: 'Refrescar', icon: const Icon(Icons.refresh, size: 20), onPressed: isLoading ? null : _reload)],
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
                    child: Text(AppLocale.noDataForFilter.getString(context), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Chart(
                          data: rows,
                          variables: {
                            'category': Variable(accessor: (Map map) => map['category'] as String),
                            'value': Variable(accessor: (Map map) => map['value'] as num),
                          },
                          transforms: [Proportion(variable: 'value', as: 'percent')],
                          marks: [
                            IntervalMark(
                              position: Varset('percent') / Varset('category'),
                              color: ColorEncode(variable: 'category', values: colors),
                              label: LabelEncode(
                                encoder: (tuple) => Label(
                                  tuple['category']?.toString(),
                                  LabelStyle(
                                    textStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          coord: PolarCoord(transposed: true, dimCount: 1, startRadius: 0.25),
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
      width: double.infinity,
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
                      "No hay ventas registradas",
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
                          constraints: const BoxConstraints(maxWidth: 320), // Límite de ancho para pantallas grandes
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch, // Se estiran, pero solo hasta 320px
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
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
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderNewPage()));
                                },
                              ),

                              const SizedBox(height: 12),

                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: Icon(Icons.list_alt, size: 20, color: Theme.of(context).colorScheme.secondary),
                                label: Text(
                                  AppLocale.myOrders.getString(context),
                                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 16),
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
