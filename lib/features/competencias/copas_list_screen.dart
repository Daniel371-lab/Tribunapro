import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'data/competencias_data.dart';
import 'widgets/competencia_tile.dart';

class CopasListScreen extends StatelessWidget {
  const CopasListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Copas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: CompetenciasData.copas.length,
              itemBuilder: (context, index) {
                final copa = CompetenciasData.copas[index];
                return CompetenciaTile(
                  competencia: copa,
                  onTap: () => context.push('/competencias/copas/${copa.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}