import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';

class CompetenciasScreen extends StatelessWidget {
  const CompetenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Competencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _CompetenciaTipoCard(
              titulo: 'Ligas',
              subtitulo: 'Las 5 grandes de Europa, Brasil, Argentina, Paraguay, MLS y Liga MX',
              icono: Icons.flag_outlined,
              onTap: () => context.push('/competencias/ligas'),
            ),
            const SizedBox(height: 12),
            _CompetenciaTipoCard(
              titulo: 'Copas',
              subtitulo: 'Champions, Europa League, Libertadores y Sudamericana',
              icono: Icons.emoji_events_outlined,
              onTap: () => context.push('/competencias/copas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetenciaTipoCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final VoidCallback onTap;

  const _CompetenciaTipoCard({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borde, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icono, color: AppColors.acento, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitulo, style: TextStyle(fontSize: 12, color: textoSecundario)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textoSecundario),
          ],
        ),
      ),
    );
  }
}