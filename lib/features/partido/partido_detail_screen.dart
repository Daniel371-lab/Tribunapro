import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/models/partido.dart';
import '../dashboard/widgets/escudo_imagen.dart';

class PartidoDetailScreen extends StatelessWidget {
  final Partido partido;
  
  const PartidoDetailScreen({super.key, required this.partido});

  @override
  Widget build(BuildContext context) {
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
                      partido.competenciaNombre,
                      style: TextStyle(
                        fontSize: 18,
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

            // Contenido escroleable
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Tarjeta Principal (Marcador con Escudos)
                  _buildMarcadorCard(context),

                  const SizedBox(height: 24),

                  // Sección Resultado o Predicción
                  if (partido.finalizado) ...[
                    _buildSeccion(
                      context,
                      titulo: 'RESULTADO DE LA PREDICCIÓN',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ((partido.acertado ?? false) ? AppColors.acento : AppColors.error).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              (partido.acertado ?? false) ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: (partido.acertado ?? false) ? AppColors.acento : AppColors.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            (partido.acertado ?? false)
                                ? 'La predicción fue correcta'
                                : 'La predicción no acertó',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textoPrincipal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (partido.prediccionGanador != null) ...[
                    _buildSeccion(
                      context,
                      titulo: 'NUESTRA PREDICCIÓN',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _filaDato('Ganador sugerido', partido.prediccionGanador!, textoPrincipal, textoSecundario),
                          if (partido.prediccionGoles != null) ...[
                            const Divider(height: 24, thickness: 0.5),
                            _filaDato('Total de goles', partido.prediccionGoles!, textoPrincipal, textoSecundario),
                          ],
                        ],
                      ),
                    ),
                    
                    if (partido.porcentajeLocal != null) ...[
                      const SizedBox(height: 16),
                      _buildSeccion(
                        context,
                        titulo: 'PROBABILIDADES',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _probabilidad('Local', partido.porcentajeLocal!, textoPrincipal, textoSecundario),
                            Container(width: 1, height: 30, color: textoSecundario.withValues(alpha: 0.2)),
                            _probabilidad('Empate', partido.porcentajeEmpate ?? '-', textoPrincipal, textoSecundario),
                            Container(width: 1, height: 30, color: textoSecundario.withValues(alpha: 0.2)),
                            _probabilidad('Visita', partido.porcentajeVisitante ?? '-', textoPrincipal, textoSecundario),
                          ],
                        ),
                      ),
                    ],
                    
                    if (partido.consejo != null) ...[
                      const SizedBox(height: 16),
                      _buildSeccion(
                        context,
                        titulo: 'ANÁLISIS TÁCTICO',
                        child: Text(
                          partido.consejo!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: textoPrincipal.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ],

                  if (partido.corners != null || partido.tarjetas != null) ...[
                    const SizedBox(height: 16),
                    _buildSeccion(
                      context,
                      titulo: 'CORNERS Y TARJETAS',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (partido.corners != null)
                            _probabilidad('Corners', partido.corners.toString(), textoPrincipal, textoSecundario),
                          if (partido.corners != null && partido.tarjetas != null)
                            Container(width: 1, height: 30, color: textoSecundario.withValues(alpha: 0.2)),
                          if (partido.tarjetas != null)
                            _probabilidad('Tarjetas', partido.tarjetas.toString(), textoPrincipal, textoSecundario),
                        ],
                      ),
                    ),
                  ],

                  if (partido.h2h != null && partido.h2h!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSeccion(
                      context,
                      titulo: 'HISTORIAL RECIENTE (H2H)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(partido.h2h!.length, (index) {
                          final linea = partido.h2h![index];
                          final esUltimo = index == partido.h2h!.length - 1;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  linea,
                                  style: TextStyle(fontSize: 13, color: textoPrincipal),
                                ),
                              ),
                              if (!esUltimo) const Divider(height: 8, thickness: 0.5),
                            ],
                          );
                        }),
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

  // Tarjeta principal del partido (Marcador)
  Widget _buildMarcadorCard(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Equipo Local
              Expanded(
                child: Column(
                  children: [
                    EscudoImagen(url: partido.escudoLocal ?? '', size: 56),
                    const SizedBox(height: 12),
                    Text(
                      partido.equipoLocal,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textoPrincipal,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Marcador / VS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      partido.finalizado ? (partido.resultado ?? '-') : 'VS',
                      style: TextStyle(
                        fontSize: partido.finalizado ? 28 : 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: partido.finalizado ? textoPrincipal : textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),

              // Equipo Visitante
              Expanded(
                child: Column(
                  children: [
                    EscudoImagen(url: partido.escudoVisitante ?? '', size: 56),
                    const SizedBox(height: 12),
                    Text(
                      partido.equipoVisitante,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textoPrincipal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 16),
          
          // Fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: textoSecundario),
              const SizedBox(width: 6),
              Text(
                _formatearFechaCompleta(partido.fecha),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textoSecundario,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(
    BuildContext context, {
    required String titulo,
    required Widget child,
  }) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: textoSecundario,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: superficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borde, width: 0.8),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _filaDato(String etiqueta, String valor, Color colorPrincipal, Color colorSecundario) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: TextStyle(fontSize: 14, color: colorSecundario)),
        Text(valor, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorPrincipal)),
      ],
    );
  }

  Widget _probabilidad(String etiqueta, String valor, Color colorPrincipal, Color colorSecundario) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colorPrincipal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          etiqueta.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: colorSecundario,
          ),
        ),
      ],
    );
  }

  String _formatearFechaCompleta(DateTime fecha) {
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final hora = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    return '${fecha.day} ${meses[fecha.month - 1]} • $hora';
  }
}
