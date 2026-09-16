import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/compras_service.dart';
import '../../core/services/pro_state.dart';
import '../login/registro_screen.dart';

class ModoProScreen extends StatefulWidget {
  const ModoProScreen({super.key});

  @override
  State<ModoProScreen> createState() => _ModoProScreenState();
}

class _ModoProScreenState extends State<ModoProScreen> {
  // Colores fijos para esta pantalla: se muestra siempre con este estilo
  // "VIP" oscuro, sin importar el tema claro/oscuro elegido por el usuario.
  static const _fondo = Color(0xFF0D1117);
  static const _superficie = Color(0xFF161B22);
  static const _textoPrincipal = Color(0xFFF0F2F5);
  static const _textoSecundario = Color(0xFF9CA3AF);

  ProductDetails? _producto;
  bool _cargandoPrecio = true;

  // Guardamos el estado Pro al entrar para detectar el cambio exacto
  // (false → true) que significa "el usuario acaba de pagar".
  late final bool _eraProAlEntrar;

  @override
  void initState() {
    super.initState();
    _eraProAlEntrar = esProNotifier.value;
    esProNotifier.addListener(_onEsProCambio);
    _cargarPrecio();
  }

  @override
  void dispose() {
    esProNotifier.removeListener(_onEsProCambio);
    super.dispose();
  }

  void _onEsProCambio() {
    if (!mounted) return;
    // Solo mostramos el agradecimiento si el usuario NO era Pro al entrar
    // y ahora sí lo es. Eso indica que la compra se procesó correctamente.
    if (!_eraProAlEntrar && esProNotifier.value) {
      _mostrarAgradecimiento();
    }
  }

  Future<void> _cargarPrecio() async {
    final producto = await ComprasService.instance.obtenerProductoSuscripcion();
    if (mounted) {
      setState(() {
        _producto = producto;
        _cargandoPrecio = false;
      });
    }
  }

  void _mostrarAgradecimiento() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const _DialogoAgradecimiento(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: _textoPrincipal,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Tribuna Pro VIP',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: _textoPrincipal,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.proBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 32,
                        color: AppColors.pro,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Conviértete en un miembro VIP de la tribuna',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: _textoSecundario),
                    ),
                    const SizedBox(height: 28),

                    _beneficio(
                      icono: Icons.block_rounded,
                      titulo: 'Sin anuncios',
                      detalle: 'Navega la app sin interrupciones',
                    ),
                    const SizedBox(height: 10),
                    _beneficio(
                      icono: Icons.lock_open_rounded,
                      titulo: 'Todos los partidos liberados',
                      detalle: 'Predicciones Pro totalmente liberadas',
                    ),
                    const SizedBox(height: 10),
                    _beneficio(
                      icono: Icons.dark_mode_rounded,
                      titulo: 'Modo oscuro',
                      detalle: 'Exclusivo para miembros VIP',
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _superficie,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SUSCRIPCIÓN MENSUAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: AppColors.pro,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _cargandoPrecio
                              ? const SizedBox(
                                  height: 26,
                                  width: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.pro,
                                  ),
                                )
                              : Text(
                                  _producto != null
                                      ? '${_producto!.price} / mes'
                                      : 'Precio no disponible',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: _textoPrincipal,
                                  ),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botón dinámico: si el usuario ya es Pro, se deshabilita
                    // y cambia el texto. Si no, se comporta como antes.
                    ValueListenableBuilder<bool>(
                      valueListenable: esProNotifier,
                      builder: (context, esPro, _) {
                        final bloqueado = esPro || _cargandoPrecio || _producto == null;
                        final texto = esPro ? 'Ya sos Pro ✓' : 'Hacerme Pro';

                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: esPro
                                  ? _superficie
                                  : AppColors.acentoOscuro,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: bloqueado
                                ? null
                                : () => _intentarComprarSuscripcion(context),
                            child: Text(
                              texto,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: esPro
                                    ? _textoSecundario
                                    : const Color(0xFF04342C),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Cancela cuando quieras desde Play Store',
                      style: TextStyle(fontSize: 11.5, color: _textoSecundario),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _beneficio({
    required IconData icono,
    required String titulo,
    required String detalle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF04342C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 17, color: const Color(0xFF5DCAA5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _textoPrincipal),
                ),
                Text(
                  detalle,
                  style: const TextStyle(fontSize: 12, color: _textoSecundario),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _intentarComprarSuscripcion(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final esInvitado = user == null || user.isAnonymous;

    if (esInvitado) {
      _mostrarDialogoCrearCuenta(context);
      return;
    }

    ComprasService.instance.comprarSuscripcion();
  }

  void _mostrarDialogoCrearCuenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Crea tu cuenta primero',
          style: TextStyle(color: _textoPrincipal, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Para suscribirte a Modo Pro necesitas una cuenta registrada. Así, si cambias de celular o reinstalas la app, no pierdes el acceso a lo que ya pagaste.',
          style: TextStyle(color: _textoSecundario, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ahora no', style: TextStyle(color: _textoSecundario)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.pro,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistroScreen()),
              );
            },
            child: const Text('Crear cuenta', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Diálogo temporal que aparece cuando la compra Pro se procesa OK.
/// Se cierra solo a los 4 segundos, sin que el usuario tenga que tocar nada.
class _DialogoAgradecimiento extends StatefulWidget {
  const _DialogoAgradecimiento();

  @override
  State<_DialogoAgradecimiento> createState() => _DialogoAgradecimientoState();
}

class _DialogoAgradecimientoState extends State<_DialogoAgradecimiento>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkRotate;
  late final Animation<double> _fade;
  Timer? _autoCierre;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // El check entra rotando un poco + creciendo.
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _checkRotate = Tween<double>(begin: -0.35, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    // Se cierra solo a los 4 segundos.
    _autoCierre = Timer(const Duration(seconds: 4), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _autoCierre?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.acentoOscuro.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.acentoOscuro.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _checkRotate.value,
                    child: Transform.scale(
                      scale: _checkScale.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.acentoOscuro.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.acentoOscuro,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: _fade,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '¡Gracias por unirte!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF0F2F5),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Ya eres miembro de la Tribuna VIP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}