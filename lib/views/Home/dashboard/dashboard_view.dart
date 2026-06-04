import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/logo.dart';
import 'package:primware/views/Home/dashboard/dashboard_skeleton.dart';
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
  bool _isLoading = true;
  bool _hasData = false;

  Map<String, double> _salesYTDBySalesRepData = {};
  Map<String, double> _salesPerDayByProductCategoryData = {};

  late final ChartDataLoader _salesYTDBySalesRepLoader;
  late final ChartDataLoader _salesPerDayByProductCategoryLoader;

  @override
  void initState() {
    super.initState();

    _salesYTDBySalesRepLoader = ({required context}) =>
        fetchSalesYTDBySalesRepCurrentMonth(context: context, monthOffset: 0);
    _salesPerDayByProductCategoryLoader = ({required context}) =>
        fetchSalesPerDayByProductCategory(context: context, dayOffset: 0);
    _checkDashboardData();
  }

  Future<void> _checkDashboardData() async {
    setState(() => _isLoading = true);

    Map<String, double> ytdData = _salesYTDBySalesRepData;
    Map<String, double> productCategoryData = _salesPerDayByProductCategoryData;

    final List<Future<void>> futures = [];

    if (Charts.salesYTDBySalesRep != null && ytdData.isEmpty) {
      futures.add(
        _salesYTDBySalesRepLoader(context: context).then((value) {
          ytdData = value;
        }),
      );
    }

    if (Charts.salesPerDayByProductCategory != null &&
        productCategoryData.isEmpty) {
      futures.add(
        _salesPerDayByProductCategoryLoader(context: context).then((value) {
          productCategoryData = value;
        }),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    if (!mounted) return;

    setState(() {
      _salesYTDBySalesRepData = ytdData;
      _salesPerDayByProductCategoryData = productCategoryData;
      _hasData = ytdData.isNotEmpty || productCategoryData.isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700
        ? true
        : false;

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
        Token.adOrgInfoUU = null;
        usuarioController.clear();
        claveController.clear();
        UserData.rolName = null;
        UserData.imageBytes = null;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
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
                        borderRadius: BorderRadius.circular(
                          CustomSpacer.medium,
                        ),
                        color: Colors.white,
                      ),
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
          child: _isLoading
              ? const DashboardSkeleton()
              : !_hasData
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: EmptyMetricState(showActions: true)),
                )
              : SingleChildScrollView(
                  child: Center(
                    child: CustomContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (Charts.salesYTDBySalesRep != null)
                              GraphicBarMetricCard(
                                titleBuilder: (ctx) =>
                                    AppLocale.thisMonth.getString(context),
                                initialData: _salesYTDBySalesRepData,
                                dataLoader: _salesYTDBySalesRepLoader,
                                subtitle: AppLocale
                                    .salesYTDBySalesRepDescription
                                    .getString(context),
                                showTotal: true,
                              ),

                            if (Charts.salesPerDayByProductCategory !=
                                null) ...[
                              const SizedBox(height: CustomSpacer.medium),
                              GraphicPieMetricCard(
                                titleBuilder: (ctx) =>
                                    AppLocale.today.getString(ctx),
                                initialData: _salesPerDayByProductCategoryData,
                                dataLoader: _salesPerDayByProductCategoryLoader,
                                subtitle: AppLocale
                                    .todaySalesByCategoryDescription
                                    .getString(context),
                                showTotal: true,
                              ),
                            ],
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
