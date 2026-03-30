// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';
import '../../../API/pos.api.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/custom_spacer.dart';
import '../../../Widgets/GlassDesign.dart';

enum ChartType { line, bar, pie }

typedef ChartDataLoader = Future<Map<String, double>> Function({required BuildContext context});

class MetricCard extends StatefulWidget {
  final String Function(BuildContext) titleBuilder;
  final ChartDataLoader dataLoader;
  final ChartType chartType;
  final String? xAxisLabel;
  final String? yAxisLabel;
  final bool showRefresh;

  const MetricCard({super.key, required this.titleBuilder, required this.dataLoader, this.chartType = ChartType.line, this.xAxisLabel, this.yAxisLabel, this.showRefresh = true});

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  List<String> dataKeys = [];
  Map<String, double> rawChartData = {};
  bool isLoading = true;

  late ChartType _currentChartType;
  int _touchedPieIndex = -1;

  final NumberFormat _moneyFmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _currentChartType = widget.chartType;
    _load();
  }

  String _formatMoneyFull(double value) {
    final formatted = _moneyFmt.format(value);
    return '${POS.currencySymbol} $formatted';
  }

  String _formatY(double value) {
    final abs = value.abs();
    if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }

  double _niceInterval(double maxY) {
    if (maxY <= 0) return 1;
    final double rough = maxY / 5.0;
    final num pow10 = pow(10, (log(rough) / ln10).floor());
    final double normalized = rough / pow10;
    double step = (normalized < 1.5)
        ? 1
        : (normalized < 3)
        ? 2
        : (normalized < 7)
        ? 5
        : 10;
    return step * pow10;
  }

  double _gridInterval() {
    if (rawChartData.isEmpty) return 1;
    final double maxY = rawChartData.values.reduce((a, b) => a > b ? a : b);
    return _niceInterval(maxY);
  }

  double _maxYWithPadding() {
    if (rawChartData.isEmpty) return 0;
    final double maxVal = rawChartData.values.reduce((a, b) => a > b ? a : b);
    final double step = _niceInterval(maxVal);
    return ((maxVal) / step).ceil() * step + (step * 0.2);
  }

  double _tickMinWidth() => _currentChartType == ChartType.pie ? 0 : 72.0;

  double _computeChartWidth(BuildContext context) {
    final screen = MediaQuery.of(context).size.width - 48;
    if (_currentChartType == ChartType.pie || dataKeys.isEmpty) return screen;
    final desired = (dataKeys.length * _tickMinWidth()) + 32.0;
    return desired > screen ? desired : screen;
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    rawChartData = await widget.dataLoader(context: context);
    dataKeys = rawChartData.keys.toList();
    setState(() => isLoading = false);
  }

  void _reload() {
    setState(() => _touchedPieIndex = -1);
    _load();
  }

  Widget _buildTypeToggle(ChartType type, IconData icon) {
    final isSelected = _currentChartType == type;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400;

    return InkWell(
      onTap: () {
        if (!mounted) return;
        setState(() {
          _currentChartType = type;
          _touchedPieIndex = -1;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildChart() {
    final textColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    final gridColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.1);
    final tooltipBgColor = Theme.of(context).colorScheme.onSurface;
    final tooltipTextColor = Theme.of(context).colorScheme.surface;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    final linePoints = <FlSpot>[];
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < dataKeys.length; i++) {
      final val = rawChartData[dataKeys[i]] ?? 0;
      linePoints.add(FlSpot(i.toDouble(), val));

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              width: 22,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              gradient: LinearGradient(colors: [primaryColor, secondaryColor], begin: Alignment.bottomCenter, end: Alignment.topCenter),
            ),
          ],
        ),
      );
    }

    if (_currentChartType == ChartType.bar) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          groupsSpace: 8,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => tooltipBgColor,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${dataKeys[group.x.toInt()]}\n',
                  TextStyle(color: tooltipTextColor.withOpacity(0.8), fontSize: 12),
                  children: [
                    TextSpan(
                      text: _formatMoneyFull(rod.toY),
                      style: TextStyle(color: tooltipTextColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _gridInterval(),
            getDrawingHorizontalLine: (value) => FlLine(color: gridColor, strokeWidth: 1, dashArray: [5, 5]),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= dataKeys.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(dataKeys[i], style: TextStyle(color: textColor, fontSize: 11)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: _gridInterval(),
                getTitlesWidget: (value, meta) => Text(_formatY(value), style: TextStyle(color: textColor, fontSize: 11)),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          maxY: max(1.0, _maxYWithPadding()),
          barGroups: barGroups,
        ),
        duration: Duration.zero,
      );
    } else if (_currentChartType == ChartType.pie) {
      final List<Color> pieColors = [primaryColor, secondaryColor, Colors.orange.shade400, Colors.purple.shade400, Colors.teal.shade400, Colors.redAccent];
      final total = rawChartData.values.fold<double>(0, (a, b) => a + b);
      final sections = <PieChartSectionData>[];

      for (int i = 0; i < dataKeys.length; i++) {
        final val = rawChartData[dataKeys[i]] ?? 0;
        final isTouched = i == _touchedPieIndex;
        sections.add(
          PieChartSectionData(
            color: pieColors[i % pieColors.length],
            value: val > 0 ? val : 0.001,
            title: total > 0 ? '${((val / total) * 100).toStringAsFixed(isTouched ? 1 : 0)}%' : '0%',
            radius: isTouched ? 65.0 : 55.0,
            titleStyle: TextStyle(
              fontSize: isTouched ? 16 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
            ),
          ),
        );
      }

      return PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              if (!mounted) return;
              setState(() {
                if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                  _touchedPieIndex = -1;
                  return;
                }
                _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          sections: sections,
          centerSpaceRadius: 40,
        ),
        duration: Duration.zero,
      );
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes
              .map(
                (index) => TouchedSpotIndicatorData(
                  FlLine(color: Theme.of(context).dividerColor.withOpacity(0.5), strokeWidth: 1.5, dashArray: [4, 4]),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: Theme.of(context).colorScheme.surface, strokeWidth: 3, strokeColor: primaryColor),
                  ),
                ),
              )
              .toList(),
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => const Color(0xFF1A1A1A),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            tooltipBorderRadius: BorderRadius.circular(12),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) => touchedSpots
                .map(
                  (spot) => LineTooltipItem(
                    '${dataKeys[spot.x.toInt()]}\n',
                    const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: _formatMoneyFull(spot.y),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _gridInterval(),
          getDrawingHorizontalLine: (value) => FlLine(color: gridColor.withOpacity(0.4), strokeWidth: 1, dashArray: [5, 5]),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final nearest = value.roundToDouble();
                if ((value - nearest).abs() > 0.01) return const SizedBox();
                final index = nearest.toInt();
                if (index < 0 || index >= dataKeys.length) return const SizedBox();
                final step = (dataKeys.length / 8).ceil();
                if (step > 1 && index % step != 0 && index != dataKeys.length - 1 && index != 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(dataKeys[index], style: TextStyle(color: textColor, fontSize: 11)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 45,
              showTitles: true,
              interval: _gridInterval(),
              getTitlesWidget: (value, meta) => Text(_formatY(value), style: TextStyle(color: textColor, fontSize: 11)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: linePoints.length > 1 ? linePoints.length.toDouble() - 1 : 1,
        minY: 0,
        maxY: max(1.0, _maxYWithPadding()),
        lineBarsData: [
          LineChartBarData(
            spots: linePoints,
            isCurved: true,
            curveSmoothness: 0.35,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            gradient: LinearGradient(colors: [primaryColor, secondaryColor], begin: Alignment.centerLeft, end: Alignment.centerRight),
            shadow: const Shadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: [primaryColor.withOpacity(0.2), primaryColor.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    // 👇 USAMOS TU CONTENEDOR GLASS ULTRA PREMIUM OFICIAL
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👇 Estructura apilada y centrada que construimos
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.titleBuilder(context),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypeToggle(ChartType.line, Icons.show_chart),
                  _buildTypeToggle(ChartType.bar, Icons.bar_chart),
                  _buildTypeToggle(ChartType.pie, Icons.pie_chart),
                  if (widget.showRefresh) ...[const SizedBox(width: 8), IconButton(tooltip: 'Refrescar', icon: const Icon(Icons.refresh, size: 20), onPressed: isLoading ? null : _reload)],
                ],
              ),
            ],
          ),

          const SizedBox(height: CustomSpacer.large),

          SizedBox(
            height: _currentChartType == ChartType.pie ? 260 : 240,
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
                : (dataKeys.isEmpty)
                ? Center(
                    child: Text("No hay datos", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: _currentChartType == ChartType.pie ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: _computeChartWidth(context),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_currentChartType),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.90 + (0.10 * value),
                            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.only(top: 16, right: _currentChartType == ChartType.pie ? 0 : 24),
                          child: _buildChart(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
