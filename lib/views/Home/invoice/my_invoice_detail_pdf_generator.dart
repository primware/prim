import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<pw.Document> generateOrderSummaryPdf(Map<String, dynamic> order) async {
  final pdf = pw.Document();
  final lines = order['C_OrderLine'] as List<dynamic>;

  pdf.addPage(pw.MultiPage(
    build: (context) => [
      pw.Header(
          level: 0,
          child: pw.Text('Resumen de la Orden #${order['DocumentNo']}')),
      pw.Text("Cliente: ${order['bpartner']['name']}"),
      pw.Text("Fecha: ${order['DateOrdered']}"),
      pw.SizedBox(height: 10),
      pw.Text("Productos:"),
      pw.Table.fromTextArray(
        headers: [
          'Producto',
          'Cantidad',
          'Precio',
          'Impuesto',
          'Subtotal',
          'Total'
        ],
        data: lines.map((line) {
          final name = line['M_Product_ID']['identifier']
              .toString()
              .split('_')
              .skip(1)
              .join(' ');
          final qty = line['QtyOrdered'];
          final price = line['PriceActual'];
          final rate = line['C_Tax_ID']['Rate'];
          final taxName = line['C_Tax_ID']['Name'];
          final net = line['LineNetAmt'];
          final tax = (net * rate / 100);
          final total = net + tax;

          return [
            name,
            qty.toString(),
            "\$${price.toStringAsFixed(2)}",
            "$taxName ($rate%)",
            "\$${net.toStringAsFixed(2)}",
            "\$${total.toStringAsFixed(2)}",
          ];
        }).toList(),
      ),
      pw.SizedBox(height: 20),
      pw.Text("Total bruto: \$${order['TotalLines']}"),
      pw.Text("Total final: \$${order['GrandTotal']}"),
    ],
  ));

  return pdf;
}
