// ignore_for_file: deprecated_member_use
import 'dart:typed_data';

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
import '../shared/toast_message.dart';
import '../shared/file_picker_helper.dart';
import '../API/endpoint.api.dart';
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
              Logo(width: 200),
              if (!Base.prod) ...[
                const SizedBox(width: CustomSpacer.large),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
  bool _isCreatingCloseCash = false;
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
          ElevatedButton(
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

    POSPrinter.logo = null;
    POSPrinter.isLogoSet = false;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.only(
          top: CustomSpacer.xlarge + CustomSpacer.xlarge,
          bottom: CustomSpacer.medium,
        ),
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (POSPrinter.logo != null)
                GestureDetector(
                  onTap: () async {
                    final picked = await pickValidFile(
                      context: context,
                      maxUploadMB: 4,
                    );
                    if (picked == null) return;
                    final bytes = picked['fileBytes'] as Uint8List;
                    setState(() {
                      POSPrinter.logo = bytes;
                      POSPrinter.isLogoSet = true;
                    });
                    final ok = await updateOrgLogo(bytes, context);
                    if (!mounted) return;
                    if (ok) {
                      ToastMessage.show(
                        context: context,
                        message: 'Logo actualizado correctamente',
                        type: ToastType.success,
                      );
                    } else {
                      ToastMessage.show(
                        context: context,
                        message: 'No se pudo actualizar el logo',
                        type: ToastType.failure,
                      );
                    }
                  },
                  child: Image.memory(
                    POSPrinter.logo!,
                    width: 160,
                    fit: BoxFit.contain,
                  ),
                ),
              if (POSPrinter.isLogoSet == false)
                TextButton(
                  child: Text(
                    AppLocale.yourLogo.getString(context),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    final picked = await pickValidFile(
                      context: context,
                      maxUploadMB: 4,
                    );
                    if (picked == null) return;
                    final bytes = picked['fileBytes'] as Uint8List;
                    setState(() {
                      POSPrinter.logo = bytes;
                      POSPrinter.isLogoSet = true;
                    });
                    final ok = await updateOrgLogo(bytes, context);
                    if (!mounted) return;
                    if (ok) {
                      ToastMessage.show(
                        context: context,
                        message: 'Logo actualizado correctamente',
                        type: ToastType.success,
                      );
                    } else {
                      ToastMessage.show(
                        context: context,
                        message: 'No se pudo actualizar el logo',
                        type: ToastType.failure,
                      );
                    }
                  },
                ),
              Text(
                UserData.name ?? 'Usuario',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ListTile(
            leading: Icon(Icons.dashboard_outlined),
            title: Text(
              AppLocale.dashboard.getString(context),
              style: TextStyle(),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardPage()),
              );
            },
          ),
          if (POS.docTypesComplete.isEmpty)
            ListTile(
              leading: Icon(Icons.add),
              title: Text(AppLocale.newOrder.getString(context)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderNewPage()),
                );
              },
            ),
          if (POS.docTypesComplete.isNotEmpty) ...[
            Column(
              children: [
                const Divider(height: 24),
                ...POS.docTypesComplete.map((doc) {
                  final dynamic rawId = doc['id'];
                  final int? docTypeId = rawId is int
                      ? rawId
                      : int.tryParse(rawId?.toString() ?? '');
                  final String title = (doc['name'] ?? doc['Name'] ?? '')
                      .toString();
                  return ListTile(
                    leading: Icon(
                      (doc['DocSubTypeSO'] == 'RM' ||
                              docTypeId == POS.docTypeRefundID)
                          ? Icons.undo
                          : Icons.add,
                      color:
                          (doc['DocSubTypeSO'] == 'RM' ||
                              docTypeId == POS.docTypeRefundID)
                          ? Colors.red
                          : null,
                    ),
                    title: Text(title.isEmpty ? 'Documento' : title),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderNewPage(
                            doctypeID: docTypeId,
                            orderName: doc['name'],
                            isRefund:
                                doc['DocSubTypeSO'] == 'RM' ||
                                docTypeId == POS.docTypeRefundID,
                          ),
                        ),
                      );
                    },
                  );
                }),
                const Divider(height: 24),
              ],
            ),
          ],
          if (POS.isPOS) ...[
            ListTile(
              leading: _isCreatingCloseCash
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print),
              title: Text(AppLocale.closeCash.getString(context)),
              onTap: _isCreatingCloseCash
                  ? null
                  : () async {
                      setState(() => _isCreatingCloseCash = true);

                      // Verificar si ya hay un cierre de caja abierto
                      int? closeCashId = await currentCloseCash();
                      if (closeCashId != null) {
                        await updateCloseCashDateTrx(
                          cdsCloseCashID: closeCashId,
                        );
                        await refreshCloseCash(cdsCloseCashID: closeCashId);

                        if (!mounted) return;
                        setState(() => _isCreatingCloseCash = false);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CloseCashDetailPage(
                              record: {
                                'success': true,
                                'Record_ID': closeCashId,
                              },
                            ),
                          ),
                        );
                        return;
                      }

                      final String nowText = DateFormat(
                        'yyyy-MM-dd HH:mm:ss',
                      ).format(DateTime.now());

                      try {
                        final result = await postNewCloseCash(
                          context: context,
                          salesRepID: UserData.id,
                          terminalID: POS.cPosID!,
                          dateTrx: nowText,
                        );

                        if (!mounted) return;
                        setState(() => _isCreatingCloseCash = false);

                        if (result['success'] == true) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CloseCashDetailPage(record: result),
                            ),
                          );
                        } else {
                          ToastMessage.show(
                            context: context,
                            message: 'No se pudo crear el cierre de caja',
                            type: ToastType.failure,
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _isCreatingCloseCash = false);
                        ToastMessage.show(
                          context: context,
                          message: 'Error al crear el cierre de caja',
                          type: ToastType.failure,
                        );
                      }
                    },
            ),

            ListTile(
              leading: Icon(Icons.list_alt_outlined),
              title: Text(AppLocale.mycloseCashs.getString(context)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CloseCashPage(),
                  ),
                );
              },
            ),
            const Divider(height: 24),
          ],
          ListTile(
            leading: Icon(Icons.attach_money_outlined),
            title: Text(
              AppLocale.myOrders.getString(context),
              style: TextStyle(),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderListPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.inventory_2_outlined),
            title: Text(AppLocale.products.getString(context)),
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
            leading: Icon(Icons.people_alt_outlined),
            title: Text(AppLocale.customers.getString(context)),
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
              leading: Icon(Icons.settings),
              title: Text(AppLocale.settings.getString(context)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DebugPage()),
                );
              },
            ),
          // BOTÓN DE CAMBIAR ROL
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('Cambiar Rol'),
            onTap: () async {
              // Rescatamos el usuario y clave actuales
              final String currentUser = usuarioController.text.trim();
              final String currentPass = claveController.text.trim();

              // Hacemos una pre-autenticación
              final authData = await preAuth(currentUser, currentPass, context);

              if (!mounted) return;

              if (authData != null) {
                // Navegación normal (APILA la vista).
                // Si el usuario le da a "Volver", la sesión intacta sigue ahí.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConfigPage(clients: authData['clients']),
                  ),
                );
              } else {
                // Fallback por si la contraseña cambió o el token expiró
                await cleanSessionData();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),

          ListTile(
            leading: Icon(Icons.logout_outlined, color: ColorTheme.error),
            title: Text(
              AppLocale.logout.getString(context),
              style: TextStyle(color: ColorTheme.error),
            ),
            onTap: () async {
              final confirmed = await _showLogoutConfirmation(context);
              if (confirmed == true) {
                await cleanSessionData();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
