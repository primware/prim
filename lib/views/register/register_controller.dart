import 'package:flutter/material.dart';

TextEditingController clientNameController = TextEditingController();
TextEditingController orgValueController = TextEditingController();
TextEditingController orgNameController = TextEditingController();
TextEditingController adminUserNameController = TextEditingController();
TextEditingController adminUserEmailController = TextEditingController();
TextEditingController normalUserNameController = TextEditingController();
TextEditingController normalUserEmailController = TextEditingController();

void clearTextFields() {
  clientNameController.clear();
  orgValueController.clear();
  orgNameController.clear();
  adminUserNameController.clear();
  adminUserEmailController.clear();
  normalUserNameController.clear();
  normalUserEmailController.clear();
}
