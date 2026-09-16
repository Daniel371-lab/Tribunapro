import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Tarjeta minimalista que reemplaza al banner de AdMob cuando el
/// usuario es Pro. Muestra un check animado (rota + scale) y un
/// mensaje de bienvenida a la Tribuna VIP.
class AgradecimientoProCard extends StatefulWidget {
  const AgradecimientoProCard({super.key});

  @override
  State<AgradecimientoProCard> createState() => _AgradecimientoProCardState();
}

class _AgradecimientoProCardState extends State<AgradecimientoProCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkRotate;
  late final Animation<double> _fadeTexto;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // El check aparece con scale + rotación suave (de -20° a 0°).
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

    // El texto aparece después, en fade.
    _fadeTexto = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final acentoActual = esOscuro ? AppColors.acentoOscuro : AppColors.acento;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: acentoActual.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Check animado: aparece rotando un poco + creciendo.
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: acentoActual.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: acentoActual,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FadeTransition(
              opacity: _fadeTexto,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¡Bienvenido a la Tribuna VIP!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textoPrincipal,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gracias por unirte. Sin anuncios para siempre.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}