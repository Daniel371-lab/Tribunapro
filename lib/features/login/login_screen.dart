import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/terminos_state.dart';
import '../../core/utils/auth_errors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _cargando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? AppColors.error : null,
      ),
    );
  }

  Future<void> _iniciarSesion() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      _mostrarMensaje('Completa correo y contraseña.');
      return;
    }
    setState(() => _cargando = true);
    try {
      await _auth.iniciarSesionConEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await TerminosState.marcarAceptados();
    } catch (e) {
      if (mounted) _mostrarMensaje(mensajeErrorAuth(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _entrarComoInvitado() async {
    setState(() => _cargando = true);
    try {
      await _auth.iniciarSesionInvitado();
      await TerminosState.marcarAceptados();
    } catch (e) {
      if (mounted) _mostrarMensaje(mensajeErrorAuth(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperarContrasena() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _mostrarMensaje('Ingresa tu correo arriba primero, así sabemos a dónde enviarlo.');
      return;
    }
    try {
      await _auth.enviarEmailRecuperacion(_emailCtrl.text.trim());
      if (mounted) {
        _mostrarMensaje(
          'Enviamos un correo para restablecer tu contraseña.',
          esError: false,
        );
      }
    } catch (e) {
      if (mounted) _mostrarMensaje(mensajeErrorAuth(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tribuna Pro',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textoPrincipal),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _cargando ? null : _recuperarContrasena,
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),

              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.acento,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _cargando ? null : _iniciarSesion,
                child: _cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Iniciar sesión'),
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: _cargando ? null : () => context.push('/registro'),
                child: const Text('Registrarte'),
              ),

              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _cargando ? null : _entrarComoInvitado,
                  child: Text(
                    'Iniciar sesión como invitado',
                    style: TextStyle(color: textoSecundario),
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
