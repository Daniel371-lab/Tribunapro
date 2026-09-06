import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/favoritos_state.dart';
import '../competencias/data/competencias_data.dart';
import '../competencias/widgets/competencia_tile.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Favoritos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: favoritosNotifier,
              builder: (context, favoritos, _) {
                final todas = [...CompetenciasData.ligas, ...CompetenciasData.copas];
                final marcadas = todas.where((c) => favoritos.contains(c.id)).toList();

                if (marcadas.isEmpty) {
                  return const Center(
                    child: Text('Marcá una liga o copa con la estrella para verla acá'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: marcadas.length,
                  itemBuilder: (context, index) {
                    final c = marcadas[index];
                    final esLiga = CompetenciasData.ligas.contains(c);
                    return CompetenciaTile(
                      competencia: c,
                      onTap: () => context.push(
                        '/competencias/${esLiga ? 'ligas' : 'copas'}/${c.id}',
                      ),
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