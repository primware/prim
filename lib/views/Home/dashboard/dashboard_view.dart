// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_spacer.dart';
import '../../Auth/login_view.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool ismobile = MediaQuery.of(context).size.width <= 750;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: ismobile ? MenuDrawer() : null,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              CustomAppMenu(),
              Container(
                constraints: BoxConstraints(maxWidth: 800),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${UserData.name} - ${UserData.clientName}',
                      style: Theme.of(context).textTheme.headlineLarge,
                      overflow: TextOverflow.visible,
                    ),
                    SizedBox(height: CustomSpacer.medium),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: ismobile ? 2 : 4,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: ismobile ? 6 : 16,
                      mainAxisSpacing: ismobile ? 6 : 16,
                      children: [
                        _buildDashboardCard(
                          context,
                          'Facturar',
                          Icons.attach_money_rounded,
                          () {
                            null;
                          },
                        ),
                      ],
                    ),
                    if (!ismobile) ...[
                      SizedBox(
                          height: CustomSpacer.xlarge + CustomSpacer.xlarge),
                      ButtonSecondary(
                        texto: 'Cerrar sesión',
                        icono: Icons.logout_outlined,
                        onPressed: () {
                          Token.auth = null;
                          usuarioController.clear();
                          claveController.clear();

                          UserData.rolName = null;
                          UserData.imageBytes = null;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: Theme.of(context).primaryColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.surface,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
