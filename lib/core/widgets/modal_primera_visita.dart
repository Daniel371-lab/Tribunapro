import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../services/pro_temporal_service.dart';

/// Modal que se muestra UNA sola vez, la primera vez que el usuario
/// abre un partido. Ofrece 2 caminos: hacerse Pro (pago) o ver 5
/// anuncios para desbloquear los partidos Pro por 24 horas.
class ModalPrimeraVisita extends StatelessWidget {
  /// Se llama cuando el usuario toca "Hacerme Pro". El caller debe navegar
  /// a ModoProScreen.
  final VoidCallback onSerPro;

  /// Se llama cuando el usuario toca "Ver 5 anuncios". El caller debe
  /// abrir el flujo de los 5 anuncios.
  final VoidCallback onVer5Anuncios;

  const ModalPrimeraVisita({
    super.key,
    required this.onSerPro,
    required this.onVer5Anuncios,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required VoidCallback onSerPro,
    required VoidCallback onVer5Anuncios,
  }) async {
    // Si ya lo vio antes, no mostramos nada.
    final yaVisto = await ProTemporalService.instance.yaVioModalPrimeraVez();
    if (!context.mounted || yaVisto) return;

    // Marcamos como visto ANTES de mostrar el modal. Así, si el usuario
    // cierra la app sin cerrar el modal, no se le vuelve a mostrar.
    await ProTemporalService.instance.marcarModalPrimeraVezVisto();

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
                  'Bienvenido a Tribuna Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textoPrincipal,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elegí cómo querés disfrutar la app. Podés ver todos los partidos Pro con una de estas dos opciones:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.45, color: textoSecundario),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onSerPro,
                    icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                    label: const Text('Hacerme Pro'),
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
                    label: const Text('Ver 5 anuncios para desbloquear 24h'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
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