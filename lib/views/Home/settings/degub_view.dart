import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/API/endpoint.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/API/user.api.dart';
import 'package:primware/localization/app_locale.dart';

import '../../../shared/custom_app_menu.dart';
import '../../../shared/footer.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Color _getLogLevelColor(String level) {
    level = level.toUpperCase();
    if (level.contains('ERROR')) return Colors.redAccent;
    if (level.contains('WARN')) return Colors.orangeAccent;
    if (level.contains('INFO')) return Colors.greenAccent;
    return Colors.white70;
  }

  String _value(dynamic value, {bool posOnly = false}) {
    if (posOnly && !POS.isPOS) {
      return AppLocale.notApplicable.getString(context);
    }
    if (value == null ||
        value.toString().trim().isEmpty ||
        value.toString() == 'null') {
      return AppLocale.notApplicable.getString(context);
    }
    return value.toString();
  }

  String _namedValue(dynamic id, dynamic name, {bool posOnly = false}) {
    if (posOnly && !POS.isPOS) {
      return AppLocale.notApplicable.getString(context);
    }
    final cleanName = name?.toString().trim() ?? '';
    if (id == null && cleanName.isEmpty) {
      return AppLocale.notApplicable.getString(context);
    }
    if (id == null) return cleanName;
    if (cleanName.isEmpty) return id.toString();
    return '$cleanName (#$id)';
  }

  String _boolValue(bool value, {bool posOnly = false}) {
    if (posOnly && !POS.isPOS) {
      return AppLocale.notApplicable.getString(context);
    }
    return (value ? AppLocale.enabled : AppLocale.disabled).getString(context);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          final labelWidget = Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          );
          final valueWidget = SelectableText(
            value,
            textAlign: compact ? TextAlign.start : TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelWidget, const SizedBox(height: 3), valueWidget],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: labelWidget),
              const SizedBox(width: 16),
              Expanded(child: valueWidget),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: colors.outlineVariant),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModeBanner() {
    final colors = Theme.of(context).colorScheme;
    final isPOS = POS.isPOS;
    final accent = isPOS ? colors.primary : colors.tertiary;
    return Semantics(
      label: AppLocale.operatingMode.getString(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.45), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPOS ? Icons.point_of_sale : Icons.storefront_outlined,
                color: accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (isPOS
                            ? AppLocale.pointOfSaleMode
                            : AppLocale.salesForceMode)
                        .getString(context),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (isPOS
                            ? AppLocale.pointOfSaleModeDescription
                            : AppLocale.salesForceModeDescription)
                        .getString(context),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idLabel = AppLocale.identifier.getString(context);
    return Scaffold(
      drawer: const MenuDrawer(),
      appBar: AppBar(
        title: Text(AppLocale.console.getString(context)),
        centerTitle: true,
      ),
      bottomNavigationBar: const CustomFooter(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModeBanner(),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final cards = [
                      _buildSection(
                        title: AppLocale.sessionParameters.getString(context),
                        icon: Icons.dns_outlined,
                        children: [
                          _buildInfoRow(
                            AppLocale.production.getString(context),
                            _boolValue(Base.prod),
                          ),
                          _buildInfoRow(
                            AppLocale.instance.getString(context),
                            _value(Base.baseURL),
                          ),
                        ],
                      ),
                      _buildSection(
                        title: AppLocale.terminalParameters.getString(context),
                        icon: Icons.point_of_sale_outlined,
                        children: [
                          _buildInfoRow(
                            '${AppLocale.posTerminal.getString(context)} $idLabel',
                            _value(POS.cPosID, posOnly: true),
                          ),
                          _buildInfoRow(
                            AppLocale.modifyPricePermission.getString(context),
                            _boolValue(POS.isModifyPrice, posOnly: true),
                          ),
                          _buildInfoRow(
                            AppLocale.defaultCustomer.getString(context),
                            _namedValue(
                              POS.templatePartnerID,
                              POS.templatePartnerName,
                              posOnly: true,
                            ),
                          ),
                          _buildInfoRow(
                            AppLocale.priceList.getString(context),
                            _value(POS.priceListID),
                          ),
                          _buildInfoRow(
                            AppLocale.priceListVersion.getString(context),
                            _value(POS.priceListVersionID),
                          ),
                          _buildInfoRow(
                            AppLocale.warehouse.getString(context),
                            _value(POS.warehouseID ?? Token.warehouseID),
                          ),
                          _buildInfoRow(
                            AppLocale.paymentTerm.getString(context),
                            _value(POS.cPaymentTermID),
                          ),
                          _buildInfoRow(
                            AppLocale.bankAccount.getString(context),
                            _value(POS.bankAccountID, posOnly: true),
                          ),
                          _buildInfoRow(
                            AppLocale.salesDocumentType.getString(context),
                            _namedValue(POS.docTypeID, POS.docTypeName),
                          ),
                          _buildInfoRow(
                            AppLocale.refundDocumentType.getString(context),
                            _namedValue(
                              POS.docTypeRefundID,
                              POS.docTypeRefundName,
                              posOnly: true,
                            ),
                          ),
                          _buildInfoRow(
                            AppLocale.discountCharge.getString(context),
                            _value(POS.discountChargeID, posOnly: true),
                          ),
                          _buildInfoRow(
                            AppLocale.discountTax.getString(context),
                            _namedValue(
                              POS.discountTaxID,
                              POS.discountTaxRate,
                              posOnly: true,
                            ),
                          ),
                          _buildInfoRow(
                            AppLocale.multiplePayments.getString(context),
                            _boolValue(
                              POSTenderType.isMultiPayment,
                              posOnly: true,
                            ),
                          ),
                        ],
                      ),
                      _buildSection(
                        title: AppLocale.userParameters.getString(context),
                        icon: Icons.person_outline,
                        children: [
                          _buildInfoRow(idLabel, _value(UserData.id)),
                          _buildInfoRow(
                            AppLocale.name.getString(context),
                            _value(UserData.name),
                          ),
                          _buildInfoRow(
                            AppLocale.email.getString(context),
                            _value(UserData.email),
                          ),
                        ],
                      ),
                      _buildSection(
                        title: AppLocale.organizationParameters.getString(
                          context,
                        ),
                        icon: Icons.business_outlined,
                        children: [
                          _buildInfoRow(
                            AppLocale.company.getString(context),
                            _namedValue(Token.client, UserData.clientName),
                          ),
                          _buildInfoRow(
                            AppLocale.role.getString(context),
                            _namedValue(Token.rol, UserData.rolName),
                          ),
                          _buildInfoRow(
                            '${AppLocale.organization.getString(context)} $idLabel',
                            _value(Token.organitation),
                          ),
                          _buildInfoRow(
                            '${AppLocale.warehouse.getString(context)} $idLabel',
                            _value(Token.warehouseID),
                          ),
                        ],
                      ),
                      _buildSection(
                        title: AppLocale.printingParameters.getString(context),
                        icon: Icons.print_outlined,
                        children: [
                          _buildInfoRow(
                            AppLocale.printerName.getString(context),
                            _value(POSPrinter.headerName),
                          ),
                          _buildInfoRow(
                            AppLocale.printerAddress.getString(context),
                            _value(POSPrinter.headerAddress),
                          ),
                          _buildInfoRow(
                            AppLocale.printerTaxId.getString(context),
                            _value(POSPrinter.headerTaxID),
                          ),
                          _buildInfoRow(
                            AppLocale.printerDv.getString(context),
                            _value(POSPrinter.headerDV),
                          ),
                          _buildInfoRow(
                            AppLocale.printerPhone.getString(context),
                            _value(POSPrinter.headerPhone),
                          ),
                          _buildInfoRow(
                            AppLocale.printerEmail.getString(context),
                            _value(POSPrinter.headerEmail),
                          ),
                        ],
                      ),
                    ];
                    if (!wide) {
                      return Column(
                        children: cards
                            .map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: card,
                              ),
                            )
                            .toList(),
                      );
                    }
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: cards
                          .map(
                            (card) => SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: card,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.terminal, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              AppLocale.systemLogs.getString(context),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(CurrentLogMessage.log.clear),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                      label: Text(AppLocale.clear.getString(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: MediaQuery.of(context).size.height * 0.55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: CurrentLogMessage.log.length,
                      itemBuilder: (context, index) {
                        final entry = CurrentLogMessage.log[index];
                        final ts = (entry['ts'] ?? '').toString();
                        final level = (entry['level'] ?? 'INFO').toString();
                        final message = (entry['message'] ?? '').toString();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: SelectableText.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 13,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text: '[$ts] ',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                TextSpan(
                                  text: '${level.padRight(5)}: ',
                                  style: TextStyle(
                                    color: _getLogLevelColor(level),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: message,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
