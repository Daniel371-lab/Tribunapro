import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/favoritos_state.dart';
import '../../dashboard/widgets/escudo_imagen.dart';
import '../data/competencias_data.dart';

class CompetenciaTile extends StatelessWidget {
  final Competencia competencia;
  final VoidCallback onTap;

  const CompetenciaTile({super.key, required this.competencia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                EscudoImagen(url: competencia.escudo, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    competencia.nombre,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textoPrincipal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
        ),
      ),
    );
  }
}