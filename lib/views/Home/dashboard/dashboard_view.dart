// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/logo.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_spacer.dart';
import '../../Auth/login_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'dashboard_funtions.dart';
import '../../../localization/app_locale.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<String> dataKeys = [];
  List<FlSpot> salesData = [];
  bool isLoadingSalesChart = true;
  String groupBy = 'month';

  Future<void> _loadSalesChart() async {
    setState(() {
      isLoadingSalesChart = true;
    });
    final groupedData =
        await fetchSalesChartData(context: context, groupBy: groupBy);
    setState(() {
      salesData = [];
      dataKeys = groupedData.keys.toList()..sort();
      double xIndex = 0;
      for (var key in dataKeys) {
        salesData.add(FlSpot(
          xIndex,
          groupedData[key] ?? 0,
        ));
        xIndex++;
      }
      isLoadingSalesChart = false;
    });
  }

  static const List<String> _monthsEs = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic'
  ];
  static const List<String> _monthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  List<String> _monthsForLocale(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    return lang == 'es' ? _monthsEs : _monthsEn;
  }

  String formatLabel(String key) {
    final parts = key.split('-');
    // Expecting keys like YYYY-MM or YYYY-MM-DD
    if (parts.length >= 2) {
      final monthIndex = int.tryParse(parts[1]) ?? 1; // 1-12
      final months = _monthsForLocale(context);
      final idx = (monthIndex.clamp(1, 12)) - 1;
      return months[idx];
    }
    return key;
  }

  @override
  void initState() {
    super.initState();
    _loadSalesChart();
  }

  @override
  Widget build(BuildContext context) {
    DateTime? lastBackPressed;

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();

        if (lastBackPressed == null ||
            now.difference(lastBackPressed!) > const Duration(seconds: 2)) {
          lastBackPressed = now;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocale.pressAgainToLogout.getString(context)),
              duration: const Duration(seconds: 2),
            ),
          );

          return false;
        }

        Token.auth = null;
        usuarioController.clear();
        claveController.clear();
        UserData.rolName = null;
        UserData.imageBytes = null;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );

        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocale.dashboard.getString(context)),
        ),
        drawer: MenuDrawer(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: CustomContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Logo(width: 169)),
                    SizedBox(height: CustomSpacer.xlarge),
                    Row(
                      children: [
                        Text('${AppLocale.totalSoldBy.getString(context)}',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: CustomSpacer.medium),
                        DropdownButton<String>(
                          value: groupBy,
                          items: [
                            DropdownMenuItem(
                                value: 'day',
                                child: Text(AppLocale.days.getString(context))),
                            DropdownMenuItem(
                                value: 'month',
                                child:
                                    Text(AppLocale.months.getString(context))),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                groupBy = value;
                              });
                              _loadSalesChart();
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 200,
                      child: isLoadingSalesChart
                          ? Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.white,
                              ),
                            )
                          : salesData.isEmpty
                              ? Center(
                                  child: Text(
                                      AppLocale.noDataForFilter
                                          .getString(context),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium))
                              : LineChart(
                                  LineChartData(
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipColor: (touchedSpot) =>
                                            Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                        fitInsideHorizontally: true,
                                        fitInsideVertically: true,
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            return LineTooltipItem(
                                              '${spot.y.toStringAsFixed(2)} USD', //TODO Moneda del grupo empresarial
                                              Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: (salesData.isNotEmpty
                                          ? (salesData.map((e) => e.y).reduce(
                                                      (a, b) => a > b ? a : b) /
                                                  5)
                                              .roundToDouble()
                                          : 10000),
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer
                                              .withOpacity(0.6),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 24,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index < 0 ||
                                                index >= dataKeys.length) {
                                              return const SizedBox();
                                            }
                                            final total = dataKeys.length;
                                            final step = (total / 6)
                                                .ceil(); // show up to ~6 labels
                                            if (step > 1 &&
                                                index % step != 0 &&
                                                index != total - 1) {
                                              return const SizedBox();
                                            }
                                            return Text(
                                              formatLabel(dataKeys[index]),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: (salesData.isNotEmpty
                                              ? (salesData
                                                          .map((e) => e.y)
                                                          .reduce((a, b) =>
                                                              a > b ? a : b) /
                                                      5)
                                                  .roundToDouble()
                                              : 10000),
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              '${(value / 1000).round()}k',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX: salesData.isNotEmpty
                                        ? salesData.length.toDouble() - 1
                                        : 0,
                                    minY: 0,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: salesData,
                                        isCurved: true,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surfaceTint
                                                  .withOpacity(0.5),
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surfaceTint
                                                  .withOpacity(0),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
