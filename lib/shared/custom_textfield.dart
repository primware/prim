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

  @override
  State<TextfieldTheme> createState() => _TextfieldThemeState();
}

class _TextfieldThemeState extends State<TextfieldTheme> {
  bool mostrarClave = false;

  Widget get suFixIcono => Icon(
        mostrarClave
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: mostrarClave
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.secondary,
      );

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
      textAlign: widget.textAlign ?? TextAlign.start,
      decoration: InputDecoration(
        counterText: '',
        hintText: widget.pista,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
        filled: true, // Habilita el relleno del fondo
        fillColor: Theme.of(context).colorScheme.onPrimary,
        hoverColor: Theme.of(context).primaryColor.withAlpha(40),
        focusedBorder: OutlineInputBorder(
          //Cuando estoy en el control
          borderSide: BorderSide(
              width: 2,
              color: Theme.of(context)
                  .colorScheme
                  .primary), // Color del borde cuando está enfocado
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: OutlineInputBorder(
          //Cuando no estoy en el control
          borderSide: BorderSide(
              color: widget.colorEmpty
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context)
                      .primaryColor), // Color del borde cuando no está enfocado
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(4),
          ),
        ),
        labelText: widget.texto,
        labelStyle: Theme.of(context).textTheme.bodyLarge,

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
        floatingLabelStyle: Theme.of(context).textTheme.bodyLarge,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: Theme.of(context).textTheme.bodyLarge,
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
      this.onSubmitted,
      this.colorEmpty = false,
      this.onChanged});

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
        fillColor: Theme.of(context).colorScheme.surface,
        hoverColor: Theme.of(context).colorScheme.primary.withAlpha(40),
        focusedBorder: OutlineInputBorder(
          //Cuando estoy en el control
          borderSide: BorderSide(
              width: 2,
              color: Theme.of(context)
                  .colorScheme
                  .primary), // Color del borde cuando está enfocado
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: OutlineInputBorder(
          //Cuando no estoy en el control
          borderSide: BorderSide(
              color: widget.colorEmpty
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context)
                      .primaryColor), // Color del borde cuando no está enfocado
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
        floatingLabelStyle: Theme.of(context).textTheme.bodyLarge,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
