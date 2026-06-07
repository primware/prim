import 'package:flutter/material.dart';

class ButtonPrimary extends StatefulWidget {
  const ButtonPrimary({super.key, this.onPressed, this.onLongPress, this.texto, this.icono, this.fullWidth = false, this.enable = true});

  final Function()? onPressed, onLongPress;
  final String? texto;
  final IconData? icono;
  final bool fullWidth, enable;

  @override
  State<ButtonPrimary> createState() => _ButtonPrimaryState();
}

class _ButtonPrimaryState extends State<ButtonPrimary> {
  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.enable && widget.onPressed != null;

    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isActive ? 1.0 : 0.5,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            backgroundColor: Theme.of(context).primaryColor,
            disabledBackgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: isActive
              ? () {
                  widget.onPressed?.call();
                }
              : null,
          onLongPress: isActive && widget.onLongPress != null
              ? () {
                  widget.onLongPress?.call();
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icono != null) Icon(widget.icono, color: Theme.of(context).cardColor),
              if (widget.icono != null && widget.texto != null) const SizedBox(width: 6),
              if (widget.texto != null)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.texto!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.surface),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ButtonSecondary extends StatefulWidget {
  const ButtonSecondary({super.key, this.onPressed, this.texto, this.icono, this.fullWidth = false});

  final Function()? onPressed;
  final String? texto;
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
          backgroundColor: Theme.of(context).cardColor,
          side: BorderSide(color: Theme.of(context).primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          widget.onPressed?.call();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icono != null) Icon(widget.icono, color: Theme.of(context).primaryColor),
            if (widget.icono != null && widget.texto != null) const SizedBox(width: 6),
            if (widget.texto != null)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.texto!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ButtonLoading extends StatelessWidget {
  const ButtonLoading({super.key, this.fullWidth = false});

  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(minHeight: 6, color: Theme.of(context).cardColor, backgroundColor: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}
