import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/logo.dart';
import '../../../API/endpoint.dart';
import 'package:primware/views/Home/dashboard/dashboard_skeleton.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/footer.dart';
import '../../Auth/login_view.dart' hide GlassContainer, LiquidBackground;
import 'dashboard_graph.dart';
import 'dashboard_funtions.dart';
import '../../../localization/app_locale.dart';
import '../../../Widgets/GlassDesign.dart';

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

    _salesYTDBySalesRepLoader = ({required context}) => fetchSalesYTDBySalesRepCurrentMonth(context: context, monthOffset: 0);
    _salesPerDayByProductCategoryLoader = ({required context}) => fetchSalesPerDayByProductCategory(context: context, dayOffset: 0);
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

    if (Charts.salesPerDayByProductCategory != null && productCategoryData.isEmpty) {
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
    final bool isMobile = MediaQuery.of(context).size.width < 700 ? true : false;

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();

        if (lastBackPressed == null || now.difference(lastBackPressed!) > const Duration(seconds: 2)) {
          lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.pressAgainToLogout.getString(context)), duration: const Duration(seconds: 2)));
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
      child: LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,

          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            flexibleSpace: GlassContainer(
              shadowBlurStyle: BlurStyle.normal,
              blur: 40.0,
              borderOpacity: 0.5,
              borderRadius: BorderRadius.zero,
              padding: EdgeInsets.zero,
              child: Container(color: Theme.of(context).primaryColor.withOpacity(0.40), child: const SizedBox.expand()),
            ),
            title: Text(
              AppLocale.dashboard.getString(context),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            actions: [
              !isMobile
                  ? Padding(
                      padding: const EdgeInsets.only(right: CustomSpacer.medium),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withOpacity(0.05),
                          border: Border.all(color: Colors.black.withOpacity(0.15)),
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
            bottom: false,
            child: _isLoading
                ? const DashboardSkeleton()
                : !_hasData
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: EmptyMetricState(showActions: true)),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GlassContainer(
                          width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 800,
                          padding: const EdgeInsets.all(16.0),
                          blur: 40.0,
                          borderOpacity: 0.5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (Charts.salesYTDBySalesRep != null) GraphicBarMetricCard(titleBuilder: (ctx) => AppLocale.thisMonth.getString(context), initialData: _salesYTDBySalesRepData, dataLoader: _salesYTDBySalesRepLoader, subtitle: AppLocale.salesYTDBySalesRepDescription.getString(context), showTotal: true),
                              if (Charts.salesPerDayByProductCategory != null) ...[const SizedBox(height: CustomSpacer.medium), GraphicPieMetricCard(titleBuilder: (ctx) => AppLocale.today.getString(ctx), initialData: _salesPerDayByProductCategoryData, dataLoader: _salesPerDayByProductCategoryLoader, subtitle: AppLocale.todaySalesByCategoryDescription.getString(context), showTotal: true)],
                            ],
                          ),
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
