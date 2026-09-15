import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ads/interstitial_ad_manager.dart';
import '../../core/models/partido.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/estado_vacio.dart';
import 'widgets/partido_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final servicio = FirestoreService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header principal
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
  TextSpan(
    children: [
      TextSpan(
        text: 'Tribuna ',
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      const TextSpan(
        text: 'Pro',
        style: TextStyle(color: Color(0xFF890F20)),
      ),
    ],
  ),
  style: const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  ),
),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 24),
                  onPressed: () => context.push('/ajustes'),
                ),
              ],
            ),
          ),

          // Título de sección con estilo Muted
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Text(
              'PRÓXIMOS PARTIDOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),

          // Lista de partidos desglosada
          Expanded(
            child: StreamBuilder<List<Partido>>(
              stream: servicio.proximosPartidos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const EstadoVacio(
                    icono: Icons.cloud_off_rounded,
                    titulo: 'No pudimos cargar los partidos',
                    subtitulo: 'Revisá tu conexión a internet e intentá de nuevo.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final partidos = snapshot.data!;
                if (partidos.isEmpty) {
                  return const EstadoVacio(
                    icono: Icons.sports_soccer_rounded,
                    titulo: 'No hay partidos próximos',
                    subtitulo: 'Estamos preparando los próximos encuentros. Volvé en un rato.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: partidos.length,
                  itemBuilder: (context, index) {
                    final partido = partidos[index];
                    return PartidoCard(
                      partido: partido,
                      onTap: () {
                        InterstitialAdManager.instance.mostrarSiCorresponde(
                          esPro: partido.esPro,
                          alTerminar: () => context.push('/partido', extra: partido),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}