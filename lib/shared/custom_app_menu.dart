// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:primware/views/Auth/config_view.dart';
import 'package:primware/views/Auth/auth_funtions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/views/Auth/login_view.dart' hide GlassContainer, LiquidBackground;
import 'package:primware/views/Home/dashboard/dashboard_view.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
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
import 'package:primware/Widgets/GlassDesign.dart';

class CustomAppMenu extends StatelessWidget {
  const CustomAppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) => (constraints.maxWidth > 750) ? const _TableDesktopMenu() : const _MobileMenu());
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
    // Menú superior con efecto cristal al ras
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(0),
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Logo(width: 200),
            if (!Base.prod) ...[
              const SizedBox(width: CustomSpacer.large),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                borderRadius: BorderRadius.circular(20),
                child: Text(
                  'Entorno de pruebas',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
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
    );
  }
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu();

  @override
  Widget build(BuildContext context) {
    // Cabecera móvil con cristal al ras
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 4),
      borderRadius: BorderRadius.circular(0),
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
  // ignore: unused_field
  bool _isDarkMode = false;
  bool _isCreatingCloseCash = false;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    Token.adOrgInfoUU = null;
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
    // 🌟 AQUÍ ESTÁ LA MAGIA DEL DESENFOQUE REAL
    return Drawer(
      backgroundColor: Colors.transparent, // Fundamental para ver el cristal de abajo
      elevation: 0,
      width: 320, // Un poco más ancho para lucir el diseño
      child: GlassContainer(
        // Panel lateral con esquinas redondeadas solo en la derecha
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(35)),
        padding: EdgeInsets.zero,
        blur: 15.0, // Desenfoque más suave para mayor claridad
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: AppLocale.dashboard.getString(context),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardPage())),
                  ),

                  const SizedBox(height: CustomSpacer.small),
                  _buildSectionTitle(context, 'OPERACIONES COMERCIALES'),

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
                            builder: (_) => OrderNewPage(doctypeID: docTypeId, orderName: doc['name'], isRefund: isRefund),
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

                  if (POS.isPOS) ...[
                    const SizedBox(height: CustomSpacer.small),
                    _buildSectionTitle(context, 'PUNTO DE VENTA'),
                    _buildMenuItem(context, icon: Icons.point_of_sale_outlined, title: AppLocale.closeCash.getString(context), isLoading: _isCreatingCloseCash, onTap: _isCreatingCloseCash ? null : _handleCloseCashLogic),
                    _buildMenuItem(
                      context,
                      icon: Icons.history_outlined,
                      title: AppLocale.mycloseCashs.getString(context),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseCashPage())),
                    ),
                  ],

                  const SizedBox(height: CustomSpacer.small),
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
                  const SizedBox(height: CustomSpacer.small),
                  _buildSectionTitle(context, 'SISTEMA'),

                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: AppLocale.settings.getString(context),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                    },
                  ),

                  _buildMenuItem(context, icon: Icons.manage_accounts_outlined, title: AppLocale.changeRole.getString(context), onTap: _handleChangeRole),

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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _buildMenuItem(context, icon: Icons.logout_rounded, title: AppLocale.logout.getString(context), iconColor: ColorTheme.error, textColor: ColorTheme.error, onTap: _handleLogout),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        // Línea sutil separadora entre el header y los menús
        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.transparent,
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
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  UserData.rolName ?? 'LIRION ERP',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13),
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
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  // 🌟 AQUÍ ESTÁ EL DISEÑO DE LA "PÍLDORA" PARA CADA MENÚ
  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback? onTap, Color? iconColor, Color? textColor, bool isLoading = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(50), // Forma redonda de Píldora
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.05), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50), // Efecto pulsación también redondo
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) else Icon(icon, color: iconColor ?? Theme.of(context).primaryColor, size: 22),

                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: textColor ?? Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),

                // Icono extra decorativo para un look más "App Nativa"
                Icon(Icons.chevron_right_rounded, color: Colors.grey.withOpacity(0.5), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LAS FUNCIONES SE MANTIENEN INTACTAS ---

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
