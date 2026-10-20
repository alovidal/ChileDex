import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_theme.dart';

// ============ Input reutilizable de la app ============
class AppInput extends StatefulWidget {
  // Atributos
  final String label; // Texto que aparecera
  final String? hint; // Texto de pista que aparece cuando el campo está vacío.
  final String? helperText; // Texto de ayuda que aparece debajo del campo
  final TextEditingController? controller; // Controller para leer y escribir el valor del campo externamente.
  final FocusNode? focusNode; // FocusNode para manejar el foco desde el widget padre.
  final TextInputType keyboardType; //Tipo de teclado que se muestra al enfocar el campo.
  final TextInputAction textInputAction; // Acción del botón de teclado
  final bool isPassword; // Si es true, oculta el texto
  final List<TextInputFormatter>? inputFormatters; //  Formateadores de entrada para restringir caracteres.
  final ValueChanged<String>? onSubmitted; // Callback que se ejecuta cuando el usuario envía el campo
  final ValueChanged<String>? onChanged; // Callback que se ejecuta en cada cambio de valor.
  final String? Function(String?)? validator; // Función de validación. Devuelve un mensaje de error o null si es válido.
  final bool readOnly; // Si es true, el campo no puede editarse.
  final IconData? prefixIcon; // Ícono que aparece al inicio del campo
  final Widget? suffix; // Widget personalizado que aparece al final del campo

  const AppInput({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.isPassword = false,
    this.inputFormatters,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.readOnly = false,
    this.prefixIcon,
    this.suffix,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  // Controla si el texto de la contraseña es visible o no.
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  // Alterna la visibilidad del texto (solo para campos de contraseña).
  void _toggleObscure() => setState(() => _obscureText = !_obscureText);

  // Construye el ícono del sufijo para campos de contraseña.
  Widget? _buildSuffix() {
    // Si es contraseña, muestra el toggle de visibilidad
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppTheme.textGray,
          size: 20,
        ),
        onPressed: _toggleObscure,
      );
    }

    // Si no es contraseña, usa el sufijo personalizado (puede ser null)
    return widget.suffix;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscureText,        // Oculta el texto si es contraseña
      inputFormatters: widget.inputFormatters,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      validator: widget.validator,
      readOnly: widget.readOnly,
      // El estilo base viene de InputDecorationTheme en AppTheme
      // Solo sobreescribimos lo que necesita ser dinámico
      decoration: InputDecoration(
        labelText: null,
        hintText: widget.hint,
        helperText: widget.helperText,

        // Ícono del lado izquierdo
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppTheme.textGray, size: 20)
            : null,

        // Ícono o widget del lado derecho
        suffixIcon: _buildSuffix(),
      ),
    );
  }
}