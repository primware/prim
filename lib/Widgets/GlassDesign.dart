import 'package:flutter/material.dart';
import 'dart:ui';

class LiquidBackground extends StatelessWidget {
  final Widget child;
  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final secondary = Theme.of(context).colorScheme.secondary;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: bg),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [primary.withOpacity(isDark ? 0.35 : 0.15), Colors.transparent], stops: const [0.1, 1.0]),
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
          child,
        ],
      ),
    );
  }
}

// 2. CONTENEDOR GLASS
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double borderOpacity;
  final bool hasShadow;
  final BlurStyle shadowBlurStyle;

  const GlassContainer({super.key, required this.child, this.width, this.height, this.blur = 12.0, this.padding, this.borderRadius, this.borderOpacity = 0.2, this.hasShadow = true, this.shadowBlurStyle = BlurStyle.outer});

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(24);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores adaptativos para modo claro/oscuro
    final glassColor = isDark ? Colors.black : Colors.white;
    final glassOpacityStart = isDark ? 0.15 : 0.1;
    final glassOpacityEnd = isDark ? 0.05 : 0.1;
    final borderColor = isDark ? Colors.white30 : Colors.white;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.12),
                  blurRadius: 30, // Desenfoque de la sombra
                  spreadRadius: 2,
                  offset: const Offset(0, 10), // Dirección hacia abajo
                  blurStyle: shadowBlurStyle, // Usa el estilo de desenfoque pasado por parámetro
                ),
              ]
            : null,
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

// 3. FONDO OSCURO
class DeepLiquidBackground extends StatelessWidget {
  final Widget child;
  const DeepLiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final secondary = Theme.of(context).colorScheme.secondary;
    const bg = Color(0xFF1A1A2E);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(color: bg),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [primary.withOpacity(0.6), Colors.transparent], stops: const [0.1, 1.0]),
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
                gradient: RadialGradient(colors: [secondary.withOpacity(0.5), Colors.transparent], stops: const [0.1, 1.0]),
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
                gradient: RadialGradient(colors: [primary.withOpacity(0.4), Colors.transparent], stops: const [0.1, 1.0]),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class LightAccentBackground extends StatelessWidget {
  final Widget? child;
  const LightAccentBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final secondary = Theme.of(context).colorScheme.secondary;
    final bg = Theme.of(context).colorScheme.surface;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: bg),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [primary.withOpacity(0.99), Colors.transparent], stops: const [0.1, 1.0]),
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
                gradient: RadialGradient(colors: [secondary.withOpacity(0.20), Colors.transparent], stops: const [0.1, 1.0]),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.8,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [primary.withOpacity(0.35), Colors.transparent], stops: const [0.1, 1.0]),
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

//INTERRUPTOR DE CRISTAL
class GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlassSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? primary.withOpacity(0.3) : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          border: Border.all(color: value ? primary.withOpacity(0.6) : (isDark ? Colors.white30 : Colors.black12), width: 1.5),
          boxShadow: [if (value) BoxShadow(color: primary.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              top: 2,
              bottom: 2,
              // Animación de la canica de izquierda a derecha
              left: value ? 26 : 2,
              right: value ? 2 : 26,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // El desenfoque del cristal de la canica
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // La canica: morado sólido con brillo si está activo, blanca si no
                      color: value ? primary.withOpacity(0.8) : (isDark ? Colors.white70 : Colors.white),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5), // Brillo en el borde
                        width: 1,
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//BOTÓN DE SELECCIÓN DE MENÚ DE CRISTAL
class GlassMenuButton extends StatelessWidget {
  final String label;
  final String currentValue;
  final IconData icon;
  final VoidCallback onTap;

  const GlassMenuButton({super.key, required this.label, required this.currentValue, this.icon = Icons.category_outlined, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55, // Armonía visual con el buscador
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: primary.withOpacity(0.15), shape: BoxShape.circle),
                        child: Icon(icon, color: primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // El texto de la selección
                      Text(
                        currentValue.isEmpty ? label : currentValue,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: currentValue.isEmpty ? FontWeight.w500 : FontWeight.bold, color: currentValue.isEmpty ? Colors.grey.shade600 : (isDark ? Colors.white : Colors.black87)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // Flecha de despliegue
                  Icon(Icons.expand_more, color: isDark ? Colors.white60 : Colors.grey.shade600, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
