import 'package:flutter/material.dart';
import 'dart:ui'; // Necesario para ImageFilter

// 1. FONDO LÍQUIDO PREMIUM (Adaptado al Theme de Prim)
class LiquidBackground extends StatelessWidget {
  final Widget child;
  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Extraemos los colores dinámicos de Prim
    final primary = Theme.of(context).primaryColor;
    final secondary = Theme.of(context).colorScheme.secondary;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bg, // Fondo base dinámico (blanco en claro, gris oscuro en oscuro)
      ),
      child: Stack(
        children: [
          /// --- ORBES DINÁMICOS CON COLORES DE PRIM ---
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withOpacity(isDark ? 0.35 : 0.15), // Más visible en modo oscuro
                    Colors.transparent,
                  ],
                  stops: const [0.1, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [secondary.withOpacity(isDark ? 0.35 : 0.15), Colors.transparent], stops: const [0.1, 1.0]),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [primary.withOpacity(isDark ? 0.2 : 0.08), Colors.transparent], stops: const [0.1, 1.0]),
              ),
            ),
          ),

          // Contenido principal
          child,
        ],
      ),
    );
  }
}

// 2. CONTENEDOR GLASS ULTRA PREMIUM (Estilo iOS / Prim)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double borderOpacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blur = 12.0, // Un poco más de blur para mayor elegancia
    this.padding,
    this.borderRadius,
    this.borderOpacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(24);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores adaptativos para modo claro/oscuro
    final glassColor = isDark ? Colors.black : Colors.white;
    final glassOpacityStart = isDark ? 0.4 : 0.5;
    final glassOpacityEnd = isDark ? 0.1 : 0.2;
    final borderColor = isDark ? Colors.white30 : Colors.white;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08), // Sombra más dura en oscuro
            blurRadius: 24,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: br,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [glassColor.withOpacity(glassOpacityStart), glassColor.withOpacity(glassOpacityEnd)], stops: const [0.0, 1.0]),
              border: Border.all(color: borderColor.withOpacity(borderOpacity), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
