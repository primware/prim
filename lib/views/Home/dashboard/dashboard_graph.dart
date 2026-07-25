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

typedef ChartDataLoader =
    Future<Map<String, double>> Function({
      required BuildContext context,
      required int offset,
    });

class GraphicBarMetricCard extends StatefulWidget {
  final String Function(BuildContext, int) titleBuilder;
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
  int currentOffset = 0;

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

    if (oldWidget.initialData != widget.initialData &&
        widget.initialData.isNotEmpty) {
      setState(() {
        rawChartData = Map<String, double>.from(widget.initialData);
        isLoading = false;
      });
    }
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    rawChartData = await widget.dataLoader(
      context: context,
      offset: currentOffset,
    );
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _reload() => _load();

  void _goBack() {
    setState(() => currentOffset--);
    _load();
  }

  void _goForward() {
    if (currentOffset < 0) {
      setState(() => currentOffset++);
      _load();
    }
  }

  void _goToday() {
    if (currentOffset != 0) {
      setState(() => currentOffset = 0);
      _load();
    }
  }

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
    final double maxY = rawChartData.isEmpty
        ? 100
        : rawChartData.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            _goBack();
          } else if (details.primaryVelocity! < 0) {
            _goForward();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                key: ValueKey(currentOffset),
                widget.titleBuilder(context, currentOffset),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                  onPressed: isLoading ? null : _goBack,
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: currentOffset < 0
                        ? (isDark ? Colors.white70 : Colors.grey.shade700)
                        : Colors.grey.shade300,
                  ),
                  onPressed: (isLoading || currentOffset >= 0)
                      ? null
                      : _goForward,
                ),
                if (currentOffset != 0)
                  IconButton(
                    tooltip: AppLocale.thisMonth.getString(context),
                    icon: Icon(
                      Icons.today_rounded,
                      color: primaryColor,
                    ),
                    onPressed: isLoading ? null : _goToday,
                  ),
                if (widget.showRefresh)
                  IconButton(
                    tooltip: AppLocale.refresh.getString(context),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: isLoading ? null : _reload,
                  ),
              ],
            ),
            if (widget.subtitle != null &&
                widget.subtitle!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ),
            if (widget.showTotal)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    key: ValueKey(_totalValue()),
                    '${AppLocale.total.getString(context)}: ${POS.currencySymbol} ${totalFmt.format(_totalValue())}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                  ),
                ),
              ),
            const SizedBox(height: CustomSpacer.large),
            SizedBox(
              height: 300,
              child: (isLoading && rawChartData.isEmpty)
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!.withOpacity(0.5),
                      highlightColor: Colors.grey[100]!.withOpacity(0.5),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : rawChartData.isEmpty
                  ? Center(
                      child: Text(
                        AppLocale.noDataForFilter.getString(context),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                    )
                  : AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isLoading ? 0.4 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => isDark
                                  ? Colors.grey.shade800
                                  : Colors.blueGrey.shade900,
                              tooltipRoundedRadius: 8,
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              tooltipMargin: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${entries[group.x].key}\n',
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text:
                                          '${POS.currencySymbol} ${totalFmt.format(rod.toY)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            touchCallback:
                                (FlTouchEvent event, barTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        barTouchResponse == null ||
                                        barTouchResponse.spot == null) {
                                      touchedIndex = -1;
                                      return;
                                    }
                                    touchedIndex = barTouchResponse
                                        .spot!
                                        .touchedBarGroupIndex;
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
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < entries.length) {
                                    bool showLabel =
                                        entries.length < 10 ||
                                        value.toInt() %
                                                (entries.length ~/ 6 + 1) ==
                                            0;
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        showLabel
                                            ? entries[value.toInt()].key
                                            : '',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                                  if (value == 0 || value == maxY) {
                                    return const SizedBox.shrink();
                                  }
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      NumberFormat.compact().format(value),
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxY / 5 > 0
                                ? maxY / 5
                                : 1, // Previene divisiones entre 0
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.1),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              );
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
                                        ? [
                                            secondaryColor,
                                            secondaryColor.withOpacity(0.7),
                                          ]
                                        : [
                                            primaryColor,
                                            primaryColor.withOpacity(0.6),
                                          ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6),
                                  ),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY,
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.05),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                        swapAnimationDuration: const Duration(
                          milliseconds: 550,
                        ),
                        swapAnimationCurve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class GraphicPieMetricCard extends StatefulWidget {
  final String Function(BuildContext, int) titleBuilder;
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
  int currentOffset = 0;

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
    rawChartData = await widget.dataLoader(
      context: context,
      offset: currentOffset,
    );
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _reload() => _load();

  void _goBack() {
    setState(() => currentOffset--);
    _load();
  }

  void _goForward() {
    if (currentOffset < 0) {
      setState(() => currentOffset++);
      _load();
    }
  }

  void _goToday() {
    if (currentOffset != 0) {
      setState(() => currentOffset = 0);
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant GraphicPieMetricCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData &&
        widget.initialData.isNotEmpty) {
      setState(() {
        rawChartData = Map<String, double>.from(widget.initialData);
        isLoading = false;
      });
    }
  }

  List<Map<String, Object>> _chartRows() {
    return rawChartData.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {'category': entry.key, 'value': entry.value})
        .toList();
  }

  double _totalValue() {
    if (rawChartData.isEmpty) return 0;
    return rawChartData.values.fold(0.0, (sum, value) => sum + value);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _chartRows();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = <Color>[
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.orangeAccent,
      Colors.tealAccent.shade700,
      Colors.deepPurpleAccent,
      Colors.pinkAccent,
      Colors.indigoAccent,
    ];
    final totalFmt = NumberFormat('#,##0.00', 'en_US');

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            _goBack();
          } else if (details.primaryVelocity! < 0) {
            _goForward();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                key: ValueKey(currentOffset),
                widget.titleBuilder(context, currentOffset),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                  onPressed: isLoading ? null : _goBack,
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: currentOffset < 0
                        ? (isDark ? Colors.white70 : Colors.grey.shade700)
                        : Colors.grey.shade300,
                  ),
                  onPressed: (isLoading || currentOffset >= 0)
                      ? null
                      : _goForward,
                ),
                if (currentOffset != 0)
                  IconButton(
                    tooltip: AppLocale.thisMonth.getString(context),
                    icon: Icon(
                      Icons.today_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: isLoading ? null : _goToday,
                  ),
                if (widget.showRefresh)
                  IconButton(
                    tooltip: AppLocale.refresh.getString(context),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: isLoading ? null : _reload,
                  ),
              ],
            ),
            if (widget.subtitle != null &&
                widget.subtitle!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ),
            if (widget.showTotal)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    key: ValueKey(_totalValue()),
                    '${AppLocale.total.getString(context)}: ${POS.currencySymbol} ${totalFmt.format(_totalValue())}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ),
            const SizedBox(height: CustomSpacer.large),
            SizedBox(
              height: 340,
              child: (isLoading && rawChartData.isEmpty)
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!.withOpacity(0.5),
                      highlightColor: Colors.grey[100]!.withOpacity(0.5),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : rows.isEmpty
                  ? Center(
                      child: Text(
                        AppLocale.noDataForFilter.getString(context),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                    )
                  : AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isLoading ? 0.4 : 1.0,
                      child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    if (touchedIndex >= 0 &&
                                        touchedIndex < rows.length)
                                      BoxShadow(
                                        color:
                                            colors[touchedIndex % colors.length]
                                                .withOpacity(0.55),
                                        blurRadius: 40,
                                        spreadRadius: 8,
                                      )
                                    else
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                  ],
                                ),
                              ),

                              // Gráfico de Pastel
                              PieChart(
                                PieChartData(
                                  centerSpaceRadius: 45,
                                  sectionsSpace: rows.length == 1 ? 0 : 5,
                                  pieTouchData: PieTouchData(
                                    touchCallback:
                                        (FlTouchEvent event, pieTouchResponse) {
                                          setState(() {
                                            if (!event
                                                    .isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse
                                                        .touchedSection ==
                                                    null) {
                                              touchedIndex = -1;
                                              return;
                                            }
                                            touchedIndex = pieTouchResponse
                                                .touchedSection!
                                                .touchedSectionIndex;
                                          });
                                        },
                                  ),
                                  sections: List.generate(rows.length, (index) {
                                    final row = rows[index];
                                    final color = colors[index % colors.length];
                                    final value = (row['value'] as num)
                                        .toDouble();
                                    final total = _totalValue();
                                    final percent = total > 0
                                        ? (value / total) * 100
                                        : 0.0;
                                    final isTouched =
                                        index == touchedIndex ||
                                        rows.length == 1;

                                    return PieChartSectionData(
                                      color: color,
                                      value: value,
                                      radius: isTouched ? 115 : 100,
                                      title: percent > 4
                                          ? '${percent.toStringAsFixed(0)}%'
                                          : '',
                                      titleStyle: TextStyle(
                                        fontSize: isTouched ? 16 : 13,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        shadows: const [
                                          BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                                swapAnimationDuration: const Duration(
                                  milliseconds: 550,
                                ),
                                swapAnimationCurve: Curves.easeOutBack,
                              ),

                              IgnorePointer(
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black.withOpacity(0.5)
                                            : Colors.black.withOpacity(0.15),
                                        blurRadius: 15,
                                        spreadRadius: -5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (touchedIndex >= 0 &&
                                      touchedIndex < rows.length ||
                                  rows.length == 1)
                                IgnorePointer(
                                  child: Builder(
                                    builder: (context) {
                                      final displayIndex =
                                          (touchedIndex >= 0 &&
                                              touchedIndex < rows.length)
                                          ? touchedIndex
                                          : 0;
                                      final row = rows[displayIndex];
                                      final value = (row['value'] as num)
                                          .toDouble();
                                      final percent = _totalValue() > 0
                                          ? (value / _totalValue()) * 100
                                          : 0.0;

                                      return Container(
                                        width: 120,
                                        height: 120,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withOpacity(0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              row['category'].toString(),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: isDark
                                                        ? Colors.grey.shade400
                                                        : Colors.grey.shade600,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            FittedBox(
                                              child: Text(
                                                '${POS.currencySymbol}${totalFmt.format(value)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                              ),
                                            ),
                                            if (rows.length > 1)
                                              Text(
                                                '${percent.toStringAsFixed(1)}%',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: isDark
                                                          ? Colors.grey.shade400
                                                          : Colors
                                                                .grey
                                                                .shade600,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List.generate(rows.length, (index) {
                            final row = rows[index];
                            final color = colors[index % colors.length];
                            final isTouched =
                                index == touchedIndex || rows.length == 1;

                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: touchedIndex == -1 || isTouched
                                  ? 1.0
                                  : 0.35,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      boxShadow: isTouched
                                          ? [
                                              BoxShadow(
                                                color: color.withOpacity(0.5),
                                                blurRadius: 6,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    row['category'].toString(),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontWeight: isTouched
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isTouched
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Colors.grey.shade600,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    Icon(
                      Icons.query_stats_rounded,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      AppLocale.noOrdersRegistered.getString(context),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocale.readyForFirstOrder.getString(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.add_shopping_cart,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                label: Text(
                                  AppLocale.newOrder.getString(context),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () {
                                  if (POS.docTypesComplete.isEmpty) {
                                    ToastMessage.show(
                                      context: context,
                                      message: AppLocale.noDocTypesAvailable
                                          .getString(context),
                                      type: ToastType.help,
                                    );
                                    return;
                                  }

                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).cardColor,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (BuildContext modalContext) {
                                      final availableDocs = POS.docTypesComplete
                                          .where((doc) {
                                            final dynamic rawId = doc['id'];
                                            final int? docTypeId = rawId is int
                                                ? rawId
                                                : int.tryParse(
                                                    rawId?.toString() ?? '',
                                                  );

                                            return doc['DocSubTypeSO'] !=
                                                    'RM' &&
                                                docTypeId !=
                                                    POS.docTypeRefundID;
                                          })
                                          .toList();

                                      if (availableDocs.isEmpty) {
                                        return SafeArea(
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Text(
                                              AppLocale.noDocTypesAvailable
                                                  .getString(context),
                                              textAlign: TextAlign.center,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge,
                                            ),
                                          ),
                                        );
                                      }

                                      return SafeArea(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16.0,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                AppLocale.documentType
                                                    .getString(context),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Divider(),
                                              ...availableDocs.map((doc) {
                                                final dynamic rawId = doc['id'];
                                                final int? docTypeId =
                                                    rawId is int
                                                    ? rawId
                                                    : int.tryParse(
                                                        rawId?.toString() ?? '',
                                                      );
                                                final String docName =
                                                    (doc['name'] ??
                                                            doc['Name'] ??
                                                            'Documento')
                                                        .toString();

                                                return ListTile(
                                                  leading: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .primaryColor
                                                          .withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.add_shopping_cart,
                                                      color: Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    docName,
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodyLarge,
                                                  ),
                                                  trailing: const Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: Colors.grey,
                                                  ),
                                                  onTap: () {
                                                    Navigator.pop(modalContext);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            OrderNewPage(
                                                              isRefund: false,
                                                              doctypeID:
                                                                  docTypeId,
                                                              orderName:
                                                                  docName,
                                                            ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.1),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.list_alt,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                label: Text(
                                  AppLocale.myOrders.getString(context),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const OrderListPage(),
                                    ),
                                  );
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
