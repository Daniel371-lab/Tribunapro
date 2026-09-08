import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/models/partido.dart';

class PartidoDetailScreen extends StatelessWidget {
  final Partido partido;
  const PartidoDetailScreen({super.key, required this.partido});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    partido.competenciaNombre,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: superficie,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borde, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              partido.equipoLocal,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              partido.finalizado ? (partido.resultado ?? '-') : 'vs',
                              style: TextStyle(fontSize: 14, color: textoSecundario),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              partido.equipoVisitante,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatearFechaCompleta(partido.fecha),
                        style: TextStyle(fontSize: 12, color: textoSecundario),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (partido.finalizado) ...[
                  _seccion(
                    context,
                    titulo: 'Resultado',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (partido.acertado ?? false) ? Icons.check_circle : Icons.cancel,
                          color: (partido.acertado ?? false) ? AppColors.acento : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (partido.acertado ?? false)
                              ? 'La predicción acertó'
                              : 'La predicción no acertó',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ] else if (partido.prediccionGanador != null) ...[
                  _seccion(
                    context,
                    titulo: 'Predicción',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ganador: ${partido.prediccionGanador}', style: const TextStyle(fontSize: 14)),
                        if (partido.prediccionGoles != null) ...[
                          const SizedBox(height: 4),
                          Text('Goles: ${partido.prediccionGoles}', style: const TextStyle(fontSize: 14)),
                        ],
                      ],
                    ),
                  ),
                  if (partido.porcentajeLocal != null) ...[
                    const SizedBox(height: 16),
                    _seccion(
                      context,
                      titulo: 'Probabilidades',
                      child: Row(
                        children: [
                          _probabilidad('Local', partido.porcentajeLocal!, textoSecundario),
                          _probabilidad('Empate', partido.porcentajeEmpate ?? '-', textoSecundario),
                          _probabilidad('Visita', partido.porcentajeVisitante ?? '-', textoSecundario),
                        ],
                      ),
                    ),
                  ],
                  if (partido.consejo != null) ...[
                    const SizedBox(height: 16),
                    _seccion(
                      context,
                      titulo: 'Análisis',
                      child: Text(partido.consejo!, style: TextStyle(fontSize: 13, color: textoSecundario)),
                    ),
                  ],
                ],

                if (partido.corners != null || partido.tarjetas != null) ...[
                  const SizedBox(height: 16),
                  _seccion(
                    context,
                    titulo: 'Corners y tarjetas',
                    child: Row(
                      children: [
                        if (partido.corners != null)
                          Expanded(child: Text('Corners: ${partido.corners}', style: const TextStyle(fontSize: 14))),
                        if (partido.tarjetas != null)
                          Expanded(child: Text('Tarjetas: ${partido.tarjetas}', style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ),
                ],

                if (partido.h2h != null && partido.h2h!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _seccion(
                    context,
                    titulo: 'Enfrentamientos anteriores',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: partido.h2h!
                          .map((linea) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(linea, style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
     ),
   );
 }

  Widget _seccion(BuildContext context, {required String titulo, required Widget child}) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borde, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _probabilidad(String etiqueta, String valor, Color colorSecundario) {
    return Expanded(
      child: Column(
        children: [
          Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(etiqueta, style: TextStyle(fontSize: 11, color: colorSecundario)),
        ],
      ),
    );
  }

  String _formatearFechaCompleta(DateTime fecha) {
    final meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final hora = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    return '${fecha.day} ${meses[fecha.month - 1]} · $hora';
  }
}