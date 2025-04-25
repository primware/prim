// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:panafoto/API/funtions.api.dart';
// import 'package:panafoto/API/token.api.dart';
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../API/endpoint.api.dart';
// import '../API/user.api.dart';
// import '../services/auth_service.dart';
// import '../theme/colors.dart';
// import '../theme/fonts.dart';
// import 'custom_flat_button.dart';
// import 'logo.dart';

// class CustomAppMenu extends StatelessWidget {
//   final bool showButton;

//   const CustomAppMenu({super.key, this.showButton = true});

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (_, constraints) => (constraints.maxWidth > 750)
//           ? _TableDesktopMenu(
//               showButton: showButton,
//             )
//           : _MobileMenu(),
//     );
//   }
// }

// final String? _label = Base.envProd ? null : 'test-site';

// class _TableDesktopMenu extends StatelessWidget {
//   final bool showButton;

//   const _TableDesktopMenu({required this.showButton});

//   @override
//   Widget build(BuildContext context) {
//     final authService = Provider.of<AuthService>(context);

//     return Container(
//       decoration: BoxDecoration(
//         color: ColorTheme.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 2,
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       width: double.maxFinite,
//       child: Center(
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//           width: Base.maxWithApp,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               MouseRegion(
//                 cursor: SystemMouseCursors.click,
//                 child: GestureDetector(
//                   onTap: () {
//                     context.go('/');
//                   },
//                   child: Logo(),
//                 ),
//               ),
//               if (_label != null) ...[
//                 const SizedBox(
//                   width: 12,
//                 ),
//                 Text(
//                   _label!,
//                   style: FontsTheme.h5Bold(color: ColorTheme.atention),
//                 ),
//               ],
//               const Spacer(),
//               if (showButton) ...[
//                 CustomFlatButton(
//                   text: 'Inicio',
//                   fontcolor: Colors.black,
//                   backgroundcolor: Colors.transparent,
//                   onPressed: () {
//                     context.go('/');
//                   },
//                 ),
//                 CustomFlatButton(
//                   text: 'FAQ',
//                   fontcolor: Colors.black,
//                   backgroundcolor: Colors.transparent,
//                   onPressed: () async {
//                     final String url = 'https://panafoto.com/compra-y-gana';
//                     if (await canLaunch(url)) {
//                       await launch(url,
//                           forceSafariVC: false, forceWebView: false);
//                     } else {
//                       throw 'No se puede abrir el URL: $url';
//                     }
//                   },
//                 ),
//                 CustomFlatButton(
//                   text: authService.isLogin ? 'Panel' : 'Acceder',
//                   fontcolor: ColorTheme.white,
//                   backgroundcolor: ColorTheme.primary,
//                   onPressed: () {
//                     goDashboard(context);
//                   },
//                 ),
//               ],
//               if (authService.isLogin) ...[
//                 const SizedBox(width: 24),
//                 InkWell(
//                   onTap: () {
//                     goDashboard(context);
//                   },
//                   child: CircleAvatar(
//                     radius: 20,
//                     backgroundColor: ColorTheme.p100,
//                     backgroundImage: UserData.imageBytes != null
//                         ? MemoryImage(UserData.imageBytes!)
//                         : null,
//                     child: UserData.imageBytes == null
//                         ? const Icon(
//                             Icons.people_alt_outlined,
//                             color: ColorTheme.primary,
//                             size: 20,
//                           )
//                         : null,
//                   ),
//                 ),
//               ]
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// void goDashboard(BuildContext context) {
//   if (UserData.rolName == 'Cliente') {
//     GoRouter.of(context).go('/dashboard');
//   } else if (UserData.rolName == 'Operador') {
//     GoRouter.of(context).go('/dashboard-operator');
//   } else if (UserData.rolName == 'Administrador') {
//     GoRouter.of(context).go('/dashboard-admin');
//   } else {
//     GoRouter.of(context).go('/login');
//   }
//   limpiarFormulario();
// }

// class _MobileMenu extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final authService = Provider.of<AuthService>(context);
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       decoration: BoxDecoration(
//         color: ColorTheme.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 2,
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Builder(
//             builder: (context) => IconButton(
//               icon: const Icon(Icons.menu),
//               color: ColorTheme.primary,
//               onPressed: () {
//                 Scaffold.of(context).openDrawer();
//               },
//             ),
//           ),
//           MouseRegion(
//             cursor: SystemMouseCursors.click,
//             child: GestureDetector(
//               onTap: () {
//                 context.go('/');
//               },
//               child: Logo(
//                 width: 150,
//               ),
//             ),
//           ),
//           if (authService.isLogin)
//             Padding(
//               padding: const EdgeInsets.only(right: 12),
//               child: InkWell(
//                 onTap: () {
//                   goDashboard(context);
//                 },
//                 child: CircleAvatar(
//                   radius: 20,
//                   backgroundColor: ColorTheme.p100,
//                   backgroundImage: UserData.imageBytes != null
//                       ? MemoryImage(UserData.imageBytes!)
//                       : null,
//                   child: UserData.imageBytes == null
//                       ? const Icon(
//                           Icons.people_alt_outlined,
//                           color: ColorTheme.primary,
//                           size: 20,
//                         )
//                       : null,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class MenuDrawer extends StatelessWidget {
//   MenuDrawer({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           const SizedBox(height: 24),
//           if (_label != null)
//             ListTile(
//               textColor: ColorTheme.atention,
//               title: Text(_label!),
//               onTap: () {
//                 null;
//               },
//             ),
//           ListTile(
//             iconColor: ColorTheme.primary,
//             textColor: ColorTheme.text,
//             leading: const Icon(Icons.home_outlined),
//             title: const Text('Inicio'),
//             onTap: () {
//               GoRouter.of(context).go('/');
//             },
//           ),
//           ListTile(
//             iconColor: ColorTheme.primary,
//             textColor: ColorTheme.text,
//             leading: const Icon(Icons.question_answer_outlined),
//             title: const Text('FAQ'),
//             onTap: () async {
//               final String url = 'https://panafoto.com/compra-y-gana';
//               if (await canLaunch(url)) {
//                 await launch(url, forceSafariVC: false, forceWebView: false);
//               } else {
//                 throw 'No se puede abrir el URL: $url';
//               }
//             },
//           ),
//           ListTile(
//             tileColor: ColorTheme.primary,
//             iconColor: ColorTheme.white,
//             textColor: ColorTheme.white,
//             leading: Icon(Token.auth != null ? Icons.person : Icons.login),
//             title: Text(
//               Token.auth != null ? 'Panel' : 'Acceder',
//             ),
//             onTap: () {
//               if (UserData.rolName == 'Cliente') {
//                 context.go('/dashboard');
//               } else if (UserData.rolName == 'Operador') {
//                 context.go('/dashboard-operator');
//               } else if (UserData.rolName == 'Administrador') {
//                 context.go('/dashboard-admin');
//               } else {
//                 context.go('/login');
//               }
//               limpiarFormulario();
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
