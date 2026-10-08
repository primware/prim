import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:primware/localization/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:primware/API/fe.api.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/API/endpoint.dart';
import 'package:primware/views/Home/order/my_order_print_generator.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final localization = FlutterLocalization.instance;
  await localization.ensureInitialized();
  localization.init(mapLocales: [const MapLocale('es', AppLocale.es), const MapLocale('en', AppLocale.en)], initLanguageCode: 'es');
  Future<BuildContext> localizedContext(WidgetTester tester, String language) async {
    localization.translate(language);
    late BuildContext result;
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        supportedLocales: localization.supportedLocales,
        localizationsDelegates: localization.localizationsDelegates,
        home: Builder(
          builder: (context) {
            result = context;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return result;
  }

  setUp(() {
    FESession.reset();
    Token.auth = 'Bearer test';
    Token.organitation = 11;
    Base.baseURL = 'https://example.invalid';
  });
  test('specific organization beats global; lowest ID wins; other org excluded', () {
    final records = [
      {
        'id': 1,
        'AD_Org_ID': {'id': 0},
      },
      {'id': 9, 'AD_Org_ID': 11},
      {'id': 4, 'AD_Org_ID': 11},
      {'id': 2, 'AD_Org_ID': 12},
    ];
    expect(selectFEConfig(records, 11)?['id'], 4);
    expect(selectFEConfig(records, 99)?['id'], 1);
    expect(selectFEConfig([], 11), null);
  });
  test('loads legal data without requesting secrets; reset clears session', () async {
    final client = MockClient((request) async {
      expect(request.url.query, isNot(contains('API_Key')));
      return http.Response(
        jsonEncode({
          'records': request.url.path.endsWith('FE_PAC_Config')
              ? [
                  {
                    'id': 3,
                    'AD_Org_ID': 0,
                    'FE_PAC_ID': {'id': 7},
                  },
                ]
              : [
                  {'FE_LegalName': 'PAC', 'TaxID': '123', 'FE_ResolutionDate': '2021-10-12T00:00:00'},
                ],
        }),
        200,
      );
    });
    await loadFESession(client: client);
    expect(FESession.hasFEConfig, true);
    expect(FESession.legalName, 'PAC');
    FESession.reset();
    expect(FESession.hasFEConfig, false);
    expect(FESession.legalName, null);
  });
  test('API error does not enable FE; missing config is safe', () async {
    await loadFESession(client: MockClient((_) async => http.Response('', 403)));
    expect(FESession.hasFEConfig, false);
    await loadFESession(client: MockClient((_) async => http.Response('{"records":[]}', 200)));
    expect(FESession.hasFEConfig, false);
  });
  test('CUFE uses response first and invoice as fallback', () {
    expect(
      electronicInvoiceCUFE({
        'cufe': 'LOG-CUFE',
        'invoice': {'FE_FiscalInvoiceNumber': 'INVOICE-CUFE'},
      }),
      'LOG-CUFE',
    );
    expect(
      electronicInvoiceCUFE({
        'cufe': ' ',
        'invoice': {'FE_FiscalInvoiceNumber': 'INVOICE-CUFE'},
      }),
      'INVOICE-CUFE',
    );
    const originalCUFE = 'FE0120000155648137-2-2017-0300002026092500000008830010117512139221';
    expect(electronicInvoiceCUFE({'cufe': originalCUFE}), originalCUFE);
    expect(electronicInvoiceCUFE({}), '');
  });
  test('URL and session configuration both required', () {
    expect(hasPrintableFE({'url': 'https://example.invalid/qr'}), false);
    FESession.hasFEConfig = true;
    expect(hasPrintableFE(null), false);
    expect(hasPrintableFE({'url': '  '}), false);
    expect(hasPrintableFE({'url': 'https://example.invalid/qr'}), true);
  });
  testWidgets('partial PAC omits nulls; bilingual date stays dd/MM/yyyy', (tester) async {
    final context = await localizedContext(tester, 'en');
    FESession.legalName = 'PAC';
    FESession.resolutionDate = DateTime(2021, 10, 12);
    final footer = buildPACFooter(context);
    expect(footer.length, 2);
    expect(footer.first, contains('12/10/2021'));
    expect(footer.join(), isNot(contains('null')));
    expect(footer.first, isNot(contains('Resolución No.')));
  });
  testWidgets('generate Spanish and English POS PDFs with long PAC and without FE', (tester) async {
    FESession.hasFEConfig = true;
    FESession.legalName = 'Electronic Business Intelligence Proveedor de Autorización Calificado';
    FESession.taxId = '155709723-2-2021';
    FESession.resolution = '201-9721';
    FESession.resolutionDate = DateTime(2021, 10, 12);
    final order = {
      'DocumentNo': 'ORDER-001',
      'GrandTotal': 10.7,
      'bpartner': {'name': 'Cliente de prueba'},
      'C_OrderLine': [
        {
          'M_Product_ID': {'identifier': 'Producto de prueba'},
          'QtyOrdered': 1,
          'PriceActual': 10,
          'LineNetAmt': 10,
          'C_Tax_ID': {'Name': 'ITBMS', 'Rate': 7},
        },
      ],
    };
    final info = {
      'url': 'https://dgi-fep.mef.gob.pa/Consultas/FacturasPorQR?chFE=TEST&jwt=test',
      'cufe': '0123456789ABCDEF' * 4,
      'protocolo': '123456',
      'invoice': {'FE_numeroDocumentoFiscal': '000000001', 'FE_puntoFacturacionFiscal': '001', 'DateInvoiced': '2026-10-07', 'C_InvoiceLine': []},
    };
    for (final english in [false, true]) {
      final context = await localizedContext(tester, english ? 'en' : 'es');
      final bytes = await generatePOSTicket(order, context: context, electronicInvoiceInfo: info);
      expect(bytes.length, greaterThan(1000));
      await tester.runAsync(() => File('/private/tmp/fe-ticket-${english ? 'en' : 'es'}.pdf').writeAsBytes(bytes));
    }
    final bytes = await generatePOSTicket(order, context: await localizedContext(tester, 'es'), electronicInvoiceInfo: {'url': ''});
    await tester.runAsync(() => File('/private/tmp/fe-ticket-none.pdf').writeAsBytes(bytes));
  });
}
