// ignore_for_file: deprecated_member_use
import 'dart:async';
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
import 'package:primware/views/Home/invoice/invoice_new.dart';
import 'package:primware/views/Home/product/product_view.dart';
import 'package:primware/views/Home/report/close_cash_view.dart';
import 'package:primware/views/Home/settings/degub_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/toast_message.dart';
import '../API/endpoint.dart';
import '../API/pos.api.dart';
import '../API/user.api.dart';
import '../localization/app_locale.dart';
import '../theme/colors.dart';
import '../views/Home/bpartner/bpartner_view.dart';
import '../views/Home/order/my_order.dart';
import '../views/Home/report/close_cash_detail.dart';
import '../views/Home/report/report_funtions.dart';
import 'package:primware/views/Home/settings/settings_view.dart';
import 'custom_flat_button.dart';
import 'logo.dart';

class CustomAppMenu extends StatelessWidget {
  const CustomAppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) => (constraints.maxWidth > 750) ? _TableDesktopMenu() : _MobileMenu());
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
              Logo(width: 200),
              if (!Base.prod) ...[
                const SizedBox(width: CustomSpacer.large),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    'Entorno de pruebas',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const Spacer(),
              CustomFlatButton(
                text: Token.auth != null ? 'Panel' : 'Acceder',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Token.auth != null ? const DashboardPage() : const LoginPage()),
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 6, offset: const Offset(0, 2))],
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
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Logo(width: 150),
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
    // Limpiar controladores
    usuarioController.clear();
    claveController.clear();

    // Limpiar tokens
    Token.auth = null;
    Token.preAuth = null;
    Token.superAuth = null;
    Token.warehouseID = null;
    Token.adOrgInfoUU = null;
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
    UserData.organizations = [];

    // Limpiar datos POS
    POS.priceListID = null;
    POS.priceListVersionID = null;
    POS.bankAccountID = null;
    POS.docTypeID = null;
    POS.docTypeName = null;
    POS.docTypeRefundName = null;
    POS.templatePartnerID = null;
    POS.docTypeRefundID = null;
    POS.isPOS = false;
    POS.isModifyPrice = false;
    POS.documentActions.clear();
    POS.principalTaxs.clear();
    POS.docTypesComplete.clear();

    POSPrinter.logo = null;
    POSPrinter.isLogoSet = false;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildHeader(context),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: AppLocale.dashboard.getString(context),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardPage())),
                ),

                const SizedBox(height: CustomSpacer.medium),
                _buildSectionTitle(context, 'OPERACIONES COMERCIALES'),

                _buildMenuItem(
                  context,
                  icon: Icons.payments_outlined,
                  title: AppLocale.invoicePayment.getString(context),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicePaymentPage())),
                ),

                // Pedidos / Ventas Dinámicos de iDempiere
                if (POS.docTypesComplete.isEmpty)
                  _buildMenuItem(
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
                    return _buildMenuItem(
                      context,
                      icon: isRefund ? Icons.assignment_return_outlined : Icons.add_circle_outline,
                      title: (doc['name'] ?? doc['Name'] ?? 'Documento').toString(),
                      iconColor: isRefund ? Colors.redAccent : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderNewPage(
                            doctypeID: docTypeId,
                            orderName: doc['name'],
                            isRefund: isRefund,
                            docSubTypeSO: doc['DocSubTypeSO']?.toString(),
                          ),
                        ),
                      ),
                    );
                  }),

                _buildMenuItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: AppLocale.myOrders.getString(context),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderListPage())),
                ),

                // Sección Punto de Venta
                if (POS.isPOS) ...[
                  const SizedBox(height: CustomSpacer.medium),
                  _buildSectionTitle(context, 'PUNTO DE VENTA'),
                  _buildMenuItem(
                    context,
                    icon: Icons.point_of_sale_outlined,
                    title: AppLocale.closeCash.getString(context),
                    isLoading: _isCreatingCloseCash,
                    onTap: _isCreatingCloseCash ? null : _handleCloseCashLogic,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.history_outlined,
                    title: AppLocale.mycloseCashs.getString(context),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseCashPage())),
                  ),
                ],

                const SizedBox(height: CustomSpacer.medium),
                _buildSectionTitle(context, 'CATÁLOGOS'),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  title: AppLocale.products.getString(context),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListPage())),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people_alt_outlined,
                  title: AppLocale.customers.getString(context),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BPartnerListPage())),
                ),
                const SizedBox(height: CustomSpacer.medium),
                _buildSectionTitle(context, 'SISTEMA'),

                //! BOTÓN MODO OSCURO
                // _buildMenuItem(
                //   context,
                //   icon: _isDarkMode ? Icons.nightlight : Icons.sunny,
                //   title: _isDarkMode ? 'Modo oscuro' : 'Modo claro',
                //   onTap: () {
                //     ThemeManager.themeNotifier.toggleTheme();
                //     _loadTheme();
                //   },
                // ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: AppLocale.settings.getString(context),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.manage_accounts_outlined,
                  title: AppLocale.changeRole.getString(context),
                  onTap: _handleChangeRole,
                ),

                if (!Base.prod)
                  _buildMenuItem(
                    context,
                    icon: Icons.terminal,
                    title: AppLocale.console.getString(context),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugPage())),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: _buildMenuItem(
              context,
              icon: Icons.logout_rounded,
              title: AppLocale.logout.getString(context),
              iconColor: ColorTheme.error,
              textColor: ColorTheme.error,
              onTap: _handleLogout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              backgroundImage: POSPrinter.logo != null ? MemoryImage(POSPrinter.logo!) : null,
              child: POSPrinter.logo == null ? Icon(Icons.business, color: Theme.of(context).primaryColor, size: 35) : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  UserData.name ?? 'Usuario',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  UserData.rolName ?? 'LIRION ERP',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 12),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, color: iconColor ?? Theme.of(context).primaryColor.withOpacity(0.8)),
        title: Text(
          title,
          style: TextStyle(color: textColor ?? Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
    );
  }

  Future<void> _handleChangeRole() async {
    // Rescatamos el usuario y clave actuales
    final String currentUser = usuarioController.text.trim();
    final String currentPass = claveController.text.trim();

    // Hacemos una pre-autenticación
    final authData = await preAuth(currentUser, currentPass, context);
    if (!mounted) return;

    if (authData != null) {
      // Si el usuario le da a "Volver", la sesión intacta sigue ahí.
      Navigator.push(context, MaterialPageRoute(builder: (_) => ConfigPage(clients: authData['clients'])));
    } else {
      // Fallback por si la contraseña cambió o el token expiró
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

    // Verificar si ya hay un cierre de caja abierto
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
