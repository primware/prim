import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/logo.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_spacer.dart';
import '../../Auth/login_view.dart';
import 'dashboard_graph.dart';
import 'dashboard_funtions.dart';
import '../../../localization/app_locale.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime? lastBackPressed;

  @override
  Widget build(BuildContext context) {
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DashboardCharts(
                        children: [
                          MetricCard(
                            titleBuilder: (ctx) => 'Ventas por período (Línea)',
                            dataLoader: (
                                    {required context, required groupBy}) =>
                                fetchSalesChartData(
                                    context: context, groupBy: groupBy),
                            chartType: ChartType.line,
                          ),
                          // MetricCard(
                          //   titleBuilder: (ctx) => 'Ventas por período (Barra)',
                          //   dataLoader: ({required context, required groupBy}) =>
                          //       fetchSalesChartData(
                          //           context: context, groupBy: groupBy),
                          //   chartType: ChartType.bar,
                          // ),
                        ],
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
