import 'package:flutter/material.dart';
import 'package:primware/API/endpoint.api.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/API/user.api.dart';

import '../../../shared/custom_spacer.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SelectableText('Settings'),
      ),
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
                SelectableText('Token - tokenRegister: ${Token.tokenRegister}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
