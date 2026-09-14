import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/compras_service.dart';
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

  @override
  void initState() {
    super.initState();
    _cargarPrecio();
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
                      decoration: BoxDecoration(
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

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.acentoOscuro,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: (_cargandoPrecio || _producto == null)
                            ? null
                            : () => _intentarComprarSuscripcion(context),
                        child: const Text(
                          'Hacerme Pro',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF04342C)),
                        ),
                      ),
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