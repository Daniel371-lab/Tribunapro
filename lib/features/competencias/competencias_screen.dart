import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'data/competencias_data.dart';
import 'widgets/competencia_tile.dart';

class CompetenciasScreen extends StatelessWidget {
  const CompetenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Competencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: CompetenciasData.todas.length,
              itemBuilder: (context, index) {
                final competencia = CompetenciasData.todas[index];
                return CompetenciaTile(
                  competencia: competencia,
                  onTap: () => context.push('/competencias/${competencia.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}