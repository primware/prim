// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:primware/views/Home/order/my_order_new.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../API/token.api.dart';
import '../../API/pos.api.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/localization/app_locale.dart';
import '../../shared/button.widget.dart';
import '../../shared/custom_checkbox.dart';
import '../../shared/custom_container.dart';
import '../../shared/custom_dropdown.dart';
import '../../shared/custom_spacer.dart';
import '../../shared/message.custom.dart';
import '../Home/dashboard/dashboard_view.dart';
import 'auth_funtions.dart';
import '../../API/user.api.dart';
import 'login_view.dart';

class ConfigPage extends StatefulWidget {
  final List<dynamic> clients;

  const ConfigPage({
    super.key,
    required this.clients,
  });

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
    setState(() {
      isLoading = true;
    });

    clients = widget.clients.map((client) {
      return {
        'id': client['id'],
        'name': client['name'],
      };
    }).toList();

    setState(() {
      isLoading = false;
    });
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

          final selectClient =
              clients.firstWhere((client) => client['id'] == clientId);
          UserData.clientName = selectClient['name'];
        });
      }
    }

    setState(() {
      isLoading = false;
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

  Future<void> _onRoleSelected(int? roleId) async {
    setState(() {
      selectedRoleId = roleId;
      organizations = [];
      selectedOrganizationId = null;
      isLoading = true;
    });

    if (roleId != null) {
      final fetchedOrganizations =
          await getOrganizations(selectedClientId!, roleId, context);
      if (fetchedOrganizations != null) {
        setState(() {
          organizations = fetchedOrganizations;
        });
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

  Future<void> _onContinue() async {
    if (selectedClientId != null &&
        selectedRoleId != null &&
        selectedOrganizationId != null) {
      Token.client = selectedClientId!;
      Token.rol = selectedRoleId;
      Token.organitation = selectedOrganizationId!;

      setState(() {
        isLoading = true;
      });
      bool login = await usuarioAuth(context: context);

      if (login) {
        if (rememberConfig) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String usuario = usuarioController.text.trim();
          await prefs.setInt('clientId_$usuario', selectedClientId!);
          await prefs.setInt('roleId_$usuario', selectedRoleId!);
          await prefs.setInt(
              'organizationId_$usuario', selectedOrganizationId!);
          await prefs.setString('roleName_$usuario', UserData.rolName!);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => POS.isPOS
                ? OrderNewPage(
                    doctypeID: POS.docTypeID,
                    orderName: POS.docTypeName,
                  )
                : DashboardPage(),
          ),
        );

        setState(() {
          isLoading = false;
        });
      }
    } else {
      SnackMessage.show(
        context: context,
        message: AppLocale.selectCompanyRoleOrganization.getString(context),
        type: SnackType.failure,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        MediaQuery.of(context).size.width < 750 ? true : false;

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
              Center(
                child: Text(
                  AppLocale.selectRole.getString(context),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
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
              Container(
                child: isLoading
                    ? ButtonLoading(
                        fullWidth: true,
                      )
                    : ButtonPrimary(
                        texto: AppLocale.continueKey.getString(context),
                        fullWidth: true,
                        onPressed: _onContinue,
                      ),
              ),
              const SizedBox(height: 12),
              ButtonSecondary(
                  texto: AppLocale.back.getString(context),
                  fullWidth: true,
                  onPressed: () async {
                    Navigator.pop(context);
                  }),
            ],
          ),
        ),
      )),
    );
  }
}
