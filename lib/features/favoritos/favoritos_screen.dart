import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/favoritos_state.dart';
import '../competencias/data/competencias_data.dart';
import '../competencias/widgets/competencia_tile.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Favoritos',
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
              'MIS LIGAS Y COPAS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: textoSecundario,
              ),
            ),
          ),

          // Lista reactiva de favoritos
          Expanded(
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: favoritosNotifier,
              builder: (context, favoritos, _) {
                final todas = [...CompetenciasData.ligas, ...CompetenciasData.copas];
                final marcadas = todas.where((c) => favoritos.contains(c.id)).toList();

                if (marcadas.isEmpty) {
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
                              Icons.star_outline_rounded,
                              size: 42,
                              color: AppColors.acento,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sin favoritos guardados',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Marcá una liga o copa con la estrella para tenerla siempre a mano acá.',
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
                  itemCount: marcadas.length,
                  itemBuilder: (context, index) {
                    final c = marcadas[index];
                    return CompetenciaTile(
                      competencia: c,
                      onTap: () => context.push('/competencias/${c.id}'),
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
