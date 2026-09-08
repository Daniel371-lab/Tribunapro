import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/models/partido.dart';
import '../../core/services/firestore_service.dart';
import '../dashboard/widgets/partido_card.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final servicio = FirestoreService();
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header principal
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'Historial',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: textoPrincipal,
              ),
            ),
          ),

          // Subtítulo de sección estilo Muted
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'PARTIDOS FINALIZADOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: textoSecundario,
              ),
            ),
          ),

          // StreamBuilder con la lista del historial
          Expanded(
            child: StreamBuilder<List<Partido>>(
              stream: servicio.historial(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ocurrió un error al cargar el historial',
                      style: TextStyle(color: textoSecundario, fontSize: 14),
                    ),
                  );
                }
                
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final partidos = snapshot.data!;

                if (partidos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.acento.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              size: 42,
                              color: AppColors.acento,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sin partidos finalizados',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Acá aparecerá el registro de los partidos completados y el resultado de tus predicciones.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: partidos.length,
                  itemBuilder: (context, index) => PartidoCard(
                    partido: partidos[index],
                    onTap: () => context.push('/partido', extra: partidos[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
