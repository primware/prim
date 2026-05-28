import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class TextfieldTheme extends StatefulWidget {
  TextfieldTheme({
    super.key,
    this.icono,
    this.controlador,
    this.texto,
    this.pista,
    this.obscure = false,
    this.onSubmitted,
    this.onChanged,
    this.showSubIcon = false,
    this.inputType = TextInputType.text,
    this.inputFormatters,
    this.readOnly = false,
    this.colorEmpty = false,
    this.maxLength,
    this.focusNode,
    this.textAlign,
    this.fillColor,
    this.textColor,
    this.labelColor,
  });

  final String? texto;
  final String? pista;
  final IconData? icono;
  final TextAlign? textAlign;
  final TextEditingController? controlador;
  bool obscure;
  final void Function(String)? onSubmitted, onChanged;
  final bool showSubIcon, readOnly, colorEmpty;
  final TextInputType inputType;
  List<TextInputFormatter>? inputFormatters;

  final int? maxLength;
  final FocusNode? focusNode;
  final Color? fillColor;
  final Color? textColor;
  final Color? labelColor;

  @override
  State<TextfieldTheme> createState() => _TextfieldThemeState();
}

class _TextfieldThemeState extends State<TextfieldTheme> {
  bool mostrarClave = false;

  Widget get suFixIcono => Icon(
    mostrarClave ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    color: mostrarClave
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.secondary,
  );

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = widget.textColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);
    final defaultLabelColor = widget.labelColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54);

    return TextField(
      maxLength: widget.maxLength,
      focusNode: widget.focusNode,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      obscureText: widget.obscure,
      controller: widget.controlador,
      readOnly: widget.readOnly,
      inputFormatters: widget.inputFormatters ?? [],
      keyboardType: widget.inputType,
      textAlign: widget.textAlign ?? TextAlign.start,
      decoration: InputDecoration(
        counterText: '',
        hintText: widget.pista,
        hintStyle: TextStyle(color: defaultLabelColor.withOpacity(0.6)),
        filled: true, // Habilita el relleno del fondo
        fillColor: widget.fillColor ?? Theme.of(context).cardColor,
        hoverColor: Theme.of(context).primaryColor.withAlpha(40),
        focusedBorder: OutlineInputBorder(
          //Cuando estoy en el control
          borderSide: BorderSide(
            width: 2,
            color: Theme.of(context).colorScheme.primary,
          ), // Color del borde cuando está enfocado
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: OutlineInputBorder(
          //Cuando no estoy en el control
          borderSide: BorderSide(
            color: widget.colorEmpty
                ? Theme.of(context).colorScheme.errorContainer
                : (widget.fillColor != null ? Colors.white.withOpacity(0.15) : Theme.of(context).primaryColor),
          ), // Color del borde cuando no está enfocado
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        labelText: widget.texto,
        labelStyle: TextStyle(color: defaultLabelColor),
        prefixIcon: widget.icono != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  widget.icono,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : null,
        suffixIcon: widget.showSubIcon
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    mostrarClave = !mostrarClave;
                    widget.obscure = !widget.obscure;
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: suFixIcono,
                  ),
                ),
              )
            : null,
        floatingLabelStyle: TextStyle(color: widget.textColor ?? Theme.of(context).colorScheme.primary),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: TextStyle(color: defaultTextColor),
    );
  }
}

class TextFieldComments extends StatefulWidget {
  const TextFieldComments({
    super.key,
    this.pista,
    this.controlador,
    this.readOnly = false,
    this.texto,
    this.onSubmitted,
    this.colorEmpty = false,
    this.onChanged,
  });

  final String? pista, texto;
  final TextEditingController? controlador;
  final bool readOnly, colorEmpty;

  final void Function(String)? onSubmitted, onChanged;

  @override
  State<TextFieldComments> createState() => _TextFieldCommentsState();
}

class _TextFieldCommentsState extends State<TextFieldComments> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controlador,
      maxLines: null,
      minLines: 4,
      readOnly: widget.readOnly,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.pista,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        hoverColor: Theme.of(context).colorScheme.primary.withAlpha(40),
        focusedBorder: OutlineInputBorder(
          //Cuando estoy en el control
          borderSide: BorderSide(
            width: 2,
            color: Theme.of(context).colorScheme.primary,
          ), // Color del borde cuando está enfocado
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: OutlineInputBorder(
          //Cuando no estoy en el control
          borderSide: BorderSide(
            color: widget.colorEmpty
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).primaryColor,
          ), // Color del borde cuando no está enfocado
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        labelText: widget.texto,
        labelStyle: Theme.of(context).textTheme.bodyMedium,
        alignLabelWithHint: true,
        floatingLabelStyle: Theme.of(context).textTheme.bodyLarge,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
