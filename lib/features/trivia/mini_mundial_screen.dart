import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';

class _Seleccion {
  final String nombre;
  final String codigoBandera;
  const _Seleccion(this.nombre, this.codigoBandera);
}

const _selecciones = [
  _Seleccion('Argentina', 'ar'),
  _Seleccion('Brasil', 'br'),
  _Seleccion('Uruguay', 'uy'),
  _Seleccion('Paraguay', 'py'),
  _Seleccion('México', 'mx'),
  _Seleccion('Colombia', 'co'),
  _Seleccion('Chile', 'cl'),
  _Seleccion('Francia', 'fr'),
  _Seleccion('Alemania', 'de'),
  _Seleccion('España', 'es'),
  _Seleccion('Italia', 'it'),
  _Seleccion('Portugal', 'pt'),
  _Seleccion('Países Bajos', 'nl'),
  _Seleccion('Bélgica', 'be'),
  _Seleccion('Croacia', 'hr'),
  _Seleccion('Japón', 'jp'),
];

const _formaciones = ['4-4-2', '4-3-3', '5-4-1', '3-4-3', '4-2-3-1'];

class _FormacionInfo {
  final String nombre;
  final String descripcion;
  final IconData icono;
  final List<int> lineas; // jugadores por línea (defensa, medios, ataque...)
  const _FormacionInfo(this.nombre, this.descripcion, this.icono, this.lineas);
}

const _formacionesInfo = [
  _FormacionInfo('4-4-2', 'Equilibrada', Icons.grid_view_rounded, [4, 4, 2]),
  _FormacionInfo('4-3-3', 'Ofensiva', Icons.arrow_upward_rounded, [4, 3, 3]),
  _FormacionInfo('5-4-1', 'Defensiva', Icons.shield_rounded, [5, 4, 1]),
  _FormacionInfo('3-4-3', 'Ataque total', Icons.bolt_rounded, [3, 4, 3]),
  _FormacionInfo('4-2-3-1', 'Creativa', Icons.auto_awesome_rounded, [4, 2, 3, 1]),
];

class _EstiloInfo {
  final String nombre;
  final String descripcion;
  final IconData icono;
  final Color color;
  const _EstiloInfo(this.nombre, this.descripcion, this.icono, this.color);
}

const _estilosInfo = [
  _EstiloInfo('Posesión', 'Controlá el balón', Icons.psychology_rounded, Color(0xFF3B82F6)),
  _EstiloInfo('Contraataque', 'Esperá y explotá', Icons.bolt_rounded, Color(0xFFE8B923)),
  _EstiloInfo('Presión Alta', 'Asfixiá al rival', Icons.local_fire_department_rounded, Color(0xFFE63946)),
  _EstiloInfo('Juego de Bandas', 'Jugá por los costados', Icons.swap_horiz_rounded, Color(0xFF8B5CF6)),
  _EstiloInfo('Defensa Cerrada', 'Cerrá el arco', Icons.shield_rounded, Color(0xFF2E9E5B)),
];

// Para cada estilo, los dos que le gana.
const _vence = {
  'Posesión': ['Contraataque', 'Presión Alta'],
  'Contraataque': ['Presión Alta', 'Juego de Bandas'],
  'Presión Alta': ['Juego de Bandas', 'Defensa Cerrada'],
  'Juego de Bandas': ['Defensa Cerrada', 'Posesión'],
  'Defensa Cerrada': ['Posesión', 'Contraataque'],
};

enum _Fase { bienvenida, eligiendoEquipo, eligiendoJugada, resolviendo, resultado }

class MiniMundialScreen extends StatefulWidget {
  const MiniMundialScreen({super.key});

  @override
  State<MiniMundialScreen> createState() => _MiniMundialScreenState();
}

class _MiniMundialScreenState extends State<MiniMundialScreen> {
  final _random = Random();
  _Fase _fase = _Fase.bienvenida;

  late _Seleccion _miEquipo;
  late _Seleccion _rivalEquipo;
  int _ronda = 1;

  String? _miFormacion;
  String? _miEstilo;
  String? _rivalEstilo;

  String _marcadorTexto = '';
  String _marcadorSorteo = '';
  bool _mostrandoPenales = false;
  bool? _gane;

  // Historial de rondas: true = gané, false = perdí.
  final List<bool> _historialRondas = [];

  Timer? _timer;
  Timer? _timerSorteo;

  @override
  void dispose() {
    _timer?.cancel();
    _timerSorteo?.cancel();
    super.dispose();
  }

  void _empezar() {
    setState(() {
      _historialRondas.clear();
      _ronda = 1;
      _fase = _Fase.eligiendoEquipo;
    });
  }

  void _elegirEquipo(_Seleccion equipo) {
    final restantes = _selecciones.where((s) => s.nombre != equipo.nombre).toList();
    setState(() {
      _miEquipo = equipo;
      _rivalEquipo = restantes[_random.nextInt(restantes.length)];
      _ronda = 1;
      _miFormacion = null;
      _miEstilo = null;
      _historialRondas.clear();
      _fase = _Fase.eligiendoJugada;
    });
  }

  void _jugar() {
    if (_miFormacion == null || _miEstilo == null) return;
    HapticFeedback.lightImpact();

    _rivalEstilo = _estilosInfo[_random.nextInt(_estilosInfo.length)].nombre;
    setState(() {
      _fase = _Fase.resolviendo;
      _marcadorTexto = '';
      _marcadorSorteo = '';
      _mostrandoPenales = false;
      _gane = null;
    });

    // Arrancamos el sorteo visual: cambia números rápido durante 1s.
    _iniciarSorteo();
  }

  void _iniciarSorteo() {
    const opciones = ['1-0', '0-1', '2-1', '1-2', '2-0', '0-2', '1-1', '0-0'];
    int contador = 0;
    _timerSorteo = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      contador++;
      setState(() {
        _marcadorSorteo = opciones[_random.nextInt(opciones.length)];
      });
      if (contador >= 12) {
        timer.cancel();
        _resolverPartido();
      }
    });
  }

  void _resolverPartido() {
    const misGanadores5 = ['1-0', '2-0', '2-1', '3-0', '3-1'];
    const rivalGanadores5 = ['0-1', '0-2', '1-2', '0-3', '1-3'];
    const misGanadores3 = ['1-0', '2-1', '2-0'];
    const rivalGanadores3 = ['0-1', '1-2', '0-2'];
    const empates = ['0-0', '1-1', '2-2'];

    bool? gane;
    String marcador;
    bool esEmpate = false;

    if (_miEstilo == _rivalEstilo) {
      final ganoUsuario = _random.nextBool();
      gane = ganoUsuario;
      marcador = ganoUsuario
          ? misGanadores3[_random.nextInt(3)]
          : rivalGanadores3[_random.nextInt(3)];
    } else if (_vence[_miEstilo]!.contains(_rivalEstilo)) {
      final opcion = _random.nextInt(6);
      if (opcion == 5) {
        esEmpate = true;
        marcador = empates[_random.nextInt(3)];
      } else {
        gane = true;
        marcador = misGanadores5[opcion];
      }
    } else {
      final opcion = _random.nextInt(6);
      if (opcion == 5) {
        esEmpate = true;
        marcador = empates[_random.nextInt(3)];
      } else {
        gane = false;
        marcador = rivalGanadores5[opcion];
      }
    }

    setState(() {
      _marcadorTexto = marcador;
      _gane = gane;
      _marcadorSorteo = '';
    });

    if (esEmpate) {
      _timer = Timer(const Duration(milliseconds: 1300), () {
        if (!mounted) return;
        setState(() => _mostrandoPenales = true);
        _timer = Timer(const Duration(milliseconds: 1300), _resolverPenales);
      });
    } else {
      _timer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _guardarResultadoRonda(gane == true);
        setState(() => _fase = _Fase.resultado);
      });
    }
  }

  void _resolverPenales() {
    const misGanadoresPenal = ['4-3', '5-4', '5-3'];
    const rivalGanadoresPenal = ['3-4', '4-5', '3-5'];

    final ganoUsuario = _random.nextBool();
    setState(() {
      _gane = ganoUsuario;
      _marcadorTexto = ganoUsuario
          ? misGanadoresPenal[_random.nextInt(3)]
          : rivalGanadoresPenal[_random.nextInt(3)];
    });

    _timer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _guardarResultadoRonda(ganoUsuario);
      setState(() => _fase = _Fase.resultado);
    });
  }

  void _guardarResultadoRonda(bool gane) {
    // Ajustamos el historial para que su largo coincida con la ronda actual.
    while (_historialRondas.length < _ronda - 1) {
      _historialRondas.add(true); // relleno por si hubo algún salto
    }
    _historialRondas.add(gane);

    if (gane) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _siguienteRonda() {
    if (_ronda >= 4) return;
    final restantes = _selecciones.where((s) => s.nombre != _miEquipo.nombre).toList();
    setState(() {
      _ronda++;
      _rivalEquipo = restantes[_random.nextInt(restantes.length)];
      _miFormacion = null;
      _miEstilo = null;
      _fase = _Fase.eligiendoJugada;
    });
  }

  void _reiniciarTorneo() {
    setState(() {
      _historialRondas.clear();
      _ronda = 1;
      _fase = _Fase.eligiendoEquipo;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_fase) {
      case _Fase.bienvenida:
        return _vistaBienvenida();
      case _Fase.eligiendoEquipo:
        return _vistaElegirEquipo();
      case _Fase.eligiendoJugada:
        return _vistaElegirJugada();
      case _Fase.resolviendo:
        return _vistaResolviendo();
      case _Fase.resultado:
        return _vistaResultado();
    }
  }

  // ===========================================================================
  // VISTA: BIENVENIDA
  // ===========================================================================

  Widget _vistaBienvenida() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE8B923),
                    const Color(0xFFE8B923).withValues(alpha: 0.65),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8B923).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Mini Mundial',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textoPrincipal,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Elige tu selección y gana 4 rondas para ser campeón',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textoSecundario, height: 1.45),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: superficie,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borde, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _miniInfo('4', 'Rondas'),
                  _separadorInfo(borde),
                  _miniInfo('16', 'Selecciones'),
                  _separadorInfo(borde),
                  _miniInfo('5', 'Estrategias'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _empezar,
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text(
                  'Comenzar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.acento,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  shadowColor: AppColors.acento.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniInfo(String valor, String etiqueta) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textoPrincipal)),
          Text(etiqueta, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textoSecundario, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _separadorInfo(Color borde) {
    return Container(width: 1, height: 28, color: borde);
  }

  // ===========================================================================
  // VISTA: ELEGIR EQUIPO
  // ===========================================================================

  Widget _vistaElegirEquipo() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE8B923).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, size: 20, color: Color(0xFFE8B923)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elige tu selección',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textoPrincipal, letterSpacing: -0.2),
                  ),
                  Text(
                    'Enfrentarás rivales al azar hasta la final',
                    style: TextStyle(fontSize: 12, color: textoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selecciones.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            final s = _selecciones[index];
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _elegirEquipo(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                decoration: BoxDecoration(
                  color: superficie,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borde, width: 0.8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _banderaCircular(s.codigoBandera, size: 34),
                    const SizedBox(height: 8),
                    Text(
                      s.nombre,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textoPrincipal,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // VISTA: ELEGIR JUGADA
  // ===========================================================================

  Widget _vistaElegirJugada() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    final formacionActual = _formacionesInfo.firstWhere(
      (f) => f.nombre == _miFormacion,
      orElse: () => _formacionesInfo.first,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHeaderRonda(textoPrincipal, textoSecundario, borde),

        const SizedBox(height: 18),

        // Matchup: mi equipo vs rival
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: superficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borde, width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _banderaCircular(_miEquipo.codigoBandera, size: 42),
                    const SizedBox(height: 6),
                    Text(
                      _miEquipo.nombre,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textoPrincipal),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'VS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textoSecundario, letterSpacing: 1),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _banderaCircular(_rivalEquipo.codigoBandera, size: 42),
                    const SizedBox(height: 6),
                    Text(
                      _rivalEquipo.nombre,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textoPrincipal),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Mini cancha con la formación
        _buildMiniCancha(formacionActual),

        const SizedBox(height: 22),

        Text('Alineación', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: textoSecundario)),
        const SizedBox(height: 10),
        ..._formacionesInfo.map((f) {
          final elegida = _miFormacion == f.nombre;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _miFormacion = f.nombre);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: elegida ? AppColors.acento.withValues(alpha: 0.10) : superficie,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: elegida ? AppColors.acento : borde,
                    width: elegida ? 1.6 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: elegida ? AppColors.acento : AppColors.acento.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        f.icono,
                        size: 18,
                        color: elegida ? Colors.white : AppColors.acento,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.nombre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: elegida ? AppColors.acento : textoPrincipal,
                            ),
                          ),
                          Text(
                            f.descripcion,
                            style: TextStyle(fontSize: 11, color: textoSecundario),
                          ),
                        ],
                      ),
                    ),
                    if (elegida)
                      const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.acento),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 22),

        Text('Forma de juego', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: textoSecundario)),
        const SizedBox(height: 10),
        ..._estilosInfo.map((e) {
          final elegido = _miEstilo == e.nombre;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _miEstilo = e.nombre);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: elegido ? e.color.withValues(alpha: 0.10) : superficie,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: elegido ? e.color : borde,
                    width: elegido ? 1.6 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: elegido ? e.color : e.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        e.icono,
                        size: 18,
                        color: elegido ? Colors.white : e.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.nombre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: elegido ? e.color : textoPrincipal,
                            ),
                          ),
                          Text(
                            e.descripcion,
                            style: TextStyle(fontSize: 11, color: textoSecundario),
                          ),
                        ],
                      ),
                    ),
                    if (elegido)
                      Icon(Icons.check_circle_rounded, size: 20, color: e.color),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: (_miFormacion != null && _miEstilo != null) ? _jugar : null,
            icon: const Icon(Icons.sports_soccer_rounded, size: 22),
            label: const Text(
              'Jugar partido',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.acento,
              foregroundColor: Colors.white,
              disabledBackgroundColor: borde,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              shadowColor: AppColors.acento.withValues(alpha: 0.45),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRonda(Color textoPrincipal, Color textoSecundario, Color borde) {
    return Row(
      children: [
        // Timeline de rondas
        Expanded(
          child: Row(
            children: List.generate(4, (i) {
              final numeroRonda = i + 1;
              final Color color;
              if (numeroRonda < _ronda) {
                final gane = _historialRondas.length > i ? _historialRondas[i] : false;
                color = gane ? const Color(0xFF2E9E5B) : const Color(0xFFE63946);
              } else if (numeroRonda == _ronda) {
                color = AppColors.acento;
              } else {
                color = borde;
              }
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.acento.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Ronda $_ronda/4',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.acento, letterSpacing: 0.3),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MINI CANCHA
  // ===========================================================================

  Widget _buildMiniCancha(_FormacionInfo formacion) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E7A4A), Color(0xFF0E5A2E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E5A2E).withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Líneas de la cancha
            Positioned.fill(
              child: CustomPaint(painter: _CanchaPainter()),
            ),
            // Jugadores
            ..._construirJugadores(formacion),
          ],
        ),
      ),
    );
  }

  List<Widget> _construirJugadores(_FormacionInfo formacion) {
    final jugadores = <Widget>[];
    final total = formacion.lineas.length;
    // Distribución vertical: defensa abajo, ataque arriba.
    // En la pantalla, "abajo" es y grande y "arriba" es y chico.
    // El arco propio está abajo, el rival arriba.
    for (int i = 0; i < total; i++) {
      final cantidad = formacion.lineas[i];
      // Progreso: 0 = defensa (abajo), 1 = ataque (arriba).
      final progreso = 1 - (i / (total - 1 == 0 ? 1 : total - 1));
      // 0.15 (arriba) a 0.85 (abajo)
      final y = 0.15 + (1 - progreso) * 0.7;

      for (int j = 0; j < cantidad; j++) {
        // Distribuir horizontalmente
        final x = (j + 1) / (cantidad + 1);
        jugadores.add(
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment(x * 2 - 1, y * 2 - 1),
              widthFactor: null,
              heightFactor: null,
              child: Align(
                alignment: Alignment(x * 2 - 1, y * 2 - 1),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: AppColors.acento, width: 2),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return jugadores;
  }

  // ===========================================================================
  // VISTA: RESOLVIENDO
  // ===========================================================================

  Widget _vistaResolviendo() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    final miEstiloInfo = _estilosInfo.firstWhere((e) => e.nombre == _miEstilo);
    final rivalEstiloInfo = _estilosInfo.firstWhere((e) => e.nombre == _rivalEstilo);

    final String marcadorMostrado = _marcadorSorteo.isNotEmpty
        ? _marcadorSorteo
        : (_marcadorTexto.isNotEmpty ? _marcadorTexto : '—');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Matchup con estilos enfrentados
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _banderaCircular(_miEquipo.codigoBandera, size: 56),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: miEstiloInfo.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          miEstiloInfo.nombre,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: miEstiloInfo.color),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'VS',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textoSecundario, letterSpacing: 1),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _banderaCircular(_rivalEquipo.codigoBandera, size: 56),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: rivalEstiloInfo.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          rivalEstiloInfo.nombre,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: rivalEstiloInfo.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Marcador / estado
            if (_mostrandoPenales) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.pro.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_soccer_rounded, size: 18, color: AppColors.pro),
                    const SizedBox(width: 8),
                    Text(
                      'PENALES',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.pro, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                marcadorMostrado,
                style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: textoPrincipal, letterSpacing: 2),
              ),
            ] else if (_marcadorTexto.isEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: superficie,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borde, width: 1),
                ),
                child: Text(
                  marcadorMostrado,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: AppColors.acento.withValues(alpha: 0.55),
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Resolviendo el partido...',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textoSecundario),
              ),
            ] else if (_gane == null) ...[
              Text(
                'EMPATE $_marcadorTexto',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textoPrincipal),
              ),
              const SizedBox(height: 10),
              Text(
                'Se define por penales',
                style: TextStyle(fontSize: 12, color: textoSecundario),
              ),
            ] else ...[
              Text(
                _marcadorTexto,
                style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: textoPrincipal, letterSpacing: 3),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // VISTA: RESULTADO
  // ===========================================================================

  Widget _vistaResultado() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    final esCampeon = _gane == true && _ronda == 4;
    final color = _gane == true ? const Color(0xFF2E9E5B) : const Color(0xFFE63946);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timeline del torneo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final numeroRonda = i + 1;
                final yaJugo = i < _historialRondas.length;
                final gano = yaJugo && _historialRondas[i];
                final esActual = numeroRonda == _ronda;

                Color colorRonda;
                if (yaJugo) {
                  colorRonda = gano ? const Color(0xFF2E9E5B) : const Color(0xFFE63946);
                } else if (esActual) {
                  colorRonda = AppColors.acento;
                } else {
                  colorRonda = borde;
                }

                return Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: colorRonda.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: colorRonda, width: 2),
                          ),
                          child: Center(
                            child: yaJugo
                                ? Icon(
                                    gano ? Icons.check_rounded : Icons.close_rounded,
                                    size: 16,
                                    color: colorRonda,
                                  )
                                : Text(
                                    '$numeroRonda',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colorRonda),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _etiquetaRonda(numeroRonda),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textoSecundario),
                        ),
                      ],
                    ),
                    if (numeroRonda < 4)
                      Container(
                        width: 18,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: yaJugo ? colorRonda.withValues(alpha: 0.4) : borde,
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 30),

            // Ícono/emoji del resultado
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.65)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.40),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: esCampeon
                    ? const Text('🏆', style: TextStyle(fontSize: 52))
                    : Icon(
                        _gane == true ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(height: 22),

            Text(
              esCampeon
                  ? '¡Campeón!'
                  : (_gane == true ? '¡Victoria!' : 'Eliminado'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _marcadorTexto,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textoPrincipal, letterSpacing: 2),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: superficie,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borde, width: 0.8),
              ),
              child: Text(
                esCampeon
                    ? '${_miEquipo.nombre} ganó el Mini Mundial'
                    : (_gane == true
                        ? 'Le ganaste a ${_rivalEquipo.nombre} en ${_etiquetaRonda(_ronda)}'
                        : 'Te eliminó ${_rivalEquipo.nombre} en ${_etiquetaRonda(_ronda)}'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textoSecundario),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: esCampeon
                    ? _reiniciarTorneo
                    : (_gane == true ? _siguienteRonda : _reiniciarTorneo),
                icon: Icon(
                  esCampeon
                      ? Icons.refresh_rounded
                      : (_gane == true ? Icons.arrow_forward_rounded : Icons.replay_rounded),
                  size: 20,
                ),
                label: Text(
                  esCampeon
                      ? 'Jugar de nuevo'
                      : (_gane == true ? 'Siguiente ronda' : 'Intentar de nuevo'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.acento,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  shadowColor: AppColors.acento.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _etiquetaRonda(int ronda) {
    switch (ronda) {
      case 1:
        return 'Octavos';
      case 2:
        return 'Cuartos';
      case 3:
        return 'Semis';
      case 4:
        return 'Final';
      default:
        return 'Ronda $ronda';
    }
  }

  // ===========================================================================
  // BANDERA CIRCULAR
  // ===========================================================================

  Widget _banderaCircular(String codigo, {required double size}) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.grey.withValues(alpha: 0.15),
        child: Image.network(
          'https://flagcdn.com/w80/$codigo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(Icons.flag_rounded, size: size * 0.5, color: Colors.grey),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===========================================================================
// PAINTER DE LA CANCHA
// ===========================================================================

class _CanchaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLineas = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Borde de la cancha (con margen)
    final margen = 12.0;
    final rect = Rect.fromLTWH(margen, margen, size.width - margen * 2, size.height - margen * 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      paintLineas,
    );

    // Línea del medio
    canvas.drawLine(
      Offset(margen, size.height / 2),
      Offset(size.width - margen, size.height / 2),
      paintLineas,
    );

    // Círculo central
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      24,
      paintLineas,
    );

    // Área grande arriba
    final areaAncho = size.width * 0.5;
    final areaAlto = size.height * 0.16;
    final areaTopRect = Rect.fromLTWH(
      (size.width - areaAncho) / 2,
      margen,
      areaAncho,
      areaAlto,
    );
    canvas.drawRect(areaTopRect, paintLineas);

    // Área grande abajo
    final areaBottomRect = Rect.fromLTWH(
      (size.width - areaAncho) / 2,
      size.height - margen - areaAlto,
      areaAncho,
      areaAlto,
    );
    canvas.drawRect(areaBottomRect, paintLineas);

    // Área chica arriba
    final areaChicaAncho = size.width * 0.28;
    final areaChicaAlto = size.height * 0.08;
    final areaChicaTopRect = Rect.fromLTWH(
      (size.width - areaChicaAncho) / 2,
      margen,
      areaChicaAncho,
      areaChicaAlto,
    );
    canvas.drawRect(areaChicaTopRect, paintLineas);

    // Área chica abajo
    final areaChicaBottomRect = Rect.fromLTWH(
      (size.width - areaChicaAncho) / 2,
      size.height - margen - areaChicaAlto,
      areaChicaAncho,
      areaChicaAlto,
    );
    canvas.drawRect(areaChicaBottomRect, paintLineas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}