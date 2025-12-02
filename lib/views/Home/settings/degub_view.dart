import 'package:flutter/material.dart';
import 'package:primware/API/endpoint.api.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/API/user.api.dart';

import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/footer.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});
  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MenuDrawer(),
      appBar: AppBar(
        title: Text('Settings'),
      ),
      bottomNavigationBar: CustomFooter(),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: CustomSpacer.large),
                Text(
                  'This is a debug page. It is not meant to be used in production.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: CustomSpacer.large),
                SelectableText('Es producción: ${Base.prod}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('URL: ${Base.baseURL}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('POS - priceListID: ${POS.priceListID}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText(
                    'POS - priceListVersionID: ${POS.priceListVersionID}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('POS - docTypeID: ${POS.docTypeID}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText(
                    'POS - templatePartnerID: ${POS.templatePartnerID}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('POS - isPOS: ${POS.isPOS}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('User - id: ${UserData.id}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('User - rolName: ${UserData.rolName}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('User - clientName: ${UserData.clientName}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('User - name: ${UserData.name}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('User - email: ${UserData.email}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('Token - client: ${Token.client}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('Token - rol: ${Token.rol}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('Token - organitation: ${Token.organitation}',
                    style: Theme.of(context).textTheme.bodyMedium),
                SelectableText('Token - warehouseID: ${Token.warehouseID}',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: CustomSpacer.large),
                Row(
                  children: [
                    Text(
                      'Console Log (memoria)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: CustomSpacer.small),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          CurrentLogMessage.log.clear();
                        });
                      },
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List<Map<String, dynamic>>.from(
                  CurrentLogMessage.log.reversed,
                ).map((entry) {
                  final ts = (entry['ts'] ?? '').toString();
                  final level = (entry['level'] ?? '').toString();
                  final tag = (entry['tag'] ?? '').toString();
                  final message = (entry['message'] ?? '').toString();
                  final subtitle = [ts, level, if (tag.isNotEmpty) tag]
                      .where((e) => e.isNotEmpty)
                      .join(' • ');
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      dense: true,
                      title: SelectableText(message),
                      subtitle: Text(subtitle),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
