import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Colores del splash (verde cancha con profundidad)
  static const Color _verdeCanchaClaro = Color(0xFF2E9E5B);
  static const Color _verdeCanchaOscuro = Color(0xFF0E5A2E);

  late final AnimationController _controller;
  late final Animation<double> _fadeLogo;
  late final Animation<double> _scaleLogo;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeLogo = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleLogo = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _decidirDestino();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decidirDestino() async {
    final esperaMinima = Future.delayed(const Duration(seconds: 2));
    final estadoAuth = FirebaseAuth.instance.authStateChanges().first;

    await Future.wait([esperaMinima, estadoAuth]);

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_verdeCanchaClaro, _verdeCanchaOscuro],
          ),
        ),
        child: Stack(
          children: [
            // Aro decorativo tipo "círculo central" de cancha
            Positioned(
              left: -120,
              top: -80,
              child: _AroDecorativo(
                size: 340,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              right: -140,
              bottom: -100,
              child: _AroDecorativo(
                size: 420,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),

            // Contenido principal
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fadeLogo,
                    child: ScaleTransition(
                      scale: _scaleLogo,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ícono de balón dentro de un círculo
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.sports_soccer_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Tribuna Pro',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.8,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'J P L A B S',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),

                  // Indicador sutil de carga
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aro simple y reutilizable para decorar el fondo.
class _AroDecorativo extends StatelessWidget {
  final double size;
  final Color color;

  const _AroDecorativo({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }
}