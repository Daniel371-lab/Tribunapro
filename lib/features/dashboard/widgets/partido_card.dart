import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/partido.dart';
import 'escudo_imagen.dart';

class PartidoCard extends StatelessWidget {
  final Partido partido;
  final VoidCallback onTap;

  const PartidoCard({
    super.key,
    required this.partido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final acentoActual = esOscuro ? AppColors.acentoOscuro : AppColors.acento;

    // Pill de competencia en gris medio para que destaque sobre la card blanca.
    final colorPill = esOscuro
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE0E0E0);

    final Color colorLateral;
    if (partido.finalizado) {
      colorLateral = textoSecundario.withValues(alpha: 0.35);
    } else if (partido.esPro) {
      colorLateral = const Color(0xFFE8B923);
    } else {
      colorLateral = acentoActual;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (esOscuro ? Colors.black : const Color(0xFF1A1A1A))
                .withValues(alpha: esOscuro ? 0.35 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: colorLateral),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fila superior: pill de competencia + PRO a la izquierda
                          // (se ajustan a su contenido), fecha anclada a la derecha.
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: colorPill,
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: Text(
                                          partido.competenciaNombre.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.7,
                                            color: acentoActual,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                    if (partido.esPro) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.pro,
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: const Text(
                                          'PRO',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                partido.finalizado ? 'FINALIZADO' : _formatearDiaHora(partido.fecha),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: partido.finalizado ? acentoActual : textoSecundario,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    EscudoImagen(url: partido.escudoLocal ?? '', size: 26),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        partido.equipoLocal,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textoPrincipal,
                                          height: 1.1,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  partido.finalizado ? (partido.resultado ?? '-') : 'VS',
                                  style: TextStyle(
                                    fontSize: partido.finalizado ? 16 : 11,
                                    fontWeight: partido.finalizado
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    color: partido.finalizado ? acentoActual : textoSecundario,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        partido.equipoVisitante,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textoPrincipal,
                                          height: 1.1,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    EscudoImagen(url: partido.escudoVisitante ?? '', size: 26),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatearDiaHora(DateTime fecha) {
    const dias = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM'];
    final dia = dias[fecha.weekday - 1];
    final hora = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    return '$dia/$hora';
  }
}