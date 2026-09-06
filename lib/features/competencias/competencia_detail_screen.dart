import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../dashboard/widgets/partido_card.dart';
import 'data/competencias_data.dart';

class CompetenciaDetailScreen extends StatelessWidget {
  final String competenciaId;
  const CompetenciaDetailScreen({super.key, required this.competenciaId});

  @override
  Widget build(BuildContext context) {
    final servicio = FirestoreService();
    final nombre = CompetenciasData.nombrePorId(competenciaId);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: servicio.partidosPorCompetencia(competenciaId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final partidos = snapshot.data!;
                if (partidos.isEmpty) {
                  return const Center(child: Text('No hay partidos próximos en esta competencia'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: partidos.length,
                  itemBuilder: (context, index) => PartidoCard(partido: partidos[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}