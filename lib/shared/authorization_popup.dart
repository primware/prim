// // ignore_for_file: use_build_context_synchronously

// import 'package:flutter/material.dart';
// import '../../theme/colors.dart';
// import '../../theme/fonts.dart';

// import '../shared/button.widget.dart';
// import '../views/Auth/auth_funtions.dart';
// import 'textfield.widget.dart';

// class AuthorizationPopup extends StatefulWidget {
//   const AuthorizationPopup({super.key});

//   @override
//   State<AuthorizationPopup> createState() => _AuthorizationPopupState();
// }

// class _AuthorizationPopupState extends State<AuthorizationPopup> {
//   final TextEditingController usuarioController = TextEditingController();
//   final TextEditingController claveController = TextEditingController();
//   bool isLoading = false;

//   Future<void> _funcionLogin(String usuario, String clave) async {
//     setState(() {
//       isLoading = true;
//     });

//     bool login = await superAuth(usuario, clave, context);
//     if (login) {
//       Navigator.pop(context, true);
//     } else {
//       Navigator.pop(context, false);
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       child: Container(
//         width: 500,
//         padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
//         decoration: BoxDecoration(
//           color: ColorTheme.textDark,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Text(
//                 'Autorización Requerida',
//                 style: FontsTheme.h2(),
//               ),
//             ),
//             const SizedBox(height: 24),
//             TextfieldTheme(
//               icono: Icons.mail_outline,
//               texto: 'Usuario',
//               inputType: TextInputType.emailAddress,
//               controlador: usuarioController,
//             ),
//             const SizedBox(height: 8),
//             TextfieldTheme(
//               icono: Icons.lock_outline,
//               texto: 'Contraseña',
//               obscure: true,
//               mostrarSuIcon: true,
//               controlador: claveController,
//               onSubmitted: (p0) async {
//                 await _funcionLogin(
//                   usuarioController.text.trim(),
//                   claveController.text.trim(),
//                 );
//               },
//             ),
//             const SizedBox(height: 20),
//             Container(
//               child: isLoading
//                   ? ButtonLoading(
//                       fullWidth: true,
//                       bgcolor: ColorTheme.p700,
//                       textcolor: ColorTheme.white,
//                     )
//                   : ButtonPrimary(
//                       texto: 'Autorizar',
//                       fullWidth: true,
//                       bgcolor: ColorTheme.accent,
//                       textcolor: ColorTheme.white,
//                       onPressed: () async {
//                         await _funcionLogin(
//                           usuarioController.text.trim(),
//                           claveController.text.trim(),
//                         );
//                       },
//                     ),
//             ),
//             const SizedBox(height: 8),
//             ButtonSecondary(
//               onPressed: () => Navigator.pop(context, false),
//               textcolor: ColorTheme.error,
//               bgcolor: ColorTheme.white,
//               borderColor: ColorTheme.error,
//               fullWidth: true,
//               texto: 'Cancelar',
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
