// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../API/token.api.dart';
import '../../API/pos.api.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/localization/app_locale.dart';
import '../../shared/button.widget.dart';
import '../../shared/custom_container.dart';
import '../../shared/custom_dropdown.dart';
import '../../shared/custom_spacer.dart';
import '../../shared/toast_message.dart';
import '../Home/dashboard/dashboard_view.dart';
import '../Home/dashboard/dashboard_funtions.dart';
import 'auth_funtions.dart';
import '../../API/user.api.dart';
import 'login_view.dart';
import 'loading_dialog.dart';
import '../Home/order/product_selection_popup.dart';
import 'dart:ui';

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
  
  // Cachés locales para evitar volver a consultar si el usuario cambia de opción y regresa
  final Map<int, List<Map<String, dynamic>>> _cachedRoles = {};
  final Map<String, List<Map<String, dynamic>>> _cachedOrgs = {};

  @override
  void initState() {
    super.initState();
    clients = widget.clients.map((e) => e as Map<String, dynamic>).toList();
    _loadClients();

    _loadRememberedConfig();
  }

  Future<void> _loadClients() async {
    setState(() {
      isLoading = true;
    });

    clients = widget.clients.map((client) {
      return {'id': client['id'], 'name': client['name']};
    }).toList();

    setState(() {
      isLoading = false;
    });

    if (clients.length == 1 && selectedClientId == null) {
      // Autoseleccionar si solo hay un grupo empresarial y empezar a cargar de fondo
      _onClientSelected(clients[0]['id']);
    }
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
      if (_cachedRoles.containsKey(clientId)) {
        // Usar caché si existe
        setState(() {
          roles = _cachedRoles[clientId]!;
          if (roles.length == 1) {
            selectedRoleId = roles[0]['id'];
            _onRoleSelected(selectedRoleId);
          }
          final selectClient = clients.firstWhere((client) => client['id'] == clientId);
          UserData.clientName = selectClient['name'];
        });
      } else {
        final fetchedRoles = await getRoles(clientId, context);
        if (fetchedRoles != null) {
          _cachedRoles[clientId] = fetchedRoles;
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
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _onRoleSelected(int? roleId) async {
    setState(() {
      selectedRoleId = roleId;
      organizations = [];
      selectedOrganizationId = null;
      isLoading = true;
    });

    if (roleId != null) {
      final cacheKey = '${selectedClientId}_$roleId';
      if (_cachedOrgs.containsKey(cacheKey)) {
        setState(() {
          organizations = _cachedOrgs[cacheKey]!;
          if (organizations.length == 1) {
            selectedOrganizationId = organizations[0]['id'];
            _onOrganizationSelected(selectedOrganizationId);
          }
        });
      } else {
        final fetchedOrganizations = await getOrganizations(selectedClientId!, roleId, context);
        if (fetchedOrganizations != null) {
          fetchedOrganizations.removeWhere((org) => org['id'] == 0);
          _cachedOrgs[cacheKey] = fetchedOrganizations;
          setState(() {
            organizations = fetchedOrganizations;

            if (organizations.length == 1) {
              selectedOrganizationId = organizations[0]['id'];
              _onOrganizationSelected(selectedOrganizationId);
            }
          });
        }
      }
    }

    final selectedRole = roles.firstWhere((role) => role['id'] == roleId);
    UserData.rolName = selectedRole['name'];

    setState(() {
      isLoading = false;
    });
  }

  void _onOrganizationSelected(int? organizationId) {
    setState(() {
      selectedOrganizationId = organizationId;
    });
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

  Future<void> _onContinue() async {
    if (selectedClientId != null && selectedRoleId != null && selectedOrganizationId != null) {
      Token.client = selectedClientId!;
      Token.rol = selectedRoleId;
      Token.organitation = selectedOrganizationId!;

      setState(() {
        isLoading = true;
      });

      DynamicLoadingDialog.show(context);

      // Limpiamos los datos específicos del rol/organización antes de autenticar
      // Esto evita fugas de memoria (como guardar una orden en la organización anterior)
      Token.warehouseID = null;
      Token.adOrgInfoUU = null;
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
      clearDashboardRawCache();
      ProductSelectionPopup.clearGlobalCache();

      bool login = await usuarioAuth(context: context, forceNewToken: true);

      if (!mounted) return;

      DynamicLoadingDialog.hide(context);

      if (login) {
        if (rememberConfig) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String usuario = usuarioController.text.trim();
          await prefs.setInt('clientId_$usuario', selectedClientId!);
          await prefs.setInt('roleId_$usuario', selectedRoleId!);
          await prefs.setInt('organizationId_$usuario', selectedOrganizationId!);
          await prefs.setString('roleName_$usuario', UserData.rolName!);
        }

        // Usamos pushAndRemoveUntil para destruir el Dashboard anterior
        // y evitar que se queden abiertas múltiples pantallas viejas de fondo.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => POS.isPOS
                ? OrderNewPage(doctypeID: POS.docTypeID, orderName: POS.docTypeName, isRefund: POS.docSubType == 'RM')
                : DashboardPage(),
          ),
          (Route<dynamic> route) => false,
        );

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ToastMessage.show(context: context, message: AppLocale.selectCompanyRoleOrganization.getString(context), type: ToastType.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 750 ? true : false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: CustomContainer(
            maxWidthContainer: isMobile ? 420 : 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Text(AppLocale.selectRole.getString(context), style: Theme.of(context).textTheme.headlineSmall)),
                const SizedBox(height: CustomSpacer.medium),
                SearchableDropdown<int>(
                  value: selectedClientId,
                  options: clients,
                  showSearchBox: false,
                  labelText: AppLocale.company.getString(context),
                  onChanged: _onClientSelected,
                ),
                const SizedBox(height: CustomSpacer.medium),
                SearchableDropdown<int>(
                  value: selectedRoleId,
                  options: roles,
                  showSearchBox: false,
                  labelText: AppLocale.role.getString(context),
                  onChanged: _onRoleSelected,
                ),
                const SizedBox(height: CustomSpacer.medium),
                SearchableDropdown<int>(
                  value: selectedOrganizationId,
                  options: organizations,
                  showSearchBox: false,
                  labelText: AppLocale.organization.getString(context),
                  onChanged: _onOrganizationSelected,
                ),
                const SizedBox(height: CustomSpacer.medium),
                const SizedBox(height: CustomSpacer.medium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.save_as_outlined,
                            size: 24,
                            color: rememberConfig ? Theme.of(context).primaryColor : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocale.rememberMe.getString(context),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: rememberConfig ? FontWeight.bold : FontWeight.w500,
                              color: rememberConfig
                                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)
                                  : Colors.grey.shade600,
                            ),
                          ),
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
                  child: isLoading
                      ? ButtonLoading(fullWidth: true)
                      : ButtonPrimary(texto: AppLocale.continueKey.getString(context), fullWidth: true, onPressed: _onContinue),
                ),
                const SizedBox(height: 12),
                ButtonSecondary(
                  texto: AppLocale.back.getString(context),
                  fullWidth: true,
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlassSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? primary.withOpacity(0.3) : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          border: Border.all(color: value ? primary.withOpacity(0.6) : (isDark ? Colors.white30 : Colors.black12), width: 1.5),
          boxShadow: [if (value) BoxShadow(color: primary.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              top: 2,
              bottom: 2,
              left: value ? 26 : 2,
              right: value ? 2 : 26,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value ? primary.withOpacity(0.8) : (isDark ? Colors.white70 : Colors.white),
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
