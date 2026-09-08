import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import 'data/competencias_data.dart';
import 'widgets/competencia_tile.dart';

class CompetenciasScreen extends StatelessWidget {
  const CompetenciasScreen({super.key});

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
              'Competencias',
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
              'LIGAS Y TORNEOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: textoSecundario,
              ),
            ),
          ),

          // Lista de competencias
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              physics: const BouncingScrollPhysics(),
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
