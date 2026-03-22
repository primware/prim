// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:primware/views/Auth/config_view.dart';
import 'package:primware/views/Auth/auth_funtions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/views/Auth/login_view.dart';
import 'package:primware/views/Home/dashboard/dashboard_view.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
import 'package:primware/views/Home/product/product_view.dart';
import 'package:primware/views/Home/report/close_cash_view.dart';
import 'package:primware/views/Home/settings/degub_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/toast_message.dart';
import '../shared/file_picker_helper.dart';
import '../API/endpoint.dart';
import '../API/pos.api.dart';
import '../API/user.api.dart';
import '../localization/app_locale.dart';
import '../theme/colors.dart';
import '../views/Home/bpartner/bpartner_view.dart';
import '../views/Home/dashboard/dashboard_funtions.dart';
import '../views/Home/order/my_order.dart';
import '../views/Home/report/close_cash_detail.dart';
import '../views/Home/report/report_funtions.dart';
import 'custom_flat_button.dart';
import 'logo.dart';

class CustomAppMenu extends StatelessWidget {
  const CustomAppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) => (constraints.maxWidth > 750) ? const _TableDesktopMenu() : _MobileMenu());
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      width: double.maxFinite,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Logo(width: 200),
              if (!Base.prod) ...[
                const SizedBox(width: CustomSpacer.large),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    'Entorno de pruebas',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const Spacer(),
              CustomFlatButton(
                text: Token.auth != null ? 'Panel' : 'Acceder',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Token.auth != null ? const DashboardPage() : const LoginPage()));
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: CustomSpacer.medium),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) => IconButton(icon: const Icon(Icons.menu), color: Theme.of(context).primaryColor, onPressed: () => Scaffold.of(context).openDrawer()),
            ),
            const Logo(width: 150),
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
  bool _isDarkMode = false, _isCreatingCloseCash = false;

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

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocale.confirmLogout.getString(context)),
        content: Text(AppLocale.logoutMessage.getString(context)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocale.no.getString(context))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );
  }

  Future<void> cleanSessionData() async {
    usuarioController.clear();
    claveController.clear();
    Token.auth = null;
    Token.preAuth = null;
    Token.superAuth = null;
    Token.warehouseID = null;
    Token.client = null;
    Token.rol = null;
    Token.organitation = null;
    UserData.id = null;
    UserData.name = null;
    UserData.email = null;
    UserData.phone = null;
    UserData.imageBytes = null;
    UserData.rolName = null;
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
    POSPrinter.logo = null;
    POSPrinter.isLogoSet = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(
        drawerTheme: const DrawerThemeData(backgroundColor: Colors.transparent, elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      ),
      child: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.1), // Sombra más suave en modo claro
                  blurRadius: 20,
                  offset: const Offset(5, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0), // Desenfoque cristalino
                child: Container(
                  // Magia adaptativa: Oscuro para Dark Mode, Blanco translúcido para Light Mode
                  color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.65),
                  child: Column(
                    children: [
                      // --- CABECERA ---
                      _buildHeader(context, isDark),

                      // --- LISTA DE MENÚ ---
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildPillMenu(
                              context,
                              icon: Icons.dashboard_outlined,
                              title: AppLocale.dashboard.getString(context),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardPage())),
                            ),

                            const SizedBox(height: 15),
                            Divider(color: isDark ? Colors.white24 : Colors.black12, height: 1),
                            _buildSectionTitle('OPERACIONES COMERCIALES', isDark),

                            if (POS.docTypesComplete.isEmpty)
                              _buildPillMenu(
                                context,
                                icon: Icons.add_circle_outline,
                                title: AppLocale.newOrder.getString(context),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderNewPage())),
                              ),

                            if (POS.docTypesComplete.isNotEmpty)
                              ...POS.docTypesComplete.map((doc) {
                                final dynamic rawId = doc['id'];
                                final int? docTypeId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
                                final bool isRefund = doc['DocSubTypeSO'] == 'RM' || docTypeId == POS.docTypeRefundID;
                                return _buildPillMenu(
                                  context,
                                  icon: isRefund ? Icons.assignment_return_outlined : Icons.add_circle_outline,
                                  title: (doc['name'] ?? doc['Name'] ?? 'Documento').toString(),
                                  iconColor: isRefund ? Colors.redAccent : null,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderNewPage(doctypeID: docTypeId, orderName: doc['name'], isRefund: isRefund),
                                    ),
                                  ),
                                );
                              }),

                            _buildPillMenu(
                              context,
                              icon: Icons.receipt_long_outlined,
                              title: AppLocale.myOrders.getString(context),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderListPage())),
                            ),

                            if (POS.isPOS) ...[
                              const SizedBox(height: 15),
                              Divider(color: isDark ? Colors.white24 : Colors.black12, height: 1),
                              _buildSectionTitle('PUNTO DE VENTA', isDark),
                              _buildPillMenu(context, icon: Icons.point_of_sale_outlined, title: AppLocale.closeCash.getString(context), isLoading: _isCreatingCloseCash, onTap: _isCreatingCloseCash ? null : _handleCloseCashLogic),
                              _buildPillMenu(
                                context,
                                icon: Icons.history_outlined,
                                title: AppLocale.mycloseCashs.getString(context),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseCashPage())),
                              ),
                            ],

                            const SizedBox(height: 15),
                            Divider(color: isDark ? Colors.white24 : Colors.black12, height: 1),
                            _buildSectionTitle('CATÁLOGOS', isDark),
                            _buildPillMenu(
                              context,
                              icon: Icons.inventory_2_outlined,
                              title: AppLocale.products.getString(context),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListPage())),
                            ),
                            _buildPillMenu(
                              context,
                              icon: Icons.people_alt_outlined,
                              title: AppLocale.customers.getString(context),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BPartnerListPage())),
                            ),

                            const SizedBox(height: 15),
                            Divider(color: isDark ? Colors.white24 : Colors.black12, height: 1),
                            _buildSectionTitle('SISTEMA', isDark),

                            //! BOTÓN MODO OSCURO INTACTO
                            // _buildPillMenu(
                            //   context,
                            //   icon: _isDarkMode ? Icons.nightlight : Icons.sunny,
                            //   title: _isDarkMode ? 'Modo oscuro' : 'Modo claro',
                            //   onTap: () {
                            //     ThemeManager.themeNotifier.toggleTheme();
                            //     _loadTheme();
                            //   },
                            // ),
                            _buildPillMenu(context, icon: Icons.manage_accounts_outlined, title: 'Cambiar Rol', onTap: _handleChangeRole),
                            if (!Base.prod)
                              _buildPillMenu(
                                context,
                                icon: Icons.settings_outlined,
                                title: AppLocale.settings.getString(context),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugPage())),
                              ),
                          ],
                        ),
                      ),

                      // --- FOOTER ---
                      Divider(color: isDark ? Colors.white24 : Colors.black12, height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
                        child: _buildPillMenu(context, icon: Icons.logout_rounded, title: AppLocale.logout.getString(context), iconColor: Colors.redAccent, textColor: Colors.redAccent, onTap: _handleLogout),
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

  // --- CABECERA ---
  Widget _buildHeader(BuildContext context, bool isDark) {
    final String name = UserData.name ?? 'Usuario';
    final String initials = name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'US';
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: _updateLogo,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : primary.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.2) : primary.withOpacity(0.3), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.transparent,
                backgroundImage: POSPrinter.logo != null ? MemoryImage(POSPrinter.logo!) : null,
                child: POSPrinter.logo == null
                    ? Text(
                        initials,
                        style: TextStyle(color: isDark ? Colors.white : primary, fontWeight: FontWeight.bold, fontSize: 18),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  UserData.rolName ?? 'LIRION ERP',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.black45, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  // --- BOTONES ESTILO PÍLDORAS ---
  Widget _buildPillMenu(BuildContext context, {required IconData icon, required String title, required VoidCallback? onTap, Color? iconColor, Color? textColor, bool isLoading = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // Fonde claro/translúcido si es modo claro, fondo oscuro translúcido si es oscuro
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.7), width: 1.5),
        ),
        child: Row(
          children: [
            isLoading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: isDark ? Colors.white : primary, strokeWidth: 2)) : Icon(icon, size: 18, color: iconColor ?? (isDark ? Colors.white70 : primary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: textColor ?? (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            if (onTap != null && !isLoading) Icon(Icons.chevron_right, color: isDark ? Colors.white.withOpacity(0.3) : Colors.black26, size: 18),
          ],
        ),
      ),
    );
  }

  // --- FUNCIONES LÓGICAS INTACTAS ---
  Future<void> _updateLogo() async {
    final picked = await pickValidFile(context: context, maxUploadMB: 4);
    if (picked == null) return;
    final bytes = picked['fileBytes'] as Uint8List;
    setState(() {
      POSPrinter.logo = bytes;
      POSPrinter.isLogoSet = true;
    });
    final ok = await updateOrgLogo(bytes, context);
    if (!mounted) return;
    if (ok) {
      ToastMessage.show(context: context, message: 'Logo actualizado correctamente', type: ToastType.success);
    } else {
      ToastMessage.show(context: context, message: 'No se pudo actualizar el logo', type: ToastType.failure);
    }
  }

  Future<void> _handleChangeRole() async {
    final String currentUser = usuarioController.text.trim();
    final String currentPass = claveController.text.trim();
    final authData = await preAuth(currentUser, currentPass, context);
    if (!mounted) return;
    if (authData != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ConfigPage(clients: authData['clients'])));
    } else {
      await cleanSessionData();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (Route<dynamic> route) => false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutConfirmation(context);
    if (confirmed == true) {
      await cleanSessionData();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  Future<void> _handleCloseCashLogic() async {
    setState(() => _isCreatingCloseCash = true);
    int? closeCashId = await currentCloseCash();
    if (closeCashId != null) {
      await updateCloseCashDateTrx(cdsCloseCashID: closeCashId);
      await refreshCloseCash(cdsCloseCashID: closeCashId);
      if (!mounted) return;
      setState(() => _isCreatingCloseCash = false);
      Navigator.push(context, MaterialPageRoute(builder: (_) => CloseCashDetailPage(record: {'success': true, 'Record_ID': closeCashId})));
      return;
    }
    final String nowText = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    try {
      final result = await postNewCloseCash(context: context, salesRepID: UserData.id, terminalID: POS.cPosID!, dateTrx: nowText);
      if (!mounted) return;
      setState(() => _isCreatingCloseCash = false);
      if (result['success'] == true) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => CloseCashDetailPage(record: result)));
      } else {
        ToastMessage.show(context: context, message: 'No se pudo crear el cierre de caja', type: ToastType.failure);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreatingCloseCash = false);
      ToastMessage.show(context: context, message: 'Error al crear el cierre de caja', type: ToastType.failure);
    }
  }
}
