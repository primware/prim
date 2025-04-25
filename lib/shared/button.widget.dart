import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/fonts.dart';

class ButtonPrimary extends StatefulWidget {
  const ButtonPrimary({
    super.key,
    this.onPressed,
    this.onLongPress,
    this.texto,
    this.icono,
    this.bgcolor = ColorTheme.textDark,
    this.textcolor = ColorTheme.accentLight,
    this.fullWidth = false,
  });

  final Function()? onPressed, onLongPress;
  final String? texto;
  final Color bgcolor, textcolor;
  final IconData? icono;
  final bool fullWidth;

  @override
  State<ButtonPrimary> createState() => _ButtonPrimaryState();
}

class _ButtonPrimaryState extends State<ButtonPrimary> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          backgroundColor: widget.bgcolor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          widget.onPressed?.call();
        },
        onLongPress: () {
          widget.onLongPress?.call();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icono != null)
              Icon(
                widget.icono,
                color: widget.textcolor,
              ),
            if (widget.icono != null && widget.texto != null)
              const SizedBox(width: 6),
            if (widget.texto != null)
              Text(
                widget.texto!,
                style: FontsTheme.h4Bold(color: widget.textcolor),
              ),
          ],
        ),
      ),
    );
  }
}

class ButtonSecondary extends StatefulWidget {
  const ButtonSecondary({
    super.key,
    this.onPressed,
    this.texto,
    this.icono,
    this.borderColor = ColorTheme.accentLight,
    this.textcolor = ColorTheme.accentLight,
    this.bgcolor = ColorTheme.backgroundLight,
    this.fullWidth = false,
  });

  final Function()? onPressed;
  final String? texto;
  final Color borderColor, textcolor, bgcolor;
  final IconData? icono;
  final bool fullWidth;

  @override
  State<ButtonSecondary> createState() => _ButtonSecondaryState();
}

class _ButtonSecondaryState extends State<ButtonSecondary> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          backgroundColor: widget.bgcolor,
          side: BorderSide(color: widget.borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          widget.onPressed?.call();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icono != null)
              Icon(
                widget.icono,
                color: widget.textcolor,
              ),
            if (widget.icono != null && widget.texto != null)
              const SizedBox(width: 6),
            if (widget.texto != null)
              Text(
                widget.texto!,
                style: FontsTheme.h4Bold(color: widget.textcolor),
              ),
          ],
        ),
      ),
    );
  }
}

class ButtonLoading extends StatelessWidget {
  const ButtonLoading({
    super.key,
    this.bgcolor = ColorTheme.textDark,
    this.textcolor = ColorTheme.accentLight,
    this.fullWidth = false,
  });

  final Color bgcolor, textcolor;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            backgroundColor: bgcolor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(
              minHeight: 6,
              color: textcolor,
              backgroundColor: bgcolor,
              borderRadius: BorderRadius.circular(4),
            ),
          )),
    );
  }
}
