import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'data/competencias_data.dart';
import 'widgets/competencia_tile.dart';

class LigasListScreen extends StatelessWidget {
  const LigasListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Ligas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: CompetenciasData.ligas.length,
              itemBuilder: (context, index) {
                final liga = CompetenciasData.ligas[index];
                return CompetenciaTile(
                  competencia: liga,
                  onTap: () => context.push('/competencias/ligas/${liga.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}