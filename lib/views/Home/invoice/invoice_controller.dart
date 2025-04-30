import 'package:flutter/material.dart';

TextEditingController clienteController = TextEditingController();
TextEditingController qtyProductController = TextEditingController();
TextEditingController productController = TextEditingController();
TextEditingController taxController = TextEditingController();

void clearInvoiceFields() {
  clienteController.clear();
  qtyProductController.clear();
  productController.clear();
  taxController.clear();
}
