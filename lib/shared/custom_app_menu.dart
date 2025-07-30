// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/views/Auth/login_view.dart';
import 'package:primware/views/Home/dashboard/dashboard_view.dart';
import 'package:primware/views/Home/invoice/new_invoice_view.dart';
import 'package:primware/views/Home/product/my_product_view.dart';
import 'package:primware/views/Home/settings/degub_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/endpoint.api.dart';
import '../API/user.api.dart';
import '../main.dart';
import '../theme/colors.dart';
import '../theme/fonts.dart';
import '../views/Home/bpartner/bpartner_view.dart';
import '../views/Home/invoice/my_invoice_view.dart';
import 'custom_flat_button.dart';
import 'logo.dart';

final String? _label = Base.prod ? null : 'Test';

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
  bool _isDarkMode = false;
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

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
              if (_label != null) ...[
                const SizedBox(
                  width: 12,
                ),
                Text(
                  _label!,
                  style: FontsTheme.h5Bold(color: ColorTheme.atention),
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
              const SizedBox(
                width: CustomSpacer.medium,
              ),
              Tooltip(
                message: _isDarkMode ? 'Modo Oscuro' : 'Modo Claro',
                child: IconButton(
                    icon: Icon(
                      _isDarkMode ? Icons.nightlight : Icons.sunny,
                      color:
                          _isDarkMode ? ColorTheme.aD100 : ColorTheme.atention,
                    ),
                    onPressed: () {
                      ThemeManager.themeNotifier.toggleTheme();
                      _loadTheme();
                    }),
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
  bool _isDarkMode = false;
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: ListView(
          padding: EdgeInsets.only(
            top: CustomSpacer.medium,
            bottom: CustomSpacer.medium,
          ),
          children: [
            Center(
              child: Text(UserData.name ?? 'Usuario',
                  style: FontsTheme.h5Bold(
                    color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
                  )),
            ),
            const Divider(
              height: 24,
            ),
            ListTile(
              leading: Icon(
                Icons.dashboard_outlined,
                color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
              ),
              tileColor: Theme.of(context).cardColor,
              title: Text(
                'Dashboard',
                style: TextStyle(
                  color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
                ),
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
            ListTile(
              leading: Icon(
                Icons.add,
                color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
              ),
              title: Text(
                'Nueva orden',
                style: TextStyle(
                  color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
                ),
              ),
              tileColor: Theme.of(context).cardColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InvoicePage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.attach_money_outlined,
                color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
              ),
              tileColor: Theme.of(context).cardColor,
              title: Text(
                'Mis ordenes',
                style: TextStyle(
                  color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
                ),
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
                color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
              ),
              tileColor: Theme.of(context).cardColor,
              title: Text(
                'Productos',
                style: TextStyle(
                  color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
                ),
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
                color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
              ),
              tileColor: Theme.of(context).cardColor,
              title: Text(
                'Clientes',
                style: TextStyle(
                  color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
                ),
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

            ListTile(
              leading: Icon(
                Icons.settings,
                color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
              ),
              tileColor: Theme.of(context).cardColor,
              title: Text(
                'Debug Panel',
                style: TextStyle(
                  color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
                ),
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
            // ListTile(
            //   tileColor: Theme.of(context).cardColor,
            //   leading: Icon(
            //     _isDarkMode ? Icons.nightlight : Icons.sunny,
            //     color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.atention,
            //   ),
            //   title: Text(
            //     _isDarkMode ? 'Modo oscuro' : 'Modo claro',
            //     style: TextStyle(
            //       color: _isDarkMode ? ColorTheme.aD100 : ColorTheme.tD300,
            //     ),
            //   ),
            //   onTap: () {
            //     ThemeManager.themeNotifier.toggleTheme();
            //     _loadTheme();
            //   },
            // ),
            ListTile(
              tileColor: Theme.of(context).cardColor,
              leading: Icon(
                Icons.logout_outlined,
                color: ColorTheme.error,
              ),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: ColorTheme.error,
                ),
              ),
              onTap: () {
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
              },
            ),
          ],
        ),
      ),
    );
  }
}
