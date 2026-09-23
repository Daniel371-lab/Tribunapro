import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../services/pro_temporal_service.dart';

/// Modal que se muestra la PRIMERA vez que el usuario abre un partido
/// en esta sesión de app. Se resetea al cerrar y reabrir la app.
/// NO se muestra si el usuario ya vio algún partido en esta sesión.
class ModalPrimeraVisita extends StatelessWidget {
  final VoidCallback onSerPro;
  final VoidCallback onVer5Anuncios;

  const ModalPrimeraVisita({
    super.key,
    required this.onSerPro,
    required this.onVer5Anuncios,
  });

  /// Muestra el modal si corresponde (no se mostró todavía en esta sesión).
  /// Al terminar (por cualquier vía), marca el flag en memoria.
  static Future<void> mostrar(
    BuildContext context, {
    required VoidCallback onSerPro,
    required VoidCallback onVer5Anuncios,
  }) async {
    // Ya se mostró en esta sesión de app
    if (ProTemporalService.instance.modalMostradoEstaSesion) return;

    // Marcamos ANTES de mostrar, por si el usuario cierra la app con el
    // modal abierto. Igual, como es en memoria, se resetea al reabrir.
    ProTemporalService.instance.marcarModalMostradoEstaSesion();

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => ModalPrimeraVisita(
        onSerPro: () {
          Navigator.of(ctx).pop();
          onSerPro();
        },
        onVer5Anuncios: () {
          Navigator.of(ctx).pop();
          onVer5Anuncios();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final acentoActual = esOscuro ? AppColors.acentoOscuro : AppColors.acento;

    return Dialog(
      backgroundColor: superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: acentoActual.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.stadium_rounded, color: acentoActual, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tribuna Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textoPrincipal,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Elige cómo prefieres ver los partidos Pro:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.45, color: textoSecundario),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onSerPro,
                    icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Hacerme Pro'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.pro,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onVer5Anuncios,
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Desbloquear 24h con 5 anuncios'),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Botón X arriba a la derecha
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              icon: Icon(Icons.close_rounded, size: 20, color: textoSecundario),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}