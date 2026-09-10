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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: textoPrincipal,
                      ),
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
                    const SizedBox(height: 18),
                    _buildSeccion(
                      context,
                      titulo: 'Medio tiempo',
                      icono: Icons.timelapse_rounded,
                      child: Center(
                        child: Text(
                          '${partido.medioTiempoLocal} - ${partido.medioTiempoVisitante}',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textoPrincipal),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 26),

                  if (partido.finalizado) ...[
                    _buildSeccion(
                      context,
                      titulo: 'Resultado de la predicción',
                      icono: Icons.fact_check_rounded,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ((partido.acertado ?? false) ? AppColors.acento : AppColors.error).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              (partido.acertado ?? false) ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: (partido.acertado ?? false) ? AppColors.acento : AppColors.error,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              (partido.acertado ?? false) ? 'La predicción fue correcta' : 'La predicción no acertó',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textoPrincipal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (partido.prediccionGanador != null) ...[
                    _buildSeccion(
                      context,
                      titulo: 'Nuestra predicción',
                      icono: Icons.auto_awesome_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _filaDato('Ganador sugerido', partido.prediccionGanador!, textoPrincipal, textoSecundario),
                          if (partido.prediccionGoles != null) ...[
                            const SizedBox(height: 12),
                            _filaDato('Total de goles', partido.prediccionGoles!, textoPrincipal, textoSecundario),
                          ],
                        ],
                      ),
                    ),

                    if (partido.porcentajeLocal != null) ...[
                      const SizedBox(height: 18),
                      _buildSeccion(
                        context,
                        titulo: 'Probabilidades',
                        icono: Icons.pie_chart_rounded,
                        child: _buildBarraProbabilidad(context),
                      ),
                    ],

                    if (partido.consejo != null) ...[
                      const SizedBox(height: 18),
                      _buildSeccion(
                        context,
                        titulo: 'Análisis táctico',
                        icono: Icons.psychology_alt_rounded,
                        child: Text(
                          partido.consejo!,
                          style: TextStyle(fontSize: 14, height: 1.6, color: textoPrincipal.withValues(alpha: 0.92)),
                        ),
                      ),
                    ],
                  ],

                  if (partido.corners != null || partido.tarjetas != null) ...[
                    const SizedBox(height: 18),
                    _buildSeccion(
                      context,
                      titulo: 'Corners y tarjetas',
                      icono: Icons.style_rounded,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (partido.corners != null)
                            _statChip('Corners', partido.corners.toString(), AppColors.acento),
                          if (partido.corners != null && partido.tarjetas != null) const SizedBox(width: 12),
                          if (partido.tarjetas != null)
                            _statChip('Tarjetas', partido.tarjetas.toString(), const Color(0xFFE8B923)),
                        ],
                      ),
                    ),
                  ],

                  if (partido.statsLocal != null || partido.statsVisitante != null) ...[
                    const SizedBox(height: 18),
                    _buildSeccion(
                      context,
                      titulo: 'Estadísticas de temporada',
                      icono: Icons.leaderboard_rounded,
                      child: _buildTablaComparativa(context),
                    ),
                  ],

                  if (partido.h2h != null && partido.h2h!.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _buildTituloSeccion(context, 'Enfrentamientos anteriores', Icons.history_rounded),
                    const SizedBox(height: 10),
                    Column(
                      children: partido.h2h!.map((e) => _buildFilaH2H(context, e)).toList(),
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

  BoxShadow _sombra(bool esOscuro) {
    return BoxShadow(
      color: (esOscuro ? Colors.black : const Color(0xFF1A1A1A)).withValues(alpha: esOscuro ? 0.45 : 0.07),
      blurRadius: 20,
      offset: const Offset(0, 8),
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
          colors: esOscuro
              ? [acentoActual.withValues(alpha: 0.22), superficie]
              : [acentoActual.withValues(alpha: 0.16), Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [_sombra(esOscuro)],
      ),
      child: Column(
        children: [
          if (partido.jornada != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: acentoActual,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'JORNADA ${partido.jornada}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          EscudoImagen(url: partido.escudoLocal ?? '', size: 60),
                          const SizedBox(height: 14),
                          Text(
                            partido.equipoLocal,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textoPrincipal),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        partido.finalizado ? (partido.resultado ?? '-') : 'VS',
                        style: TextStyle(
                          fontSize: partido.finalizado ? 32 : 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: partido.finalizado ? acentoActual : textoSecundario,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          EscudoImagen(url: partido.escudoVisitante ?? '', size: 60),
                          const SizedBox(height: 14),
                          Text(
                            partido.equipoVisitante,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textoPrincipal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: textoSecundario),
                    const SizedBox(width: 6),
                    Text(
                      _formatearFechaCompleta(partido.fecha),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textoSecundario),
                    ),
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

    final local = _extraerNumero(partido.porcentajeLocal);
    final empate = _extraerNumero(partido.porcentajeEmpate);
    final visitante = _extraerNumero(partido.porcentajeVisitante);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                Expanded(flex: (local * 10).round().clamp(1, 1000), child: Container(color: acentoActual)),
                Expanded(flex: (empate * 10).round().clamp(1, 1000), child: Container(color: const Color(0xFFE8B923))),
                Expanded(flex: (visitante * 10).round().clamp(1, 1000), child: Container(color: AppColors.error)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _leyendaProbabilidad('Local', partido.porcentajeLocal ?? '-', acentoActual, textoPrincipal, textoSecundario),
            _leyendaProbabilidad('Empate', partido.porcentajeEmpate ?? '-', const Color(0xFFE8B923), textoPrincipal, textoSecundario),
            _leyendaProbabilidad('Visita', partido.porcentajeVisitante ?? '-', AppColors.error, textoPrincipal, textoSecundario),
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
            Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(valor, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorPrincipal)),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          etiqueta.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: colorSecundario),
        ),
      ],
    );
  }

  double _extraerNumero(String? valor) {
    if (valor == null) return 0;
    return double.tryParse(valor.replaceAll('%', '').trim()) ?? 0;
  }

  Widget _statChip(String etiqueta, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(
              etiqueta.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: color.withValues(alpha: 0.85)),
            ),
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
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: destacada ? acentoActual.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatearValor(etiqueta, valorLocal),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textoPrincipal),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  etiqueta.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.4, color: textoSecundario),
                ),
              ),
              Expanded(
                child: Text(
                  _formatearValor(etiqueta, valorVisitante),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textoPrincipal),
                ),
              ),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [_sombra(esOscuro)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              enfrentamiento.equipoLocal,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textoPrincipal),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: acentoActual,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${enfrentamiento.golesLocal} - ${enfrentamiento.golesVisitante}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          Expanded(
            child: Text(
              enfrentamiento.equipoVisitante,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textoPrincipal),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTituloSeccion(BuildContext context, String titulo, IconData icono) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final acentoActual = esOscuro ? AppColors.acentoOscuro : AppColors.acento;

    return Row(
      children: [
        Icon(icono, size: 16, color: acentoActual),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: textoPrincipal),
        ),
      ],
    );
  }

  Widget _buildSeccion(BuildContext context, {required String titulo, required IconData icono, required Widget child}) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTituloSeccion(context, titulo, icono),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: superficie,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [_sombra(esOscuro)],
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
        Text(valor, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorPrincipal)),
      ],
    );
  }

  String _formatearFechaCompleta(DateTime fecha) {
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final hora = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    return '${fecha.day} ${meses[fecha.month - 1]} • $hora';
  }
}