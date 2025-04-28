// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../../../main.dart';
import '../../../shared/button.widget.dart';
import '../../../theme/colors.dart';
import '../../../theme/fonts.dart';
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: 800),
                padding:
                    const EdgeInsets.symmetric(vertical: 76, horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${UserData.name}',
                          style: MediaQuery.of(context).size.width <= 750
                              ? FontsTheme.h4Bold()
                              : FontsTheme.h3Bold(),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: ColorTheme.aL100,
                          backgroundImage: UserData.imageBytes != null
                              ? MemoryImage(UserData.imageBytes!)
                              : null,
                          child: UserData.imageBytes == null
                              ? const Icon(
                                  Icons.people_alt_outlined,
                                  color: ColorTheme.accentLight,
                                  size: 20,
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildDashboardCard(
                          context,
                          'Modificar perfil',
                          Icons.person_outline,
                          () {
                            null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ButtonSecondary(
                      texto: 'Cerrar sesión',
                      icono: Icons.logout_outlined,
                      bgcolor: ColorTheme.textDark,
                      borderColor: ColorTheme.accentLight,
                      textcolor: ColorTheme.accentLight,
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
                    SizedBox(height: 24),
                    ButtonSecondary(
                      texto: 'Cambiar tema',
                      icono: Icons.brightness_6,
                      bgcolor: ColorTheme.textDark,
                      borderColor: ColorTheme.accentLight,
                      textcolor: ColorTheme.accentLight,
                      onPressed: () {
                        ThemeManager.themeNotifier.toggleTheme();
                      },
                    ),
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
          color: ColorTheme.accentLight,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: ColorTheme.textDark,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: FontsTheme.h5Bold(color: ColorTheme.textDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
