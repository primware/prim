// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/views/Auth/login_view.dart';
import 'package:primware/views/Home/dashboard/dashboard_view.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
import 'package:primware/views/Home/product/product_view.dart';
import 'package:primware/views/Home/settings/degub_view.dart';
import '../API/endpoint.api.dart';
import '../API/pos.api.dart';
import '../API/user.api.dart';
import '../localization/app_locale.dart';
import '../theme/colors.dart';
import '../views/Home/bpartner/bpartner_view.dart';
import '../views/Home/order/my_order.dart';
import 'custom_flat_button.dart';
import 'logo.dart';

class CustomAppMenu extends StatelessWidget {
  const CustomAppMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) =>
          (constraints.maxWidth > 750) ? _TableDesktopMenu() : _MobileMenu(),
    );
  }
}

class _TableDesktopMenu extends StatefulWidget {
  const _TableDesktopMenu();

  @override
  State<_TableDesktopMenu> createState() => _TableDesktopMenuState();
}

class _TableDesktopMenuState extends State<_TableDesktopMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      width: double.maxFinite,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          // width: Base.maxWithApp,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Logo(
                width: 200,
              ),
              if (!Base.prod) ...[
                const SizedBox(width: CustomSpacer.large),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Entorno de pruebas',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
              const Spacer(),
              CustomFlatButton(
                text: Token.auth != null ? 'Panel' : 'Acceder',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Token.auth != null
                          ? const DashboardPage()
                          : const LoginPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(right: CustomSpacer.medium),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            Logo(
              width: 150,
            ),
          ],
        ),
      ),
    );
  }
}

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  @override
  void initState() {
    super.initState();
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocale.confirmLogout.getString(context)),
        content: Text(AppLocale.logoutMessage.getString(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocale.no.getString(context)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocale.yes.getString(context)),
          ),
        ],
      ),
    );
  }

  Future<void> cleanSessionData() async {
    // Limpiar controladores
    usuarioController.clear();
    claveController.clear();

    // Limpiar tokens
    Token.auth = null;
    Token.preAuth = null;
    Token.superAuth = null;
    Token.warehouseID = null;
    Token.client = null;
    Token.rol = null;
    Token.organitation = null;

    // Limpiar datos de usuario
    UserData.id = null;
    UserData.name = null;
    UserData.email = null;
    UserData.phone = null;
    UserData.imageBytes = null;
    UserData.rolName = null;

    // Limpiar datos POS
    POS.priceListID = null;
    POS.priceListVersionID = null;
    POS.docTypeID = null;
    POS.docTypeName = null;
    POS.docTypeRefundName = null;
    POS.templatePartnerID = null;
    POS.docTypeRefundID = null;
    POS.isPOS = false;
    POS.documentActions.clear();
    POS.principalTaxs.clear();
    POS.docTypesComplete.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.only(
          top: CustomSpacer.xlarge + CustomSpacer.xlarge + CustomSpacer.medium,
          bottom: CustomSpacer.medium,
        ),
        children: [
          Center(
            child: Text(UserData.name ?? 'Usuario',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    )),
          ),
          const Divider(
            height: 24,
          ),
          ListTile(
            leading: Icon(
              Icons.dashboard_outlined,
            ),
            title: Text(
              AppLocale.home.getString(context),
              style: TextStyle(),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardPage(),
                ),
              );
            },
          ),
          if (POS.docTypesComplete.isEmpty)
            ListTile(
              leading: Icon(
                Icons.add,
              ),
              title: Text(
                AppLocale.newOrder.getString(context),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderNewPage(),
                  ),
                );
              },
            ),
          if (POS.docTypesComplete.isNotEmpty) ...[
            Column(
              children: [
                const Divider(
                  height: 24,
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: CustomSpacer.medium),
                  child: Text(
                    'Nueva orden',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                ...POS.docTypesComplete.map((doc) {
                  final dynamic rawId = doc['id'];
                  final int? docTypeId = rawId is int
                      ? rawId
                      : int.tryParse(rawId?.toString() ?? '');
                  final String title =
                      (doc['name'] ?? doc['Name'] ?? '').toString();
                  return ListTile(
                    leading: Icon(
                      doc['DocSubTypeSO'] != 'RM' ? Icons.add : Icons.undo,
                      color: doc['DocSubTypeSO'] == 'RM' ? Colors.red : null,
                    ),
                    title: Text(title.isEmpty ? 'Documento' : title),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderNewPage(
                            doctypeID: docTypeId,
                            orderName: doc['name'],
                            isRefund: doc['DocSubTypeSO'] == 'RM',
                          ),
                        ),
                      );
                    },
                  );
                }),
                const Divider(
                  height: 24,
                ),
              ],
            ),
          ],
          ListTile(
            leading: Icon(
              Icons.attach_money_outlined,
            ),
            title: Text(
              AppLocale.myOrders.getString(context),
              style: TextStyle(),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderListPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.inventory_2_outlined,
            ),
            title: Text(
              AppLocale.products.getString(context),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.people_alt_outlined,
            ),
            title: Text(
              AppLocale.customers.getString(context),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BPartnerListPage(),
                ),
              );
            },
          ),
          if (!Base.prod)
            ListTile(
              leading: Icon(
                Icons.settings,
              ),
              title: Text(
                AppLocale.settings.getString(context),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugPage(),
                  ),
                );
              },
            ),
          ListTile(
            leading: Icon(
              Icons.logout_outlined,
              color: ColorTheme.error,
            ),
            title: Text(
              AppLocale.logout.getString(context),
              style: TextStyle(
                color: ColorTheme.error,
              ),
            ),
            onTap: () async {
              final confirmed = await _showLogoutConfirmation(context);
              if (confirmed == true) {
                await cleanSessionData();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
