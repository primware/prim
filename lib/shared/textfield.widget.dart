import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';

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
    this.colorEmpty,
    this.maxLength,
    this.focusNode,
    this.textAlign = TextAlign.start,
  });

  final String? texto;
  final String? pista;
  final IconData? icono;
  final TextEditingController? controlador;
  bool obscure;
  final void Function(String)? onSubmitted, onChanged;
  final bool showSubIcon, readOnly;
  final TextInputType inputType;
  List<TextInputFormatter>? inputFormatters;
  final Color? colorEmpty;
  final int? maxLength;
  final FocusNode? focusNode;
  final TextAlign textAlign;

  @override
  State<TextfieldTheme> createState() => _TextfieldThemeState();
}

class _TextfieldThemeState extends State<TextfieldTheme> {
  Widget suFixIcono = const Icon(
    Icons.visibility_off_outlined,
    color: ColorTheme.accentLight,
  );

  bool mostrarClave = false;

  @override
  Widget build(BuildContext context) {
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
      decoration: InputDecoration(
        hintText: widget.pista,
        hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSecondary.withAlpha(60)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondary.withAlpha(140),
        hoverColor: Theme.of(context).primaryColor.withAlpha(40),
        focusedBorder: OutlineInputBorder(
          //Cuando estoy en el control
          borderSide: BorderSide(
              width: 1,
              color: widget.colorEmpty ??
                  Theme.of(context)
                      .primaryColor), // Color del borde cuando está enfocado
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: OutlineInputBorder(
          //Cuando no estoy en el control
          borderSide: BorderSide(
              color: widget.colorEmpty ??
                  Theme.of(context)
                      .colorScheme
                      .secondary), // Color del borde cuando no está enfocado
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(4),
          ),
        ),
        labelText: widget.texto,
        labelStyle: Theme.of(context).textTheme.bodyMedium,
        prefixIcon: widget.icono != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child:
                    Icon(widget.icono, color: Theme.of(context).primaryColor),
              )
            : null,
        suffixIcon: widget.showSubIcon
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    if (mostrarClave) {
                      mostrarClave = false;
                      widget.obscure = true;
                      suFixIcono = Icon(
                        Icons.visibility_off_outlined,
                        color: Theme.of(context).colorScheme.onSecondary,
                      );
                    } else {
                      mostrarClave = true;
                      widget.obscure = false;
                      suFixIcono = Icon(
                        Icons.visibility_outlined,
                        color: Theme.of(context).primaryColor,
                      );
                    }
                  });
                },
                child: MouseRegion(
                  cursor:
                      SystemMouseCursors.click, // Cambia el cursor a una mano
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: suFixIcono,
                  ),
                ),
              )
            : null,
        floatingLabelStyle: Theme.of(context).textTheme.bodyLarge,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      textAlign: widget.textAlign,
    );
  }
}

class TextFieldComments extends StatefulWidget {
  const TextFieldComments(
      {super.key,
      this.pista,
      this.controlador,
      this.readOnly = false,
      this.texto,
      this.colorEmpty,
      this.onSubmitted,
      this.onChanged});

  final String? pista, texto;
  final TextEditingController? controlador;
  final bool readOnly;
  final Color? colorEmpty;
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
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.pista,
        hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSecondary.withAlpha(60)),
        filled: true, // Habilita el relleno del fondo
        fillColor: Theme.of(context).colorScheme.secondary.withAlpha(140),
        hoverColor: Theme.of(context).primaryColor.withAlpha(40),
        focusedBorder: OutlineInputBorder(
          //Cuando estoy en el control
          borderSide: BorderSide(
              width: 1,
              color: widget.colorEmpty ??
                  Theme.of(context)
                      .primaryColor), // Color del borde cuando está enfocado
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: OutlineInputBorder(
          //Cuando no estoy en el control
          borderSide: BorderSide(
              color: widget.colorEmpty ??
                  Theme.of(context)
                      .colorScheme
                      .secondary), // Color del borde cuando no está enfocado
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(4),
          ),
        ),
        labelText: widget.texto,
        labelStyle: Theme.of(context).textTheme.bodyMedium,
        alignLabelWithHint: true,
        floatingLabelStyle: const TextStyle(
          color: ColorTheme.accentLight,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
