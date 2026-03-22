// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // NUEVO IMPORT PARA EL CRISTAL
import '../../../API/token.api.dart';
import '../../API/pos.api.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/localization/app_locale.dart';
import '../../shared/button.widget.dart';
import '../../shared/custom_checkbox.dart';
import '../../shared/custom_spacer.dart'; // Quitamos custom_dropdown.dart porque usaremos BottomSheets
import '../../shared/toast_message.dart';
import '../Home/dashboard/dashboard_view.dart';
import 'auth_funtions.dart';
import '../../API/user.api.dart';
import 'login_view.dart'; // Para reutilizar LiquidBackground y GlassContainer si están allí, o las declaramos abajo.

// Si LiquidBackground y GlassContainer no están exportadas de forma global, las replicamos aquí rápido para asegurar que no se rompa:
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

  // --- LÓGICA ORIGINAL INTACTA ---
  Future<void> _loadClients() async {
    setState(() => isLoading = true);
    clients = widget.clients.map((client) => {'id': client['id'], 'name': client['name']}).toList();
    setState(() => isLoading = false);
  }

  Future<void> _onClientSelected(int? clientId) async {
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
      setState(() {
        selectedClientId = clientId;
        selectedRoleId = roleId;
        selectedOrganizationId = organizationId;
        rememberConfig = true;
        UserData.rolName = roleName;
        Token.rol = selectedRoleId;
      });
      await _onClientSelected(clientId);
      await _onRoleSelected(roleId);
      _onOrganizationSelected(organizationId);
    }
  }

  Future<void> _onRoleSelected(int? roleId) async {
    setState(() {
      selectedRoleId = roleId;
      organizations = [];
      selectedOrganizationId = null;
      isLoading = true;
    });

    if (roleId != null) {
      final fetchedOrganizations = await getOrganizations(selectedClientId!, roleId, context);
      if (fetchedOrganizations != null) {
        setState(() => organizations = fetchedOrganizations);
      }
    }
    final selectedRole = roles.firstWhere((role) => role['id'] == roleId);
    UserData.rolName = selectedRole['name'];
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

  // ------------------------------------------------------------------
  // NUEVA LÓGICA: MENÚS INFERIORES PREMIUM (Sustituyen al Dropdown)
  // ------------------------------------------------------------------
  void _showSelectionBottomSheet(String title, List<Map<String, dynamic>> items, int? currentValue, Function(int?) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.1), // Sutil oscuridad
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return GlassConfigContainer(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Container(
            // Limitamos la altura máxima al 70% de la pantalla para evitar que cubra todo si hay muchos roles
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(height: 24),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // Lista de elementos scrolleable
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item['id'] == currentValue;
                      final primaryColor = Theme.of(context).primaryColor;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            onSelected(item['id']);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['name'].toString(),
                                    style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? primaryColor : Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                                if (isSelected) Icon(Icons.check_circle, color: primaryColor),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper para dibujar los botones selectores en pantalla
  // Helper para dibujar los botones selectores en pantalla (MÁS OSCUROS Y DEFINIDOS)
  Widget _buildSelectorButton(String label, int? selectedValue, List<Map<String, dynamic>> items, Function(int?) onSelected) {
    final String displayText = selectedValue == null ? 'Seleccionar...' : items.firstWhere((element) => element['id'] == selectedValue, orElse: () => {'name': 'Desconocido'})['name'].toString();

    final bool isDisabled = items.isEmpty && selectedValue == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: isDisabled ? Colors.grey : null),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDisabled ? null : () => _showSelectionBottomSheet(label, items, selectedValue, onSelected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              // 👇 HEMOS AUMENTADO LA OPACIDAD AQUÍ 👇
              color: isDisabled ? Colors.grey.withOpacity(0.1) : Theme.of(context).cardColor.withOpacity(0.55), // MÁS OSCURO (antes 0.3)
              borderRadius: BorderRadius.circular(12),
              // 👇 Y HEMOS DEFINIDO MÁS EL BORDE 👇
              border: Border.all(
                color: isDisabled ? Colors.transparent : Colors.grey.withOpacity(0.5), // MÁS DEFINIDO (antes 0.3)
                width: 1.5,
              ), // LIGERAMENTE MÁS ANCHO
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: selectedValue != null ? FontWeight.bold : FontWeight.normal, color: isDisabled ? Colors.grey : (selectedValue != null ? Theme.of(context).primaryColor : null)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: isDisabled ? Colors.grey : Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
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

        // 1. INYECTAMOS EL FONDO LÍQUIDO
        body: LiquidConfigBackground(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 2. CONTENEDOR DE CRISTAL
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

                        // --- MENÚS DESLIZABLES PREMIUM ---
                        _buildSelectorButton(AppLocale.company.getString(context), selectedClientId, clients, _onClientSelected),
                        const SizedBox(height: CustomSpacer.medium),

                        _buildSelectorButton(AppLocale.role.getString(context), selectedRoleId, roles, _onRoleSelected),
                        const SizedBox(height: CustomSpacer.medium),

                        _buildSelectorButton(AppLocale.organization.getString(context), selectedOrganizationId, organizations, _onOrganizationSelected),
                        const SizedBox(height: CustomSpacer.large),

                        // Checkbox intacto
                        CustomCheckbox(
                          value: rememberConfig,
                          text: AppLocale.rememberMe.getString(context),
                          onChanged: (newValue) {
                            setState(() {
                              rememberConfig = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: CustomSpacer.xlarge),

                        // Botones de acción intactos
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
    );
  }
}
