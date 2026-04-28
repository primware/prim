import 'package:flutter/material.dart';
import 'change_password_view.dart';
import 'org_settings_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: const SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  // --- TARJETA DE CAMBIO DE CONTRASEÑA ---
                  ChangePasswordCard(),

                  SizedBox(height: 24),

                  // --- TARJETA DE ORGANIZACIÓN ---
                  OrgSettingsCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
