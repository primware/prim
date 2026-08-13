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
import 'password_warning_dialog.dart';
import 'dashboard_graph.dart';
import 'dashboard_funtions.dart';
import '../../../localization/app_locale.dart';
import '../order/my_order.dart';

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

    _salesYTDBySalesRepLoader = ({required context, required int offset}) =>
        fetchSalesYTDBySalesRepCurrentMonth(context: context, monthOffset: offset);
    _salesPerDayByProductCategoryLoader = ({required context, required int offset}) =>
        fetchSalesPerDayByProductCategory(context: context, dayOffset: offset);
    _checkDashboardData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (usuarioController.text.trim() == claveController.text.trim() &&
          usuarioController.text.trim().isNotEmpty) {
        PasswordWarningDialog.show(context);
      }
    });
  }

  Future<void> _checkDashboardData() async {
    setState(() => _isLoading = true);

    Map<String, double> ytdData = _salesYTDBySalesRepData;
    Map<String, double> productCategoryData = _salesPerDayByProductCategoryData;

    final List<Future<void>> futures = [];

    if (Charts.salesYTDBySalesRep != null && ytdData.isEmpty) {
      futures.add(
        _salesYTDBySalesRepLoader(context: context, offset: 0).then((value) {
          ytdData = value;
        }),
      );
    }

    if (Charts.salesPerDayByProductCategory != null &&
        productCategoryData.isEmpty) {
      futures.add(
        _salesPerDayByProductCategoryLoader(context: context, offset: 0).then((value) {
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
              : SingleChildScrollView(
                  child: Center(
                    child: CustomContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: Icon(Icons.list_alt, size: 20, color: Theme.of(context).colorScheme.secondary),
                                label: Text(
                                  AppLocale.myOrders.getString(context),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderListPage()));
                                },
                              ),
                            ),
                            const SizedBox(height: CustomSpacer.medium),
                            

                            if (Charts.salesYTDBySalesRep != null)
                              GraphicBarMetricCard(
                                titleBuilder: (ctx, offset) {
                                  if (offset == 0) return AppLocale.thisMonth.getString(context);
                                  final now = DateTime.now();
                                  final d = DateTime(now.year, now.month + offset, 1);
                                  final lang = Localizations.localeOf(context).languageCode;
                                  final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
                                  final enMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
                                  final m = lang == 'es' ? months[d.month - 1] : enMonths[d.month - 1];
                                  return '$m ${d.year}';
                                },
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
                                titleBuilder: (ctx, offset) {
                                  if (offset == 0) return AppLocale.today.getString(ctx);
                                  if (offset == -1) return AppLocale.yesterday.getString(ctx);
                                  final now = DateTime.now();
                                  final d = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
                                  final lang = Localizations.localeOf(context).languageCode;
                                  final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
                                  final enMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
                                  final m = lang == 'es' ? months[d.month - 1] : enMonths[d.month - 1];
                                  return '${d.day} de $m';
                                },
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
