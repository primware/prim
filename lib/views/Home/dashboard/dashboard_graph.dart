// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/custom_spacer.dart';

enum ChartType { line, bar, pie }

typedef ChartDataLoader = Future<Map<String, double>> Function({
  required BuildContext context,
  required String groupBy,
});

/// Reusable metric card that supports multiple chart types (line, bar, pie).
class MetricCard extends StatefulWidget {
  final String initialGroupBy;
  final List<String> groupByOptions; // e.g., ['day','month']
  final String Function(BuildContext) titleBuilder;
  final ChartDataLoader dataLoader; // returns Map<X, Y>
  final ChartType chartType;
  final String? xAxisLabel; // eje X label
  final String? yAxisLabel; // eje Y label

  const MetricCard({
    super.key,
    required this.titleBuilder,
    required this.dataLoader,
    this.initialGroupBy = 'month',
    this.groupByOptions = const ['day', 'month'],
    this.chartType = ChartType.line,
    this.xAxisLabel,
    this.yAxisLabel,
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
  String groupBy = 'month';

  List<String> _localizedMonths(BuildContext context) {
    return [
      AppLocale.jan.getString(context),
      AppLocale.feb.getString(context),
      AppLocale.mar.getString(context),
      AppLocale.apr.getString(context),
      AppLocale.may.getString(context),
      AppLocale.jun.getString(context),
      AppLocale.jul.getString(context),
      AppLocale.aug.getString(context),
      AppLocale.sep.getString(context),
      AppLocale.oct.getString(context),
      AppLocale.nov.getString(context),
      AppLocale.dec.getString(context),
    ];
  }

  String _formatLabel(String key) {
    final parts = key.split('-');
    if (parts.length >= 2) {
      final year = int.tryParse(parts[0]) ?? 0;
      final monthIndex = int.tryParse(parts[1]) ?? 1; // 1-12
      final months = _localizedMonths(context);
      final idx = (monthIndex.clamp(1, 12)) - 1;

      if (groupBy == 'month') {
        // e.g., "Sep 25"
        return '${months[idx]} ${year % 100}';
      } else {
        // groupBy == 'day' -> expect YYYY-MM-DD
        if (parts.length >= 3) {
          final day = int.tryParse(parts[2]) ?? 1;
          // e.g., "25 Sep" (día primero para diferenciar de month)
          return '${day.toString()} ${months[idx]}';
        } else {
          // Fallback if only YYYY-MM provided
          return '${months[idx]} ${year % 100}';
        }
      }
    }
    return key;
  }

  Map<String, double> _normalizeByGroup(Map<String, double> raw) {
    if (groupBy == 'month') {
      final Map<String, double> agg = {};
      raw.forEach((k, v) {
        // Expect keys like YYYY-MM or YYYY-MM-DD
        final key = (k.length >= 7) ? k.substring(0, 7) : k; // YYYY-MM
        agg.update(key, (prev) => prev + v, ifAbsent: () => v);
      });
      return agg;
    }
    return raw; // for 'day' assume viene ya por día
  }

  String _formatY(double value) {
    final abs = value.abs();
    if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
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
    final double maxVal =
        points.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final double step = _niceInterval(maxVal);
    // Round up to next tick and add a small headroom so the top label isn’t clipped
    final double rounded = ((maxVal) / step).ceil() * step;
    return rounded + step * 0.5; // 20% of a step as headroom
  }

  // --- Horizontal scroll helpers ---
  double _tickMinWidth() {
    if (widget.chartType == ChartType.pie) return 0; // not used
    // More space for day labels like "25 Sep"
    return groupBy == 'day' ? 68.0 : 64.0;
  }

  double _computeChartWidth(BuildContext context) {
    if (widget.chartType == ChartType.pie) {
      return MediaQuery.of(context).size.width; // no scroll for pie
    }
    final screen = MediaQuery.of(context).size.width * 0.8;
    if (dataKeys.isEmpty) return screen;
    // Reserve a bit of padding and ensure each tick has legible width
    final desired = (dataKeys.length * _tickMinWidth()) + 24.0;
    final width = desired > screen ? desired : screen;
    return width > 760 ? 760 : width;
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    final rawData = await widget.dataLoader(context: context, groupBy: groupBy);
    final groupedData = _normalizeByGroup(rawData);

    // Common ordering for X values
    final keys = groupedData.keys.toList()..sort();

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
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      );
    }

    // Build pie sections
    final total =
        groupedData.values.fold<double>(0, (a, b) => a + (b.toDouble()));
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
    groupBy = widget.initialGroupBy;
    _load();
  }

  Widget _buildChart() {
    switch (widget.chartType) {
      case ChartType.bar:
        return BarChart(
          BarChartData(
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) =>
                    Theme.of(context).colorScheme.primaryContainer,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    rod.toY.toStringAsFixed(2),
                    Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  );
                },
              ),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false),
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
                    final i = value.toInt();
                    if (i < 0 || i >= dataKeys.length) return const SizedBox();
                    final step = (dataKeys.length / 8).ceil();
                    if (step > 1 && i % step != 0 && i != dataKeys.length - 1) {
                      return const SizedBox();
                    }
                    return Text(_formatLabel(dataKeys[i]));
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: widget.yAxisLabel != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: RotatedBox(
                            quarterTurns: 3, child: Text(widget.yAxisLabel!)),
                      )
                    : null,
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: _gridInterval(),
                  getTitlesWidget: (value, meta) => Text(
                    _formatY(value),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            maxY: _maxYWithPadding(),
            barGroups: barGroups,
          ),
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
        return LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) =>
                    Theme.of(context).colorScheme.secondary,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                  return LineTooltipItem(
                    spot.y.toStringAsFixed(2),
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
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.6),
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
                      _formatLabel(dataKeys[index]),
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
                            quarterTurns: 3, child: Text(widget.yAxisLabel!)),
                      )
                    : null,
                sideTitles: SideTitles(
                  reservedSize: 50,
                  showTitles: true,
                  interval: _gridInterval(),
                  getTitlesWidget: (value, meta) => Text(
                    _formatY(value),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                      Theme.of(context).colorScheme.secondary.withOpacity(0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.titleBuilder(context),
            style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(height: CustomSpacer.small),
        // Chart area with optional horizontal scroll for narrow screens
        SizedBox(
          height: widget.chartType == ChartType.pie ? 220 : 200,
          child: isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                      width: double.infinity, height: 200, color: Colors.white),
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
        Center(
          child: DropdownButton<String>(
            value: groupBy,
            items: widget.groupByOptions.map((opt) {
              final label = opt == 'day'
                  ? AppLocale.days.getString(context)
                  : AppLocale.months.getString(context);
              return DropdownMenuItem(value: opt, child: Text(label));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => groupBy = value);
                _load();
              }
            },
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
