import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/ads/rewarded_ad_manager.dart';
import '../../core/models/partido.dart';
import '../../core/services/usuario_state.dart';
import '../../core/widgets/boton_5_anuncios.dart';
import '../ajustes/modo_pro_screen.dart';

class BloqueoProCard extends StatefulWidget {
  final Partido partido;
  const BloqueoProCard({super.key, required this.partido});

  @override
  State<BloqueoProCard> createState() => _BloqueoProCardState();
}

class _BloqueoProCardState extends State<BloqueoProCard> {
  bool _procesando = false;

  void _verAnuncio() {
    setState(() => _procesando = true);
    RewardedAdManager.instance.mostrar(
      onRecompensaGanada: () async {
        await UsuarioState.instance.desbloquearPorAnuncio(widget.partido.id);
        if (mounted) setState(() => _procesando = false);
      },
      onNoDisponible: () {
        if (!mounted) return;
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El anuncio no está disponible todavía, probá de nuevo en un momento.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return ValueListenableBuilder<String?>(
      valueListenable: UsuarioState.instance.ultimoDesbloqueoAnuncio,
      builder: (context, _, __) {
        final yaUsoAnuncioHoy = UsuarioState.instance.yaUsoAnuncioHoy();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: superficie,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.pro.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 18, color: AppColors.pro),
                  const SizedBox(width: 8),
                  Text('Predicción exclusiva', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textoPrincipal)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Desbloqueá este partido para ver las predicciones.', style: TextStyle(fontSize: 12.5, color: textoSecundario)),
              const SizedBox(height: 16),

              // Desbloquear ESTE partido viendo 1 anuncio (1 cada 24h)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_procesando || yaUsoAnuncioHoy) ? null : _verAnuncio,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                  label: Text(yaUsoAnuncioHoy ? 'Ya usaste tu anuncio de hoy' : 'Desbloquear viendo un anuncio'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 10),

              // NUEVO: reemplaza al botón "Pagar y desbloquear este partido".
              // Ve 5 anuncios y desbloquea TODOS los partidos Pro por 24h.
              const Boton5Anuncios(relleno: true),
              const SizedBox(height: 10),

              // Hacerme Pro (pago, quita anuncios para siempre)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ModoProScreen())),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text('Hacerme Pro y ver todos los partidos'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.pro, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}