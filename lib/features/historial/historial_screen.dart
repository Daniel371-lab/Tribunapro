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
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final acentoActual = esOscuro ? AppColors.acentoOscuro : AppColors.acento;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'Historial',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: textoPrincipal),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'PARTIDOS FINALIZADOS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textoSecundario),
            ),
          ),
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
                              color: acentoActual.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.history_rounded, size: 42, color: acentoActual),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sin partidos finalizados',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textoPrincipal),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Acá aparecerá el registro de los partidos completados y el resultado de tus predicciones.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, height: 1.4, color: textoSecundario),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                int totalPredicciones = 0;
                int aciertos = 0;
                final partidosConPredicciones = <String>{};

                for (final p in partidos) {
                  final items = p.predicciones;
                  if (items == null) continue;
                  for (final item in items) {
                    if (item.cumplida != null) {
                      totalPredicciones++;
                      if (item.cumplida == true) aciertos++;
                      partidosConPredicciones.add(p.id);
                    }
                  }
                }

                final porcentaje = totalPredicciones == 0 ? null : ((aciertos / totalPredicciones) * 100).round();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: partidos.length + (porcentaje != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (porcentaje != null) {
                      if (index == 0) {
                        return _buildCardResumen(
                          context,
                          porcentaje: porcentaje,
                          aciertos: aciertos,
                          total: totalPredicciones,
                          partidosCount: partidosConPredicciones.length,
                          superficie: superficie,
                          textoPrincipal: textoPrincipal,
                          textoSecundario: textoSecundario,
                          acentoActual: acentoActual,
                        );
                      }
                      final partido = partidos[index - 1];
                      return PartidoCard(
                        partido: partido,
                        onTap: () => context.push('/partido', extra: partido),
                      );
                    }
                    final partido = partidos[index];
                    return PartidoCard(
                      partido: partido,
                      onTap: () => context.push('/partido', extra: partido),
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

  Widget _buildCardResumen(
    BuildContext context, {
    required int porcentaje,
    required int aciertos,
    required int total,
    required int partidosCount,
    required Color superficie,
    required Color textoPrincipal,
    required Color textoSecundario,
    required Color acentoActual,
  }) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (esOscuro ? Colors.black : const Color(0xFF1A1A1A)).withValues(alpha: esOscuro ? 0.4 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: acentoActual.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$porcentaje%',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: acentoActual),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Porcentaje de aciertos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textoPrincipal),
                ),
                const SizedBox(height: 4),
                Text(
                  '$aciertos de $total predicciones acertadas',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textoSecundario),
                ),
                const SizedBox(height: 2),
                Text(
                  'Repartidas en $partidosCount ${partidosCount == 1 ? "partido" : "partidos"}',
                  style: TextStyle(fontSize: 11.5, color: textoSecundario.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}