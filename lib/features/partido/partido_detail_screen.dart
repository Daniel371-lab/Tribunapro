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
    final fondo = esOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textoPrincipal),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      partido.competenciaNombre,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: textoPrincipal),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMarcadorCard(context),

                  if (partido.medioTiempoLocal != null && partido.medioTiempoVisitante != null) ...[
                    const SizedBox(height: 14),
                    _buildSeccion(
                      context,
                      titulo: 'Medio tiempo',
                      child: Center(
                        child: Text(
                          '${partido.medioTiempoLocal} - ${partido.medioTiempoVisitante}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textoPrincipal),
                        ),
                      ),
                    ),
                  ],

                  if (partido.predicciones != null && partido.predicciones!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildTituloSeccion(context, partido.finalizado ? 'Predicciones y resultado' : 'Nuestras predicciones'),
                    const SizedBox(height: 10),
                    _buildCardPredicciones(context),
                    if (partido.muestraChica && !partido.finalizado) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: textoSecundario),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Inicio de temporada: las estadísticas todavía son limitadas.',
                              style: TextStyle(fontSize: 11, color: textoSecundario),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],

                  if (partido.porcentajeLocal != null) ...[
                    const SizedBox(height: 18),
                    _buildSeccion(
                      context,
                      titulo: 'Probabilidades',
                      child: _buildBarraProbabilidad(context),
                    ),
                  ],

                  if (partido.corners != null || partido.tarjetas != null) ...[
                    const SizedBox(height: 18),
                    _buildSeccion(
                      context,
                      titulo: 'Corners y tarjetas',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (partido.corners != null) _statChip('Corners', partido.corners.toString(), AppColors.acento),
                          if (partido.corners != null && partido.tarjetas != null) const SizedBox(width: 12),
                          if (partido.tarjetas != null) _statChip('Tarjetas', partido.tarjetas.toString(), const Color(0xFFE8B923)),
                        ],
                      ),
                    ),
                  ],

                  if (partido.statsLocal != null || partido.statsVisitante != null) ...[
                    const SizedBox(height: 18),
                    _buildSeccion(context, titulo: 'Estadísticas de temporada', child: _buildTablaComparativa(context)),
                  ],

                  if (partido.h2h != null && partido.h2h!.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _buildTituloSeccion(context, 'Enfrentamientos anteriores'),
                    const SizedBox(height: 10),
                    Column(children: partido.h2h!.map((e) => _buildFilaH2H(context, e)).toList()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPredicciones(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    final items = partido.predicciones!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [_sombra(esOscuro)],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final esUltimo = index == items.length - 1;
          final mostrarEstado = partido.finalizado && item.cumplida != null;
          final acerto = item.cumplida == true;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    if (mostrarEstado) ...[
                      Icon(
                        acerto ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 18,
                        color: acerto ? AppColors.acento : AppColors.error,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        item.texto,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: mostrarEstado
                              ? (acerto ? AppColors.acento : AppColors.error)
                              : textoPrincipal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!esUltimo) Divider(height: 1, thickness: 0.5, color: textoSecundario.withValues(alpha: 0.15)),
            ],
          );
        }),
      ),
    );
  }

  BoxShadow _sombra(bool esOscuro) {
    return BoxShadow(
      color: (esOscuro ? Colors.black : const Color(0xFF1A1A1A)).withValues(alpha: esOscuro ? 0.4 : 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    );
  }

  Widget _buildMarcadorCard(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final acentoActual = esOscuro ? AppColors.acentoOscuro : AppColors.acento;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: esOscuro ? [acentoActual.withValues(alpha: 0.2), superficie] : [acentoActual.withValues(alpha: 0.14), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [_sombra(esOscuro)],
      ),
      child: Column(
        children: [
          if (partido.jornada != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: acentoActual, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'JORNADA ${partido.jornada}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.white),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          EscudoImagen(url: partido.escudoLocal ?? '', size: 42),
                          const SizedBox(height: 8),
                          Text(
                            partido.equipoLocal,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textoPrincipal),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        partido.finalizado ? (partido.resultado ?? '-') : 'VS',
                        style: TextStyle(
                          fontSize: partido.finalizado ? 22 : 16,
                          fontWeight: FontWeight.w900,
                          color: partido.finalizado ? acentoActual : textoSecundario,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          EscudoImagen(url: partido.escudoVisitante ?? '', size: 42),
                          const SizedBox(height: 8),
                          Text(
                            partido.equipoVisitante,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textoPrincipal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: textoSecundario),
                    const SizedBox(width: 5),
                    Text(_formatearFechaCompleta(partido.fecha), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textoSecundario)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraProbabilidad(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final acentoActual = esOscuro ? AppColors.acentoOscuro : AppColors.acento;

    final local = partido.porcentajeLocal ?? 0;
    final empate = partido.porcentajeEmpate ?? 0;
    final visitante = partido.porcentajeVisitante ?? 0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(flex: (local * 10).clamp(1, 1000), child: Container(color: acentoActual)),
                Expanded(flex: (empate * 10).clamp(1, 1000), child: Container(color: const Color(0xFFE8B923))),
                Expanded(flex: (visitante * 10).clamp(1, 1000), child: Container(color: AppColors.error)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _leyendaProbabilidad('Local', '$local%', acentoActual, textoPrincipal, textoSecundario),
            _leyendaProbabilidad('Empate', '$empate%', const Color(0xFFE8B923), textoPrincipal, textoSecundario),
            _leyendaProbabilidad('Visita', '$visitante%', AppColors.error, textoPrincipal, textoSecundario),
          ],
        ),
      ],
    );
  }

  Widget _leyendaProbabilidad(String etiqueta, String valor, Color color, Color colorPrincipal, Color colorSecundario) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(valor, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorPrincipal)),
          ],
        ),
        const SizedBox(height: 2),
        Text(etiqueta.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: colorSecundario)),
      ],
    );
  }

  Widget _statChip(String etiqueta, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 3),
            Text(etiqueta.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: color.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaComparativa(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final acentoActual = esOscuro ? AppColors.acentoOscuro : AppColors.acento;

    final local = partido.statsLocal;
    final visitante = partido.statsVisitante;

    final filas = <(String, int?, int?)>[
      ('Posición', local?.posicion, visitante?.posicion),
      ('Puntos', local?.puntos, visitante?.puntos),
      ('Partidos jugados', local?.partidosJugados, visitante?.partidosJugados),
      ('Ganados', local?.ganados, visitante?.ganados),
      ('Empatados', local?.empatados, visitante?.empatados),
      ('Perdidos', local?.perdidos, visitante?.perdidos),
      ('Goles a favor', local?.golesFavor, visitante?.golesFavor),
      ('Goles en contra', local?.golesContra, visitante?.golesContra),
      ('Diferencia de gol', local?.diferenciaGol, visitante?.diferenciaGol),
    ];

    return Column(
      children: List.generate(filas.length, (index) {
        final (etiqueta, valorLocal, valorVisitante) = filas[index];
        final destacada = index.isEven;
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(color: destacada ? acentoActual.withValues(alpha: 0.06) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(child: Text(_formatearValor(etiqueta, valorLocal), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textoPrincipal))),
              Expanded(flex: 2, child: Text(etiqueta.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.3, color: textoSecundario))),
              Expanded(child: Text(_formatearValor(etiqueta, valorVisitante), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textoPrincipal))),
            ],
          ),
        );
      }),
    );
  }

  String _formatearValor(String etiqueta, int? valor) {
    if (valor == null) return '-';
    if (etiqueta == 'Diferencia de gol' && valor > 0) return '+$valor';
    return '$valor';
  }

  Widget _buildFilaH2H(BuildContext context, EnfrentamientoH2H enfrentamiento) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final acentoActual = esOscuro ? AppColors.acentoOscuro : AppColors.acento;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(14), boxShadow: [_sombra(esOscuro)]),
      child: Row(
        children: [
          Expanded(child: Text(enfrentamiento.equipoLocal, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textoPrincipal), overflow: TextOverflow.ellipsis)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: acentoActual, borderRadius: BorderRadius.circular(8)),
            child: Text('${enfrentamiento.golesLocal} - ${enfrentamiento.golesVisitante}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Expanded(child: Text(enfrentamiento.equipoVisitante, textAlign: TextAlign.end, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textoPrincipal), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildTituloSeccion(BuildContext context, String titulo) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    return Text(titulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: textoPrincipal));
  }

  Widget _buildSeccion(BuildContext context, {required String titulo, required Widget child}) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTituloSeccion(context, titulo),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(16), boxShadow: [_sombra(esOscuro)]),
          child: child,
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