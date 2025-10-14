import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/logo.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/footer.dart';
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
    final bool isMobile =
        MediaQuery.of(context).size.width < 700 ? true : false;

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
          actions: [
            !isMobile
                ? Padding(
                    padding: const EdgeInsets.only(right: CustomSpacer.medium),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(CustomSpacer.medium),
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.all(CustomSpacer.small),
                      child: Logo(
                        width: 60,
                      ),
                    ),
                  )
                : SizedBox.shrink()
          ],
        ),
        bottomNavigationBar: CustomFooter(),
        drawer: MenuDrawer(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: CustomContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DashboardCharts(
                        children: [
                          MetricCard(
                            titleBuilder: (ctx) =>
                                AppLocale.salesYTDMonthly.getString(context),
                            dataLoader: ({required context}) =>
                                fetchSalesChartData(
                              context: context,
                            ),
                            chartType: ChartType.line,
                          ),
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
