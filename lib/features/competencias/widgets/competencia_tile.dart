import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/favoritos_state.dart';
import '../data/competencias_data.dart';

class CompetenciaTile extends StatelessWidget {
  final Competencia competencia;
  final VoidCallback onTap;

  const CompetenciaTile({super.key, required this.competencia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borde, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(competencia.nombre, style: const TextStyle(fontSize: 14)),
            ),
            ValueListenableBuilder<Set<String>>(
              valueListenable: favoritosNotifier,
              builder: (context, favoritos, _) {
                final esFavorito = favoritos.contains(competencia.id);
                return IconButton(
                  icon: Icon(
                    esFavorito ? Icons.star : Icons.star_outline,
                    color: esFavorito ? AppColors.acento : Colors.grey,
                  ),
                  onPressed: () => alternarFavorito(competencia.id),
                );
              },
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}