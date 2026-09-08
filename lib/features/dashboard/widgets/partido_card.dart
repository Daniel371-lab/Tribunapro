import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/partido.dart';

class PartidoCard extends StatelessWidget {
  final Partido partido;
  final VoidCallback? onTap;
  const PartidoCard({super.key, required this.partido, this.onTap});

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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borde, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${partido.competenciaNombre} · ${_formatearFecha(partido.fecha)}',
                    style: TextStyle(fontSize: 11, color: textoSecundario),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (partido.esPro && !partido.finalizado) _badgePro(),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(partido.equipoLocal, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    partido.finalizado ? (partido.resultado ?? 'vs') : 'vs',
                    style: TextStyle(fontSize: 12, color: textoSecundario),
                  ),
                ),
                Expanded(
                  child: Text(
                    partido.equipoVisitante,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (partido.finalizado || partido.prediccionGanador != null) ...[
              const SizedBox(height: 10),
              if (partido.finalizado) _chipResultado() else _filaPrediccion(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filaPrediccion() {
    return Row(
      children: [
        Expanded(child: _chip(partido.prediccionGanador!)),
        if (partido.prediccionGoles != null) ...[
          const SizedBox(width: 8),
          Expanded(child: _chip(partido.prediccionGoles!, esSecundario: true)),
        ],
      ],
    );
  }

  Widget _chipResultado() {
    final acerto = partido.acertado ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (acerto ? AppColors.acento : AppColors.error).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(acerto ? Icons.check : Icons.close, size: 14, color: acerto ? AppColors.acento : AppColors.error),
          const SizedBox(width: 4),
          Text(
            acerto ? 'Acertado' : 'Errado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: acerto ? AppColors.acento : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgePro() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.proBg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.lock_outline, size: 11, color: AppColors.pro),
          SizedBox(width: 3),
          Text('Pro', style: TextStyle(fontSize: 11, color: AppColors.pro, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _chip(String texto, {bool esSecundario = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: esSecundario ? Colors.grey.withValues(alpha: 0.1) : AppColors.acento.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: esSecundario ? Colors.grey.shade700 : AppColors.acento,
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final esHoy = fecha.year == ahora.year && fecha.month == ahora.month && fecha.day == ahora.day;
    final hora = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    return esHoy ? 'Hoy $hora' : 'Mañana $hora';
  }
}