import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/terminos_state.dart';
import '../../core/utils/auth_errors.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  bool _aceptaTerminos = false;
  bool _cargando = false;

  static final _regexPassword = RegExp(r'^(?=.*[A-Z])[A-Za-z0-9]{7,15}$');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.error),
    );
  }

  String? _validarNombre(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Este campo es obligatorio.';
    if (texto.length < 2) return 'Debe tener al menos 2 caracteres.';
    if (texto.length > 30) return 'No puede superar los 30 caracteres.';
    final regex = RegExp(r'^[A-Za-zÀ-ÿñÑ\s]+$');
    if (!regex.hasMatch(texto)) return 'Solo se permiten letras.';
    return null;
  }

  String? _validarEmail(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Ingresa un correo.';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
    if (!regex.hasMatch(valor.trim())) return 'El correo no es válido.';
    return null;
  }

  String? _validarPassword(String? valor) {
    if (valor == null || valor.isEmpty) return 'Ingresa una contraseña.';
    if (!_regexPassword.hasMatch(valor)) {
      return 'Debe tener entre 7 y 15 caracteres, solo letras y números, con al menos una mayúscula.';
    }
    return null;
  }

  String? _validarConfirmacion(String? valor) {
    if (valor != _passwordCtrl.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_aceptaTerminos) {
      _mostrarMensaje('Debes aceptar los Términos y Condiciones para continuar.');
      return;
    }

    setState(() => _cargando = true);
    try {
      await _auth.registrarConEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
      );
      await TerminosState.marcarAceptados();
    } catch (e) {
      if (mounted) _mostrarMensaje(mensajeErrorAuth(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Completa tus datos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textoPrincipal),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nombreCtrl,
                  maxLength: 30,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  validator: _validarNombre,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _apellidoCtrl,
                  maxLength: 30,
                  decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder()),
                  validator: _validarNombre,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder()),
                  validator: _validarEmail,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    helperText: '7 a 15 caracteres, letras y números, al menos una mayúscula.',
                    helperMaxLines: 2,
                  ),
                  validator: _validarPassword,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmarCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmar contraseña', border: OutlineInputBorder()),
                  validator: _validarConfirmacion,
                ),

                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _aceptaTerminos,
                      activeColor: AppColors.acento,
                      onChanged: (valor) => setState(() => _aceptaTerminos = valor ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/terminos'),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 12, color: textoSecundario),
                              children: [
                                const TextSpan(text: 'Acepto los '),
                                TextSpan(
                                  text: 'Términos y Condiciones y la Política de Privacidad',
                                  style: TextStyle(
                                    color: AppColors.acento,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.acento,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _cargando ? null : _registrar,
                  child: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
