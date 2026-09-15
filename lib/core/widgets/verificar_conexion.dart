import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class VerificarConexion extends StatefulWidget {
  final Widget child;
  const VerificarConexion({super.key, required this.child});

  @override
  State<VerificarConexion> createState() => _VerificarConexionState();
}

class _VerificarConexionState extends State<VerificarConexion> {
  bool _hayConexion = true;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = Connectivity().onConnectivityChanged.listen(_actualizar);
    _verificarInicial();
  }

  Future<void> _verificarInicial() async {
    final resultado = await Connectivity().checkConnectivity();
    _actualizar(resultado);
  }

  void _actualizar(List<ConnectivityResult> resultados) {
    final conectado = resultados.any((r) => r != ConnectivityResult.none);
    if (mounted) setState(() => _hayConexion = conectado);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hayConexion) return widget.child;
    return const _PantallaSinConexion();
  }
}

class _PantallaSinConexion extends StatelessWidget {
  const _PantallaSinConexion();

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = esOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Scaffold(
      backgroundColor: fondo,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: textoSecundario.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off_rounded, size: 44, color: textoSecundario),
              ),
              const SizedBox(height: 24),
              Text(
                'Sin conexión a internet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: textoPrincipal,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tribuna Pro necesita estar conectada para mostrarte los partidos y predicciones.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.5, color: textoSecundario),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textoSecundario),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Esperando conexión...',
                    style: TextStyle(fontSize: 12, color: textoSecundario),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}