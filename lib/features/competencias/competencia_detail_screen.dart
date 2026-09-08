import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/models/partido.dart';
import '../../core/services/firestore_service.dart';
import '../dashboard/widgets/partido_card.dart';
import 'data/competencias_data.dart';

class CompetenciaDetailScreen extends StatelessWidget {
  final String competenciaId;
  
  const CompetenciaDetailScreen({
    super.key, 
    required this.competenciaId,
  });

  @override
  Widget build(BuildContext context) {
    final servicio = FirestoreService();
    final nombre = CompetenciasData.nombrePorId(competenciaId);
    
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera estilizada
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: textoPrincipal,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: textoPrincipal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Subtítulo indicador
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'PARTIDOS PROGRAMADOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: textoSecundario,
                ),
              ),
            ),

            // Lista de partidos con estados visuales mejorados
            Expanded(
              child: StreamBuilder<List<Partido>>(
                stream: servicio.partidosPorCompetencia(competenciaId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Ocurrió un error al cargar los datos',
                        style: TextStyle(color: textoSecundario, fontSize: 14),
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  final partidos = snapshot.data!;
                  
                  if (partidos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer_rounded,
                            size: 48,
                            color: textoSecundario.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay partidos próximos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
      ),
    );
  }
}
