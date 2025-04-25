import 'dart:io';
import 'package:flutter/material.dart';
import 'package:primware/views/Auth/login_view.dart';
import 'API/endpoint.api.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MainApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    //!para desactivar el ssl ya que es un autofirmado el API
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Base.title,
      home: const LoginPage(),
    );
  }
}
