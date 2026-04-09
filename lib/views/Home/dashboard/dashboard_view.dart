import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/logo.dart';
import '../../../API/endpoint.dart';
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
    final bool isMobile = MediaQuery.of(context).size.width < 700 ? true : false;

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();

        if (lastBackPressed == null || now.difference(lastBackPressed!) > const Duration(seconds: 2)) {
          lastBackPressed = now;
          //TODO cambiar a Toast
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocale.pressAgainToLogout.getString(context)), duration: const Duration(seconds: 2)));

          return false;
        }

        Token.auth = null;
        usuarioController.clear();
        claveController.clear();
        UserData.rolName = null;
        UserData.imageBytes = null;

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));

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
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(CustomSpacer.medium), color: Colors.white),
                      padding: const EdgeInsets.all(CustomSpacer.small),
                      child: const Logo(width: 60),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: const CustomFooter(),
        drawer: const MenuDrawer(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: CustomContainer(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DashboardCharts(
                    children: [
                      DashboardCharts(
                        children: [
                          if (Charts.salesYTDBySalesRep != null)
                            GraphicBarMetricCard(
                              titleBuilder: (ctx) => AppLocale.salesYTDBySalesRep.getString(context),
                              dataLoader: ({required context}) => fetchSalesYTDBySalesRepCurrentMonth(context: context, monthOffset: -2),
                              showTotal: true,
                            ),

                          if (Charts.salesPerDay != null)
                            GraphicBarMetricCard(
                              titleBuilder: (ctx) => AppLocale.salesPerDay.getString(context),
                              dataLoader: ({required context}) => fetchSalesPerDay(context: context, monthOffset: -2),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardCharts extends StatelessWidget {
  final List<Widget> children;
  const DashboardCharts({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    List<Widget> columnChildren = [];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        columnChildren.add(const SizedBox(height: 24));
      }
      columnChildren.add(children[i]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: columnChildren);
  }
}
