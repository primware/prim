// lib/shared/theme_switcher_controller.dart
//
// Widget + controlador global para la animación de cambio de tema tipo "circular reveal".
// El efecto: al cambiar el tema, se toma una captura del estado anterior y se muestra
// encima de la pantalla como una "máscara". Luego esa máscara se recorta con un círculo
// que crece desde el punto donde el usuario presionó el botón, revelando el nuevo tema.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:primware/theme/theme.dart';
import 'package:primware/main.dart';

/// Clave global para que [ThemeSwitcherController] pueda capturar la pantalla.
final GlobalKey repaintKey = GlobalKey();

/// Controlador global que dispara la animación de cambio de tema.
class ThemeSwitcherController {
  ThemeSwitcherController._();
  static final ThemeSwitcherController instance = ThemeSwitcherController._();

  _CircularRevealOverlayState? _overlayState;

  void _register(_CircularRevealOverlayState state) {
    _overlayState = state;
  }

  void _unregister(_CircularRevealOverlayState state) {
    if (_overlayState == state) _overlayState = null;
  }

  /// Llama a este método para disparar la animación.
  /// [origin] es la posición global (en coordenadas de pantalla) donde se originará el círculo.
  Future<void> trigger({required Offset origin, bool isReversed = false}) async {
    await _overlayState?.trigger(origin: origin, isReversed: isReversed);
  }
}

/// Envuelve toda la aplicación. Coloca este widget como padre del [MaterialApp].
/// Internamente toma una captura de la pantalla actual antes del cambio de tema
/// y luego reproduce la animación de revelado circular.
class CircularRevealOverlay extends StatefulWidget {
  final Widget child;
  const CircularRevealOverlay({super.key, required this.child});

  @override
  State<CircularRevealOverlay> createState() => _CircularRevealOverlayState();
}

class _CircularRevealOverlayState extends State<CircularRevealOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  ui.Image? _snapshot;
  Offset _origin = Offset.zero;
  bool _isAnimating = false;

  bool _isReversed = false;

  @override
  void initState() {
    super.initState();
    ThemeSwitcherController.instance._register(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _snapshot = null;
          _isAnimating = false;
        });
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    ThemeSwitcherController.instance._unregister(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> trigger({required Offset origin, bool isReversed = false}) async {
    if (_isAnimating) return;

    // 1. Capturamos la pantalla CON el tema actual (antes del cambio).
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final pixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final image = await boundary.toImage(pixelRatio: pixelRatio);

    setState(() {
      _snapshot = image;
      _origin = origin;
      _isReversed = isReversed;
      _isAnimating = true;
    });

    // 2. Damos un frame para que el nuevo tema se pinte debajo.
    await Future.delayed(const Duration(milliseconds: 32));

    // 3. Iniciamos la animación.
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        // Fondo: Si NO está invertido, mostramos la foto vieja intacta al fondo.
        if (_isAnimating && !_isReversed && _snapshot != null)
          RawImage(image: _snapshot, fit: BoxFit.cover),

        // Capa Principal (App en vivo)
        if (_isAnimating && !_isReversed && _snapshot != null)
          // Efecto Normal: La app nueva (abajo) CRECE desde el botón, cubriendo la foto vieja.
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return ClipPath(
                clipper: _CircularRevealClipper(
                  origin: _origin,
                  progress: _animation.value, // Crece 0 -> 1
                ),
                child: child,
              );
            },
            child: RepaintBoundary(
              key: repaintKey,
              child: widget.child,
            ),
          )
        else
          // Efecto Invertido o Sin Animación: La app nueva se muestra normal.
          RepaintBoundary(
            key: repaintKey,
            child: widget.child,
          ),

        // Capa Superior (Solo para Invertido)
        if (_isAnimating && _isReversed && _snapshot != null)
          // Efecto Invertido: La foto vieja (arriba) se ENCOGE hacia el botón.
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return ClipPath(
                clipper: _CircularRevealClipper(
                  origin: _origin,
                  progress: 1.0 - _animation.value, // Encoge 1 -> 0
                ),
                child: RawImage(image: _snapshot, fit: BoxFit.cover),
              );
            },
          ),
      ],
    );
  }
}

/// Un [CustomClipper] que recorta la imagen en un círculo cuyo radio va de
/// [maxRadius * progress] → 0 conforme [progress] baja de 1 a 0.
class _CircularRevealClipper extends CustomClipper<Path> {
  final Offset origin;
  final double progress; // 1.0 = círculo lleno; 0.0 = punto

  const _CircularRevealClipper({required this.origin, required this.progress});

  @override
  Path getClip(Size size) {
    final maxRadius = _calcMaxRadius(size, origin);
    final radius = maxRadius * progress;
    return Path()
      ..addOval(Rect.fromCircle(center: origin, radius: radius));
  }

  static double _calcMaxRadius(Size size, Offset center) {
    final w = size.width;
    final h = size.height;
    // Distancia al vértice más lejano del rectángulo
    final corners = [
      Offset(0, 0),
      Offset(w, 0),
      Offset(0, h),
      Offset(w, h),
    ];
    return corners
        .map((c) => (c - center).distance)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  bool shouldReclip(_CircularRevealClipper old) =>
      old.progress != progress || old.origin != origin;
}

/// Un botón (IconButton) que puedes colocar en cualquier AppBar.
/// Captura su posición global y dispara la animación de cambio de tema.
class ThemeToggleIconButton extends StatefulWidget {
  const ThemeToggleIconButton({super.key});

  @override
  State<ThemeToggleIconButton> createState() => _ThemeToggleIconButtonState();
}

class _ThemeToggleIconButtonState extends State<ThemeToggleIconButton> {
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeData>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, _) {
        final bool isDark = theme.brightness == Brightness.dark;
        return IconButton(
          key: _buttonKey,
          icon: Icon(isDark ? Icons.sunny : Icons.nightlight),
          tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
          onPressed: () async {
            final RenderBox? box =
                _buttonKey.currentContext?.findRenderObject() as RenderBox?;
            final Offset origin = box != null
                ? box.localToGlobal(box.size.center(Offset.zero))
                : const Offset(0, 0);

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isDarkMode', !isDark);

            appThemeNotifier.value =
                isDark ? AppThemes.lightTheme : AppThemes.darkTheme;

            // Si cambiamos a modo oscuro (!isDark porque isDark es el estado VIEJO):
            // isDark == false (actual es claro, vamos a oscuro):
            //   Queremos que la oscuridad cubra todo (la foto clara se ENCOGE). -> isReversed = true.
            // isDark == true (actual es oscuro, vamos a claro):
            //   Queremos que la luz separe (la app clara CRECE). -> isReversed = false.
            final bool goingToDark = !isDark;
            await ThemeSwitcherController.instance.trigger(
              origin: origin,
              isReversed: goingToDark,
            );
          },
        );
      },
    );
  }
}
