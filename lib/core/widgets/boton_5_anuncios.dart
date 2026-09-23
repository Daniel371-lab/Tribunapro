import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../ads/rewarded_ad_manager.dart';
import '../services/pro_temporal_service.dart';

/// Botón que gestiona la secuencia de 5 anuncios recompensados.
/// El usuario ve uno, vuelve a la app, toca "Siguiente", y así hasta 5.
/// Si completa los 5, se activa el Pro temporal por 24 horas.
/// Si abandona en el medio (cierra la app, sale de la pantalla, etc.),
/// el progreso se pierde y arranca de cero la próxima vez.
class Boton5Anuncios extends StatefulWidget {
  /// Estilo del botón: "filled" (relleno, para bloqueo pro) o
  /// "outlined" (borde, para ajustes).
  final bool relleno;

  const Boton5Anuncios({super.key, this.relleno = true});

  @override
  State<Boton5Anuncios> createState() => _Boton5AnunciosState();
}

class _Boton5AnunciosState extends State<Boton5Anuncios> {
  int _progreso = 0; // 0 a 5
  bool _proTemporalActivo = false;

  @override
  void initState() {
    super.initState();
    _verificarProTemporal();
  }

  Future<void> _verificarProTemporal() async {
    final activo = await ProTemporalService.instance.estaActivo();
    if (mounted) setState(() => _proTemporalActivo = activo);
  }

  void _continuarSecuencia() {
    RewardedAdManager.instance.mostrar(
      onRecompensaGanada: () async {
        _progreso++;
        if (_progreso >= 5) {
          await ProTemporalService.instance.activarPor24Horas();
          if (mounted) {
            setState(() {
              _progreso = 0;
              _proTemporalActivo = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Listo! Vas a ver los partidos Pro por 24 horas.'),
              ),
            );
          }
        } else {
          if (mounted) setState(() {});
        }
      },
      onNoDisponible: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El anuncio no está disponible, probá de nuevo en un momento.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final acentoActual = esOscuro ? AppColors.acentoOscuro : AppColors.acento;

    // Si el Pro temporal ya está activo, mostramos un mensaje fijo.
    if (_proTemporalActivo) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: acentoActual.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: acentoActual.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: acentoActual),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Partidos Pro desbloqueados por 24h',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: acentoActual),
              ),
            ),
          ],
        ),
      );
    }

    // Texto según el progreso
    final String texto;
    if (_progreso == 0) {
      texto = 'Ver 5 anuncios y desbloquear 24h';
    } else {
      texto = 'Siguiente anuncio ($_progreso/5)';
    }

    final icono = _progreso == 0
        ? Icons.play_circle_outline_rounded
        : Icons.play_arrow_rounded;

    if (widget.relleno) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _continuarSecuencia,
          icon: Icon(icono, size: 18),
          label: Text(texto),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.pro,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _continuarSecuencia,
        icon: Icon(icono, size: 18),
        label: Text(texto),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}