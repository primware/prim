import 'package:flutter/material.dart';

TextEditingController searchController = TextEditingController();
TextEditingController idController = TextEditingController();
TextEditingController taxIdController = TextEditingController();
TextEditingController nombreController = TextEditingController();
TextEditingController apellidoController = TextEditingController();
TextEditingController representanteController = TextEditingController();
TextEditingController correoController = TextEditingController();
TextEditingController telefonoController = TextEditingController();
TextEditingController movilController = TextEditingController();
TextEditingController cumpleanosController = TextEditingController();
TextEditingController direccionController = TextEditingController();
TextEditingController comentariosController = TextEditingController();
TextEditingController currentUserIDController = TextEditingController();
TextEditingController currentPartnerIDController = TextEditingController();

void clearCustomerControllers() {
  idController.clear();
  taxIdController.clear();
  nombreController.clear();
  apellidoController.clear();
  representanteController.clear();
  correoController.clear();
  telefonoController.clear();
  movilController.clear();
  cumpleanosController.clear();
  direccionController.clear();
  comentariosController.clear();
  currentPartnerIDController.clear();
  currentUserIDController.clear();
}
