import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:primware/theme/theme.dart';
import 'package:primware/shared/custom_textfield.dart';

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
                gradient: RadialGradient(
                  colors: [
                    primary.withOpacity(isDark ? 0.35 : 0.15),
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
                gradient: RadialGradient(
                  colors: [
                    secondary.withOpacity(isDark ? 0.35 : 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 1.0],
                ),
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
                gradient: RadialGradient(
                  colors: [
                    primary.withOpacity(isDark ? 0.2 : 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 1.0],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

//DROPDOWN DE CRISTAL
class GlassDropdownItem<T> {
  final T value;
  final String text;
  final IconData? icon;

  GlassDropdownItem({required this.value, required this.text, this.icon});
}

// CONTENEDOR GLASS (Conectado al Theme)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final double? blur;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? borderOpacity;
  final bool hasShadow;
  final BlurStyle shadowBlurStyle;
  final double shadowBlur;
  final Offset shadowOffset;
  final Color? customBorderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.constraints,
    this.blur,
    this.padding,
    this.borderRadius,
    this.borderOpacity,
    this.hasShadow = true,
    this.shadowBlurStyle = BlurStyle.outer,
    this.shadowBlur = 30.0,
    this.shadowOffset = const Offset(0, 10),
    this.customBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(24);

    final glassTheme = Theme.of(context).extension<GlassTheme>()!;

    return Container(
      width: width,
      height: height,
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: glassTheme.shadowColor,
                  blurRadius: shadowBlur,
                  spreadRadius: 2,
                  offset: shadowOffset,
                  blurStyle: shadowBlurStyle,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur ?? glassTheme.blur,
            sigmaY: blur ?? glassTheme.blur,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: br,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glassTheme.glassColor.withOpacity(glassTheme.opacityStart),
                  glassTheme.glassColor.withOpacity(glassTheme.opacityEnd),
                ],
                stops: const [0.0, 1.0],
              ),
              border: Border.all(
                color: (customBorderColor ?? glassTheme.borderColor)
                    .withOpacity(borderOpacity ?? glassTheme.borderOpacity),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// FONDO OSCURO
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
                gradient: RadialGradient(
                  colors: [primary.withOpacity(0.6), Colors.transparent],
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
                gradient: RadialGradient(
                  colors: [secondary.withOpacity(0.5), Colors.transparent],
                  stops: const [0.1, 1.0],
                ),
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
                gradient: RadialGradient(
                  colors: [primary.withOpacity(0.4), Colors.transparent],
                  stops: const [0.1, 1.0],
                ),
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
                gradient: RadialGradient(
                  colors: [primary.withOpacity(0.99), Colors.transparent],
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
                gradient: RadialGradient(
                  colors: [secondary.withOpacity(0.20), Colors.transparent],
                  stops: const [0.1, 1.0],
                ),
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
                gradient: RadialGradient(
                  colors: [primary.withOpacity(0.35), Colors.transparent],
                  stops: const [0.1, 1.0],
                ),
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// FONDO LIMPIO DE CRISTAL
class CleanGlassBackground extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final BorderRadius? borderRadius;

  const CleanGlassBackground({
    super.key,
    required this.child,
    this.blurSigma = 25.0,
    this.opacity = 0.35,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final br = borderRadius ?? BorderRadius.zero;

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: bg.withOpacity(opacity),
          child: child,
        ),
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
          color: value
              ? primary.withOpacity(0.3)
              : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05)),
          border: Border.all(
            color: value
                ? primary.withOpacity(0.6)
                : (isDark ? Colors.white30 : Colors.black12),
            width: 1.5,
          ),
          boxShadow: [
            if (value)
              BoxShadow(
                color: primary.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
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
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value
                          ? primary.withOpacity(0.8)
                          : (isDark ? Colors.white70 : Colors.white),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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

  const GlassMenuButton({
    super.key,
    required this.label,
    required this.currentValue,
    this.icon = Icons.category_outlined,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark
              ? Colors.black.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.06),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currentValue.isEmpty ? label : currentValue,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: currentValue.isEmpty
                              ? FontWeight.w500
                              : FontWeight.bold,
                          color: currentValue.isEmpty
                              ? Colors.grey.shade600
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Icon(
                    Icons.expand_more,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// MENÚ DESPLEGABLE DE CRISTAL (FLOTANTE, CON BUSCADOR INTELIGENTE Y ANIMACIONES FLUIDAS)
class GlassDropdown<T> extends StatefulWidget {
  final String label;
  final String currentValue;
  final IconData icon;
  final List<GlassDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final Color? textColor;
  final Color? labelColor;

  const GlassDropdown({
    super.key,
    required this.label,
    required this.currentValue,
    required this.items,
    required this.onChanged,
    this.icon = Icons.category_outlined,
    this.textColor,
    this.labelColor,
  });

  @override
  State<GlassDropdown<T>> createState() => _GlassDropdownState<T>();
}

class _GlassDropdownState<T> extends State<GlassDropdown<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 🌟 ANIMACIÓN MÁS RÁPIDA Y LIGERA: 200ms es el estándar premium de UI
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // 🌟 FADE IN: Aparece suavemente
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // 🌟 SCALE IN: Pequeño efecto de "zoom" desde el 95% al 100% (cero lag)
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  Future<void> _closeDropdown() async {
    if (_isOpen) {
      setState(() => _isOpen = false);
      await _animationController.reverse();
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _showDropdown() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = _createOverlayEntry(size);
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _animationController.forward(from: 0.0);
  }

  OverlayEntry _createOverlayEntry(Size size) {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 8.0),
            // 🌟 NUEVAS ANIMACIONES FLUIDAS EN EL OVERLAY
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment
                    .topCenter, // El panel crece desde el botón superior
                child: _GlassDropdownPanel<T>(
                  width: size.width,
                  items: widget.items,
                  onItemSelected: (value) {
                    widget.onChanged(value);
                    _closeDropdown();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GlassContainer(
        padding: EdgeInsets.zero,
        hasShadow: false,
        child: InkWell(
          onTap: _toggleDropdown,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 39),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(widget.icon, color: primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              widget.currentValue.isEmpty
                                  ? widget.label
                                  : widget.currentValue,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: widget.currentValue.isEmpty
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                    color: widget.currentValue.isEmpty
                                        ? (widget.labelColor ?? Colors.grey.shade600)
                                        : (widget.textColor ?? (isDark ? Colors.white : Colors.black87)),
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0.0,
                    duration: const Duration(
                      milliseconds: 200,
                    ), // Sincronizado con la duración principal
                    child: Icon(
                      Icons.expand_more,
                      color: widget.labelColor ?? (isDark ? Colors.white60 : Colors.grey.shade600),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// PANEL FLOTANTE INTERNO (CON BUSCADOR Y SCROLL)
class _GlassDropdownPanel<T> extends StatefulWidget {
  final double width;
  final List<GlassDropdownItem<T>> items;
  final ValueChanged<T> onItemSelected;

  const _GlassDropdownPanel({
    required this.width,
    required this.items,
    required this.onItemSelected,
  });

  @override
  State<_GlassDropdownPanel<T>> createState() => _GlassDropdownPanelState<T>();
}

class _GlassDropdownPanelState<T> extends State<_GlassDropdownPanel<T>> {
  late List<GlassDropdownItem<T>> filteredItems;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
    searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterItems);
    searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredItems = widget.items
          .where((item) => item.text.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    // REGLA INTELIGENTE: Más de 5 items = Activa buscador y limita la altura
    final bool showSearch = widget.items.length > 5;
    final double maxHeight = showSearch
        ? 300.0
        : (widget.items.length * 55.0) + 20.0;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: widget.width,
        child: GlassContainer(
          padding: const EdgeInsets.all(8),
          hasShadow: true,
          shadowBlur:
              40.0, // Sombra profunda para que el panel se despegue mucho del fondo
          shadowOffset: const Offset(0, 15),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSearch) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8.0,
                      left: 4.0,
                      right: 4.0,
                    ),
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: primary.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Divider(
                    color: Colors.white.withOpacity(isDark ? 0.1 : 0.4),
                    height: 1,
                  ),
                  const SizedBox(height: 4),
                ],
                // El scroll se activa automáticamente dentro de Flexible
                Flexible(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return InkWell(
                        onTap: () => widget.onItemSelected(item.value),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              if (item.icon != null) ...[
                                Icon(
                                  item.icon,
                                  size: 20,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Text(
                                  item.text,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// EFECTO DE PRESIÓN PARA BOTONES
class GlassPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const GlassPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<GlassPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

// CAMPO DE TEXTO DE CRISTAL
class GlassTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const GlassTextField({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        borderRadius: BorderRadius.circular(16),
        customBorderColor: _isFocused ? primary : null,
        borderOpacity: _isFocused ? 0.8 : 0.3,
        hasShadow: false,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          cursorColor: primary,
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _isFocused
                  ? primary
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : Colors.black38,
            ),
            prefixIcon: widget.icon != null
                ? Icon(
                    widget.icon,
                    color: _isFocused
                        ? primary
                        : (isDark ? Colors.white70 : Colors.black54),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

class GlassAlertDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final MainAxisAlignment actionsAlignment;

  const GlassAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.actionsAlignment = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16.0),
      elevation: 0,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(24.0),
        hasShadow: true,
        shadowBlur: 20.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              DefaultTextStyle(
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                child: title!,
              ),
              const SizedBox(height: 16),
            ],
            if (content != null) ...[
              Flexible(
                child: SingleChildScrollView(
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyMedium!,
                    child: content!,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (actions != null)
              Row(
                mainAxisAlignment: actionsAlignment,
                children: actions!,
              ),
          ],
        ),
      ),
    );
  }
}

class GlassSearchField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final List<Map<String, dynamic>> options;
  final void Function(Map<String, dynamic>) onItemSelected;
  final void Function(String) onCreate;
  final void Function(String) onChanged;
  final bool showCreateButtonIfNotFound;
  final String createAnchorTerm;
  final Color? fillColor;
  final Color? textColor;
  final Color? labelColor;

  const GlassSearchField({
    super.key,
    required this.label,
    required this.controller,
    required this.options,
    required this.onItemSelected,
    required this.onCreate,
    required this.onChanged,
    this.showCreateButtonIfNotFound = false,
    this.createAnchorTerm = '',
    this.fillColor,
    this.textColor,
    this.labelColor,
  });

  @override
  State<GlassSearchField> createState() => _GlassSearchFieldState();
}

class _GlassSearchFieldState extends State<GlassSearchField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  List<Map<String, dynamic>> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _closeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _closeOverlay();
      });
    }
  }

  void _onTextChanged() {
    final query = widget.controller.text.toLowerCase();
    setState(() {
      _filteredOptions = widget.options.where((option) {
        final name = (option['name'] ?? option['Name'] ?? '').toString().toLowerCase();
        return name.contains(query);
      }).toList();
    });
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _showOverlay() {
    if (_isOpen) return;
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 8.0),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: size.width,
                  child: _GlassSearchPanel(
                    options: _filteredOptions,
                    searchText: widget.controller.text,
                    label: widget.label,
                    showCreateButtonIfNotFound: widget.showCreateButtonIfNotFound,
                    onCreate: (text) {
                      widget.onCreate(text);
                      _focusNode.unfocus();
                    },
                    onItemSelected: (item) {
                      widget.onItemSelected(item);
                      _focusNode.unfocus();
                    },
                    labelColor: widget.labelColor,
                    textColor: widget.textColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeOverlay() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextfieldTheme(
        controlador: widget.controller,
        focusNode: _focusNode,
        texto: widget.label,
        inputType: TextInputType.text,
        fillColor: widget.fillColor,
        textColor: widget.textColor,
        labelColor: widget.labelColor,
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _GlassSearchPanel extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final String searchText;
  final String label;
  final bool showCreateButtonIfNotFound;
  final void Function(String) onCreate;
  final void Function(Map<String, dynamic>) onItemSelected;
  final Color? labelColor;
  final Color? textColor;

  const _GlassSearchPanel({
    required this.options,
    required this.searchText,
    required this.label,
    required this.showCreateButtonIfNotFound,
    required this.onCreate,
    required this.onItemSelected,
    this.labelColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyleColor = textColor ?? (isDark ? Colors.white : Colors.black87);

    final showCreateButton = showCreateButtonIfNotFound &&
        searchText.trim().isNotEmpty &&
        !options.any((item) => (item['name'] ?? item['Name'] ?? '').toString().toLowerCase() == searchText.trim().toLowerCase());

    final double itemHeight = 50.0;
    final int visibleItemsCount = options.length + (showCreateButton ? 1 : 0);
    final double maxHeight = visibleItemsCount > 5 ? 250.0 : (visibleItemsCount * itemHeight) + 16.0;

    return GlassContainer(
      padding: const EdgeInsets.all(8),
      hasShadow: true,
      shadowBlur: 30.0,
      shadowOffset: const Offset(0, 10),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: visibleItemsCount,
          itemBuilder: (context, index) {
            if (index == options.length && showCreateButton) {
              return InkWell(
                onTap: () => onCreate(searchText),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: itemHeight - 8,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Crear ${label.replaceAll('*', '').trim()} "$searchText"',
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final item = options[index];
            final itemName = (item['name'] ?? item['Name'] ?? '').toString();

            return InkWell(
              onTap: () => onItemSelected(item),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: itemHeight - 8,
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text(
                  itemName,
                  style: TextStyle(
                    color: textStyleColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
