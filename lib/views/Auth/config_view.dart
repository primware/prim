import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../../Widgets/GlassDesign.dart';
import '../../../API/token.api.dart';
import '../../API/pos.api.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/localization/app_locale.dart';
import '../../shared/button.widget.dart';
import '../../shared/custom_checkbox.dart';
import '../../shared/custom_spacer.dart';
import '../../shared/toast_message.dart';
import '../Home/dashboard/dashboard_view.dart';
import 'auth_funtions.dart';
import '../../API/user.api.dart';
import 'login_view.dart';

class LiquidConfigBackground extends StatelessWidget {
  final Widget child;
  const LiquidConfigBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final secondary = Theme.of(context).colorScheme.secondary;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: bg),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [primary.withOpacity(isDark ? 0.35 : 0.15), Colors.transparent], stops: const [0.1, 1.0]),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [secondary.withOpacity(isDark ? 0.35 : 0.15), Colors.transparent], stops: const [0.1, 1.0]),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [primary.withOpacity(isDark ? 0.2 : 0.08), Colors.transparent], stops: const [0.1, 1.0]),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class GlassConfigContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const GlassConfigContainer({super.key, required this.child, this.width, this.padding});

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(24);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark ? Colors.black : Colors.white;

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.08), blurRadius: 24, spreadRadius: -5, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: br,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [glassColor.withOpacity(isDark ? 0.4 : 0.5), glassColor.withOpacity(isDark ? 0.1 : 0.2)]),
              border: Border.all(color: (isDark ? Colors.white30 : Colors.white).withOpacity(0.2), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class ConfigPage extends StatefulWidget {
  final List<dynamic> clients;

  const ConfigPage({super.key, required this.clients});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  bool isLoading = false;
  bool rememberConfig = false;
  int? selectedClientId;
  int? selectedRoleId;
  int? selectedOrganizationId;
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> organizations = [];

  @override
  void initState() {
    super.initState();
    clients = widget.clients.map((e) => e as Map<String, dynamic>).toList();
    _loadClients();
    _loadRememberedConfig();
  }

  Future<void> _loadClients() async {
    setState(() => isLoading = true);
    clients = widget.clients.map((client) => {'id': client['id'], 'name': client['name']}).toList();
    setState(() => isLoading = false);
  }

  Future<void> _onClientSelected(int? clientId) async {
    if (!mounted) return;
    setState(() {
      selectedClientId = clientId;
      roles = [];
      selectedRoleId = null;
      organizations = [];
      selectedOrganizationId = null;
      isLoading = true;
    });

    if (clientId != null) {
      final fetchedRoles = await getRoles(clientId, context);
      if (!mounted) return;
      if (fetchedRoles != null) {
        setState(() {
          roles = fetchedRoles;
          if (roles.length == 1) {
            selectedRoleId = roles[0]['id'];
            _onRoleSelected(selectedRoleId);
          }
          final selectClient = clients.firstWhere((client) => client['id'] == clientId);
          UserData.clientName = selectClient['name'];
        });
      }
    }
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _loadRememberedConfig() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String usuario = usuarioController.text.trim();
    int? clientId = prefs.getInt('clientId_$usuario');
    int? roleId = prefs.getInt('roleId_$usuario');
    int? organizationId = prefs.getInt('organizationId_$usuario');
    String? roleName = prefs.getString('roleName_$usuario');

    if (roleId != null && organizationId != null) {
      if (!mounted) return;
      setState(() {
        selectedClientId = clientId;
        selectedRoleId = roleId;
        selectedOrganizationId = organizationId;
        rememberConfig = true;
        UserData.rolName = roleName;
        Token.rol = selectedRoleId;
      });
      await _onClientSelected(clientId);
      if (!mounted) return;
      await _onRoleSelected(roleId);
      if (!mounted) return;
      _onOrganizationSelected(organizationId);
    }
  }

  Future<void> _onRoleSelected(int? roleId) async {
    if (!mounted) return;
    setState(() {
      selectedRoleId = roleId;
      organizations = [];
      selectedOrganizationId = null;
      isLoading = true;
    });

    if (roleId != null) {
      final fetchedOrganizations = await getOrganizations(selectedClientId!, roleId, context);
      if (!mounted) return;
      if (fetchedOrganizations != null) {
        setState(() => organizations = fetchedOrganizations);
      }
    }
    final selectedRole = roles.firstWhere((role) => role['id'] == roleId);
    UserData.rolName = selectedRole['name'];
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _onOrganizationSelected(int? organizationId) {
    setState(() => selectedOrganizationId = organizationId);
  }

  Future<void> _onContinue() async {
    if (selectedClientId != null && selectedRoleId != null && selectedOrganizationId != null) {
      Token.client = selectedClientId!;
      Token.rol = selectedRoleId;
      Token.organitation = selectedOrganizationId!;
      setState(() => isLoading = true);

      // Limpiamos los datos específicos del rol/organización
      Token.warehouseID = null;
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

      bool login = await usuarioAuth(context: context);
      if (!mounted) return;

      if (login) {
        if (rememberConfig) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String usuario = usuarioController.text.trim();
          await prefs.setInt('clientId_$usuario', selectedClientId!);
          await prefs.setInt('roleId_$usuario', selectedRoleId!);
          await prefs.setInt('organizationId_$usuario', selectedOrganizationId!);
          await prefs.setString('roleName_$usuario', UserData.rolName!);
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => POS.isPOS ? OrderNewPage(doctypeID: POS.docTypeID, orderName: POS.docTypeName, isRefund: POS.docSubType == 'RM') : const DashboardPage(),
          ),
          (Route<dynamic> route) => false,
        );
      }
      setState(() => isLoading = false);
    } else {
      ToastMessage.show(context: context, message: AppLocale.selectCompanyRoleOrganization.getString(context), type: ToastType.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 750 ? true : false;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,

        body: LiquidConfigBackground(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Focus(
                autofocus: true,
                onKey: (node, event) {
                  if (event is RawKeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                    _onContinue();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassConfigContainer(
                      width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 500,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 40, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Text(AppLocale.selectRole.getString(context), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: CustomSpacer.xlarge),

                          GlassDropdown<int>(
                            label: AppLocale.company.getString(context),
                            icon: Icons.business_outlined,
                            currentValue: selectedClientId == null ? '' : clients.firstWhere((e) => e['id'] == selectedClientId, orElse: () => {'name': ''})['name'].toString(),
                            items: clients.map((e) => GlassDropdownItem<int>(value: e['id'] as int, text: e['name'].toString())).toList(),
                            onChanged: _onClientSelected,
                          ),
                          const SizedBox(height: CustomSpacer.medium),

                          GlassDropdown<int>(
                            label: AppLocale.role.getString(context),
                            icon: Icons.admin_panel_settings_outlined,
                            currentValue: selectedRoleId == null ? '' : roles.firstWhere((e) => e['id'] == selectedRoleId, orElse: () => {'name': ''})['name'].toString(),
                            items: roles.map((e) => GlassDropdownItem<int>(value: e['id'] as int, text: e['name'].toString())).toList(),
                            onChanged: _onRoleSelected,
                          ),
                          const SizedBox(height: CustomSpacer.medium),

                          GlassDropdown<int>(
                            label: AppLocale.organization.getString(context),
                            icon: Icons.account_tree_outlined,
                            currentValue: selectedOrganizationId == null ? '' : organizations.firstWhere((e) => e['id'] == selectedOrganizationId, orElse: () => {'name': ''})['name'].toString(),
                            items: organizations.map((e) => GlassDropdownItem<int>(value: e['id'] as int, text: e['name'].toString())).toList(),
                            onChanged: _onOrganizationSelected,
                          ),
                          const SizedBox(height: CustomSpacer.large),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.save_as_outlined, size: 22, color: rememberConfig ? Theme.of(context).primaryColor : Colors.grey.shade600),
                                    const SizedBox(width: 12),
                                    Text(AppLocale.rememberMe.getString(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: rememberConfig ? FontWeight.bold : FontWeight.w500)),
                                  ],
                                ),
                                GlassSwitch(
                                  value: rememberConfig,
                                  onChanged: (newValue) {
                                    setState(() {
                                      rememberConfig = newValue;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: CustomSpacer.xlarge),

                          Container(
                            child: isLoading ? ButtonLoading(fullWidth: true) : ButtonPrimary(texto: AppLocale.continueKey.getString(context), fullWidth: true, onPressed: _onContinue),
                          ),
                          const SizedBox(height: 12),

                          ButtonSecondary(
                            texto: AppLocale.back.getString(context),
                            fullWidth: true,
                            onPressed: () {
                              Navigator.pop(context);
                            },
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
