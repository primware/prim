import 'package:pdf/widgets.dart' as pw;

pw.Widget documentNumberBarcode(String documentNumber, {required bool isPOS}) {
  final value = documentNumber.trim();
  if (value.isEmpty) return pw.SizedBox();

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.SizedBox(height: isPOS ? 12 : 18),
      pw.Center(
        child: pw.BarcodeWidget(
          data: value,
          barcode: pw.Barcode.code128(),
          width: isPOS ? 150 : 240,
          height: isPOS ? 48 : 64,
          drawText: true,
          textPadding: isPOS ? 2 : 4,
          textStyle: pw.TextStyle(fontSize: isPOS ? 8 : 10),
        ),
      ),
      pw.SizedBox(height: isPOS ? 10 : 14),
    ],
  );
}

