import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/firestore_service.dart';
import 'widgets/partido_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final servicio = FirestoreService();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tribuna pro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/ajustes'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Próximos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: servicio.proximosPartidos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('No se pudo cargar los partidos'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final partidos = snapshot.data!;
                if (partidos.isEmpty) {
                  return const Center(child: Text('No hay próximos partidos cargados'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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