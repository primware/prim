import 'package:flutter/material.dart';

TextEditingController nameController = TextEditingController();
TextEditingController taxController = TextEditingController();
TextEditingController locationController = TextEditingController();
TextEditingController emailController = TextEditingController();

void clearPartnerFields() {
  nameController.clear();
  locationController.clear();
  taxController.clear();
  emailController.clear();
}
