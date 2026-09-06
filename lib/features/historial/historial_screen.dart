import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../dashboard/widgets/partido_card.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final servicio = FirestoreService();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Historial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: StreamBuilder(
              stream: servicio.historial(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final partidos = snapshot.data!;
                if (partidos.isEmpty) {
                  return const Center(child: Text('Todavía no hay partidos finalizados'));
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