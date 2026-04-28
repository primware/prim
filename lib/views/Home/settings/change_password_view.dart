import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../API/endpoint.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_container.dart';
import '../../../shared/custom_textfield.dart';
import '../../../shared/toast_message.dart';
import '../../Auth/login_view.dart';

class ChangePasswordCard extends StatefulWidget {
  const ChangePasswordCard({super.key});

  @override
  State<ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<ChangePasswordCard> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoadingPassword = false;

  bool hasMinLength = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    newPasswordController.addListener(_validatePassword);
    confirmPasswordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    if (newPasswordController.text.length > 8) {
      newPasswordController.text = newPasswordController.text.substring(0, 8);
      newPasswordController.selection = TextSelection.fromPosition(TextPosition(offset: 8));
    }
    if (confirmPasswordController.text.length > 8) {
      confirmPasswordController.text = confirmPasswordController.text.substring(0, 8);
      confirmPasswordController.selection = TextSelection.fromPosition(TextPosition(offset: 8));
    }

    final pass = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    setState(() {
      hasMinLength = pass.length == 8;
      hasUppercase = pass.contains(RegExp(r'[A-Z]'));
      hasLowercase = pass.contains(RegExp(r'[a-z]'));
      passwordsMatch = pass == confirm && pass.isNotEmpty;
    });
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    int score = 0;
    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    return score;
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey.shade300;
    }
  }

  String get _strengthText {
    if (newPasswordController.text.isEmpty) return 'Seguridad';
    switch (_passwordStrength) {
      case 0:
      case 1:
        return 'Débil';
      case 2:
        return 'Medio';
      case 3:
        return 'Fuerte';
      default:
        return '';
    }
  }

  void _performLogout() {
    UserData.uu = null;
    UserData.name = null;
    Token.auth = null;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginPage()), (Route<dynamic> route) => false);
  }

  Future<void> _confirmUpdate() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('¿Actualizar clave?'),
          content: const Text('Se cerrará la sesión actual y tendrás que ingresar nuevamente.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sí, actualizar')),
          ],
        );
      },
    );
    if (confirm == true) _executeServerUpdate();
  }

  Future<void> _executeServerUpdate() async {
    setState(() => isLoadingPassword = true);
    try {
      // JSON plano como descubrimos que iDempiere prefiere
      final Map<String, dynamic> body = {"AD_User_UU": UserData.uu, "Password": newPasswordController.text.trim()};

      final response = await post(Uri.parse(Processes.changePassword), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!}, body: jsonEncode(body));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['isError'] == true) {
          ToastMessage.show(context: context, message: responseData['summary'] ?? 'Error', type: ToastType.failure);
        } else {
          ToastMessage.show(context: context, message: 'Contraseña actualizada.', type: ToastType.success);
          await Future.delayed(const Duration(milliseconds: 1500));
          _performLogout();
        }
      } else {
        ToastMessage.show(context: context, message: 'Error del servidor', type: ToastType.failure);
      }
    } catch (e) {
      ToastMessage.show(context: context, message: 'Error de conexión', type: ToastType.failure);
    } finally {
      if (mounted) setState(() => isLoadingPassword = false);
    }
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(isMet ? Icons.check_circle : Icons.radio_button_unchecked, color: isMet ? Colors.green : Colors.grey.shade400, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: isMet ? Colors.green.shade700 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isButtonEnabled = _passwordStrength == 3 && passwordsMatch;

    return CustomContainer(
      maxWidthContainer: 500,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            Icon(Icons.shield_outlined, color: Theme.of(context).primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              'Seguridad de la\nCuenta',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 32),
            TextfieldTheme(controlador: newPasswordController, texto: 'Nueva Contraseña', icono: Icons.lock_outline, obscure: true, showSubIcon: true),
            const SizedBox(height: 16),
            TextfieldTheme(controlador: confirmPasswordController, texto: 'Confirmar Contraseña', icono: Icons.lock_outline, obscure: true, showSubIcon: true),
            const SizedBox(height: 24),
            LinearProgressIndicator(value: newPasswordController.text.isEmpty ? 0 : _passwordStrength / 3, color: _strengthColor),
            const SizedBox(height: 24),
            _buildRequirementRow('Exactamente 8 caracteres', hasMinLength),
            _buildRequirementRow('Al menos una letra Mayúscula', hasUppercase),
            _buildRequirementRow('Al menos una letra minúscula', hasLowercase),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: isLoadingPassword ? const ButtonLoading() : ButtonPrimary(texto: 'Actualizar', onPressed: isButtonEnabled ? _confirmUpdate : null),
            ),
          ],
        ),
      ),
    );
  }
}
