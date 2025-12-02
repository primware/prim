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

enum ChartType { line, bar, pie }

typedef ChartDataLoader =
    Future<Map<String, double>> Function({required BuildContext context});

/// Reusable metric card that supports multiple chart types (line, bar, pie).
class MetricCard extends StatefulWidget {
  final String Function(BuildContext) titleBuilder;
  final ChartDataLoader dataLoader; // returns Map<X, Y>
  final ChartType chartType;
  final String? xAxisLabel; // eje X label
  final String? yAxisLabel; // eje Y label
  final bool showRefresh;

  const MetricCard({
    super.key,
    required this.titleBuilder,
    required this.dataLoader,
    this.chartType = ChartType.line,
    this.xAxisLabel,
    this.yAxisLabel,
    this.showRefresh = true,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  List<String> dataKeys = [];
  List<FlSpot> points = [];
  List<BarChartGroupData> barGroups = [];
  List<PieChartSectionData> pieSections = [];
  bool isLoading = true;

  final NumberFormat _moneyFmt = NumberFormat('#,##0.00', 'en_US');

  String _formatMoneyFull(double value) {
    final formatted = _moneyFmt.format(value);
    return '${POS.currencySymbol} $formatted';
  }

  String _formatY(double value) {
    final abs = value.abs();
    String formatted;
    if (abs >= 1000000) {
      formatted = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (abs >= 1000) {
      formatted = '${(value / 1000).toStringAsFixed(0)}k';
    } else {
      formatted = value.toStringAsFixed(0);
    }
    return '${POS.currencySymbol} $formatted';
  }

  double _niceInterval(double maxY) {
    if (maxY <= 0) return 1;
    // choose rough 5 steps
    final double rough = maxY / 5.0;
    final num pow10 = pow(10, (log(rough) / ln10).floor());
    final double normalized = rough / pow10;
    double step;
    if (normalized < 1.5) {
      step = 1;
    } else if (normalized < 3) {
      step = 2;
    } else if (normalized < 7) {
      step = 5;
    } else {
      step = 10;
    }
    return step * pow10;
  }

  double _gridInterval() {
    if (points.isEmpty) return 1;
    final double maxY = points.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    return _niceInterval(maxY);
  }

  double _maxYWithPadding() {
    if (points.isEmpty) return 0;
    final double maxVal = points
        .map((e) => e.y)
        .reduce((a, b) => a > b ? a : b);
    final double step = _niceInterval(maxVal);
    // Round up to next tick and add a small headroom so the top label isn’t clipped
    final double rounded = ((maxVal) / step).ceil() * step;
    return rounded + step * 0.5; // 20% of a step as headroom
  }

  // --- Horizontal scroll helpers ---
  double _tickMinWidth() {
    if (widget.chartType == ChartType.pie) return 0; // not used
    return 72.0;
  }

  double _computeChartWidth(BuildContext context) {
    if (widget.chartType == ChartType.pie) {
      return MediaQuery.of(context).size.width; // no scroll for pie
    }
    final screen = MediaQuery.of(context).size.width * 0.8;
    if (dataKeys.isEmpty) return screen;
    // sin tope; deja crecer para que no se monten las etiquetas
    final desired = (dataKeys.length * _tickMinWidth()) + 32.0; // padding extra
    return desired > screen ? desired : screen;
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    final rawData = await widget.dataLoader(context: context);
    final groupedData = rawData;

    // Respetar el orden provisto por el dataLoader (ya viene cronológico)
    final keys = groupedData.keys.toList();

    // Build line points
    final linePoints = <FlSpot>[];
    double xIndex = 0;
    for (var k in keys) {
      linePoints.add(FlSpot(xIndex, (groupedData[k] ?? 0).toDouble()));
      xIndex++;
    }

    // Build bar groups
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < keys.length; i++) {
      final y = (groupedData[keys[i]] ?? 0).toDouble();
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: y,
              width: 14,
              borderRadius: BorderRadius.circular(4),
              // Forzar color sólido igual al de la línea (algunas versiones ignoran `color`)
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    // Build pie sections
    final total = groupedData.values.fold<double>(
      0,
      (a, b) => a + (b.toDouble()),
    );
    final sections = <PieChartSectionData>[];
    for (int i = 0; i < keys.length; i++) {
      final label = keys[i];
      final value = (groupedData[label] ?? 0).toDouble();
      final pct = total == 0 ? 0 : (value / total) * 100;
      sections.add(
        PieChartSectionData(
          value: value,
          title: '${pct.toStringAsFixed(0)}%',
          radius: 50,
        ),
      );
    }

    setState(() {
      dataKeys = keys;
      points = linePoints;
      barGroups = groups;
      pieSections = sections;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _reload() {
    _load();
  }

  Widget _withAlwaysOnLabels({required Widget chart, required bool forBars}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double edgePad =
            20.0; // espacio extra para que no se corten los extremos
        final innerLeft =
            50.0 +
            edgePad; // debe corresponder al reservedSize de los leftTitles
        final innerRight = edgePad;
        final innerTop = 0.0;
        final innerBottom = forBars
            ? 38.0
            : 24.0; // match bottomTitles reserved
        final innerWidth = constraints.maxWidth - innerLeft - innerRight;
        final innerHeight = constraints.maxHeight - innerTop - innerBottom;
        final maxX = (dataKeys.isNotEmpty)
            ? (dataKeys.length - 1).toDouble()
            : 0.0;
        final maxY = _maxYWithPadding();
        final List<Widget> labels = [];
        for (int i = 0; i < dataKeys.length; i++) {
          final double xRel = (maxX == 0) ? 0.0 : (i / maxX);
          final double x = innerLeft + xRel * innerWidth;
          final double yVal = forBars
              ? (barGroups[i].barRods.first.toY)
              : points[i].y;
          final double yRel = (maxY == 0) ? 0.0 : (yVal / maxY);
          final double y = innerTop + (1.0 - yRel) * innerHeight;
          labels.add(
            Positioned(
              left: (x - 36).clamp(0.0, constraints.maxWidth - 72),
              top: (y - 22).clamp(0.0, constraints.maxHeight - 22),
              width: 72,
              child: IgnorePointer(
                child: Text(
                  _formatMoneyFull(yVal),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }
        return Stack(
          children: [
            Positioned.fill(child: chart),
            ...labels,
          ],
        );
      },
    );
  }

  Widget _buildChart() {
    switch (widget.chartType) {
      case ChartType.bar:
        return _withAlwaysOnLabels(
          chart: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceBetween,
              groupsSpace: 8,
              barTouchData: BarTouchData(
                enabled: false,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) =>
                      Theme.of(context).colorScheme.secondary,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      _formatMoneyFull(rod.toY),
                      Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _gridInterval(),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withOpacity(0.6),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  axisNameWidget: widget.xAxisLabel != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(widget.xAxisLabel!),
                        )
                      : null,
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (i < 0 || i >= dataKeys.length) {
                        return const SizedBox();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          dataKeys[i],
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: widget.yAxisLabel != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(widget.yAxisLabel!),
                          ),
                        )
                      : null,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    interval: _gridInterval(),
                    getTitlesWidget: (value, meta) => Text(
                      _formatY(value),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              maxY: _maxYWithPadding(),
              barGroups: barGroups,
            ),
          ),
          forBars: true,
        );
      case ChartType.pie:
        return PieChart(
          PieChartData(
            sections: pieSections,
            sectionsSpace: 2,
            centerSpaceRadius: 0,
          ),
        );
      case ChartType.line:
        return _withAlwaysOnLabels(
          chart: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                enabled: false,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) =>
                      Theme.of(context).colorScheme.secondary,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                    return LineTooltipItem(
                      _formatMoneyFull(spot.y),
                      Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: _gridInterval(),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withOpacity(0.6),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  axisNameWidget: widget.xAxisLabel != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(widget.xAxisLabel!),
                        )
                      : null,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      // Show labels only on integer ticks to avoid repetition
                      final nearest = value.roundToDouble();
                      if ((value - nearest).abs() > 0.01) {
                        return const SizedBox();
                      }
                      final index = nearest.toInt();
                      if (index < 0 || index >= dataKeys.length) {
                        return const SizedBox();
                      }
                      final total = dataKeys.length;
                      final step = (total / 8).ceil();
                      if (step > 1 &&
                          index % step != 0 &&
                          index != total - 1 &&
                          index != 0) {
                        return const SizedBox();
                      }
                      return Text(
                        dataKeys[index],
                        style: Theme.of(context).textTheme.titleSmall,
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: widget.yAxisLabel != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(widget.yAxisLabel!),
                          ),
                        )
                      : null,
                  sideTitles: SideTitles(
                    reservedSize: 60,
                    showTitles: true,
                    interval: _gridInterval(),
                    getTitlesWidget: (value, meta) => Text(
                      _formatY(value),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: points.isNotEmpty ? points.length.toDouble() - 1 : 0,
              minY: 0,
              maxY: _maxYWithPadding(),
              lineBarsData: [
                LineChartBarData(
                  spots: points,
                  isCurved: false,
                  color: Theme.of(context).colorScheme.secondary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.5),
                        Theme.of(context).colorScheme.secondary.withOpacity(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          forBars: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.titleBuilder(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.showRefresh)
              IconButton(
                tooltip: 'Refrescar',
                icon: const Icon(Icons.refresh),
                onPressed: isLoading ? null : _reload,
              ),
          ],
        ),

        const SizedBox(height: CustomSpacer.small),
        // Chart area with optional horizontal scroll for narrow screens
        SizedBox(
          height: widget.chartType == ChartType.pie ? 220 : 200,
          child: isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.white,
                  ),
                )
              : (dataKeys.isEmpty)
              ? Center(
                  child: Text(
                    AppLocale.noDataForFilter.getString(context),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _computeChartWidth(context),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 24),
                      child: _buildChart(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// A simple container that can host multiple charts stacked vertically.
class DashboardCharts extends StatelessWidget {
  final List<Widget> children;
  const DashboardCharts({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          children[i],
        ],
      ],
    );
  }
}
