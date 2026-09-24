import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';

// ============================================================================
// MODELOS
// ============================================================================

class _Seleccion {
  final String nombre;
  final String codigoBandera;
  const _Seleccion(this.nombre, this.codigoBandera);
}

class _FormacionInfo {
  final String nombre;
  final int ataque;
  final int defensa;
  final String descripcion;
  final IconData icono;
  const _FormacionInfo(this.nombre, this.ataque, this.defensa, this.descripcion, this.icono);
}

class _EstiloInfo {
  final String nombre;
  final int ataqueBonus;
  final int defensaBonus;
  final String descripcion;
  final IconData icono;
  final Color color;
  const _EstiloInfo(this.nombre, this.ataqueBonus, this.defensaBonus, this.descripcion, this.icono, this.color);
}

enum _ResultadoTurno { golMio, golRival, nada }
enum _Fase { bienvenida, eligiendoEquipo, jugandoTurno, revelandoTurno, penales, resultado }
enum _ZonaPenal { izquierda, centro, derecha }

class _DetallePenal {
  final bool esMio;
  final bool fueGol;
  final _ZonaPenal tiro;
  final _ZonaPenal arquero;
  const _DetallePenal({required this.esMio, required this.fueGol, required this.tiro, required this.arquero});
}

// ============================================================================
// DATOS
// ============================================================================

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

const _formaciones = [
  _FormacionInfo('4-4-2', 5, 5, 'Equilibrada', Icons.grid_view_rounded),
  _FormacionInfo('4-3-3', 7, 3, 'Ofensiva', Icons.arrow_upward_rounded),
  _FormacionInfo('5-4-1', 3, 7, 'Defensiva', Icons.shield_rounded),
  _FormacionInfo('3-4-3', 8, 2, 'Ataque total', Icons.bolt_rounded),
  _FormacionInfo('4-2-3-1', 6, 4, 'Creativa', Icons.auto_awesome_rounded),
];

const _estilos = [
  _EstiloInfo('Posesión', 2, 1, 'Controlá el balón', Icons.psychology_rounded, Color(0xFF3B82F6)),
  _EstiloInfo('Contraataque', 1, 2, 'Esperá y explotá', Icons.bolt_rounded, Color(0xFFE8B923)),
  _EstiloInfo('Presión Alta', 3, 0, 'Asfixiá al rival', Icons.local_fire_department_rounded, Color(0xFFE63946)),
  _EstiloInfo('Juego de Bandas', 2, 0, 'Jugá por los costados', Icons.swap_horiz_rounded, Color(0xFF8B5CF6)),
  _EstiloInfo('Defensa Cerrada', 0, 3, 'Cerrá el arco', Icons.shield_rounded, Color(0xFF2E9E5B)),
];

// ============================================================================
// WIDGET
// ============================================================================

class MiniMundialScreen extends StatefulWidget {
  const MiniMundialScreen({super.key});

  @override
  State<MiniMundialScreen> createState() => _MiniMundialScreenState();
}

class _MiniMundialScreenState extends State<MiniMundialScreen> {
  final _random = Random();

  // ---- Flujo general ----
  _Fase _fase = _Fase.bienvenida;
  _Seleccion? _miEquipo;
  _Seleccion? _rivalEquipo;
  int _ronda = 1;
  final List<bool> _historialRondas = [];

  // ---- Partido ----
  int _golesMi = 0;
  int _golesRival = 0;
  List<int> _minutosClave = [];
  int _indiceTurno = 0;

  // ---- Turno actual ----
  _FormacionInfo? _miFormacionTurno;
  _EstiloInfo? _miEstiloTurno;
  _FormacionInfo? _rivalFormacionTurno;
  _EstiloInfo? _rivalEstiloTurno;
  _ResultadoTurno? _resultadoTurnoActual;

  // ---- Penales ----
  int _penalesMi = 0;
  int _penalesRival = 0;
  int _tirosMi = 0;
  int _tirosRival = 0;
  bool _esTurnoMio = true;
  bool _esMuerteSubita = false;
  final List<_DetallePenal> _detallesPenales = [];

  // ---- Timers ----
  Timer? _timerAnimacion;

  @override
  void dispose() {
    _timerAnimacion?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // GENERADOR DE MINUTOS
  // ---------------------------------------------------------------------------

  List<int> _generarMinutos() {
    // 3 en el primer tiempo (1-45) + 3 en el segundo (46-90), ordenados.
    final primerTiempo = List.generate(3, (_) => 5 + _random.nextInt(40)).toList()..sort();
    final segundoTiempo = List.generate(3, (_) => 50 + _random.nextInt(40)).toList()..sort();
    return [...primerTiempo, ...segundoTiempo];
  }

  // ---------------------------------------------------------------------------
  // FLUJO DE FASES
  // ---------------------------------------------------------------------------

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
      _historialRondas.clear();
      _iniciarPartido();
    });
  }

  void _iniciarPartido() {
    _golesMi = 0;
    _golesRival = 0;
    _minutosClave = _generarMinutos();
    _indiceTurno = 0;
    _miFormacionTurno = null;
    _miEstiloTurno = null;
    _rivalFormacionTurno = null;
    _rivalEstiloTurno = null;
    _resultadoTurnoActual = null;
    _fase = _Fase.jugandoTurno;
  }

  void _confirmarTurno() {
    if (_miFormacionTurno == null || _miEstiloTurno == null) return;
    HapticFeedback.selectionClick();

    // El rival elige al azar en simultáneo (Opción A: a ciegas).
    final rivalForm = _formaciones[_random.nextInt(_formaciones.length)];
    final rivalEst = _estilos[_random.nextInt(_estilos.length)];

    // Resolvemos el turno.
    final resultado = _resolverTurno(_miFormacionTurno!, _miEstiloTurno!, rivalForm, rivalEst);

    setState(() {
      _rivalFormacionTurno = rivalForm;
      _rivalEstiloTurno = rivalEst;
      _resultadoTurnoActual = resultado;
      _fase = _Fase.revelandoTurno;

      if (resultado == _ResultadoTurno.golMio) {
        _golesMi++;
        HapticFeedback.mediumImpact();
      } else if (resultado == _ResultadoTurno.golRival) {
        _golesRival++;
        HapticFeedback.heavyImpact();
      }
    });

    // Después de 2.2s pasamos al siguiente turno o al final.
    _timerAnimacion = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _avanzarTurno();
    });
  }

  void _avanzarTurno() {
    if (_indiceTurno >= 5) {
      _terminarPartido();
      return;
    }
    setState(() {
      _indiceTurno++;
      _miFormacionTurno = null;
      _miEstiloTurno = null;
      _rivalFormacionTurno = null;
      _rivalEstiloTurno = null;
      _resultadoTurnoActual = null;
      _fase = _Fase.jugandoTurno;
    });
  }

  void _terminarPartido() {
    final gane = _golesMi > _golesRival;
    final empate = _golesMi == _golesRival;

    if (empate) {
      // Arrancamos penales.
      setState(() {
        _penalesMi = 0;
        _penalesRival = 0;
        _tirosMi = 0;
        _tirosRival = 0;
        _esTurnoMio = true;
        _esMuerteSubita = false;
        _detallesPenales.clear();
        _fase = _Fase.penales;
      });
      return;
    }

    _guardarResultadoRonda(gane);
    setState(() => _fase = _Fase.resultado);
  }

  void _guardarResultadoRonda(bool gane) {
    while (_historialRondas.length < _ronda - 1) {
      _historialRondas.add(true);
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
    final restantes = _selecciones.where((s) => s.nombre != _miEquipo!.nombre).toList();
    setState(() {
      _ronda++;
      _rivalEquipo = restantes[_random.nextInt(restantes.length)];
      _iniciarPartido();
    });
  }

  void _reiniciarTorneo() {
    setState(() {
      _historialRondas.clear();
      _ronda = 1;
      _fase = _Fase.eligiendoEquipo;
    });
  }

  // ---------------------------------------------------------------------------
  // LÓGICA DEL TURNO
  // ---------------------------------------------------------------------------

  _ResultadoTurno _resolverTurno(
    _FormacionInfo miForm,
    _EstiloInfo miEst,
    _FormacionInfo rivalForm,
    _EstiloInfo rivalEst,
  ) {
    final miAtaque = miForm.ataque + miEst.ataqueBonus;
    final miDefensa = miForm.defensa + miEst.defensaBonus;
    final rivalAtaque = rivalForm.ataque + rivalEst.ataqueBonus;
    final rivalDefensa = rivalForm.defensa + rivalEst.defensaBonus;

    final miAtaqueNeto = miAtaque - rivalDefensa;
    final rivalAtaqueNeto = rivalAtaque - miDefensa;

    // Si están iguales en ataque neto.
    if (miAtaqueNeto == rivalAtaqueNeto) {
      if (miAtaqueNeto >= 2) {
        // Desempate por ataque bruto.
        if (miAtaque > rivalAtaque) return _ResultadoTurno.golMio;
        if (rivalAtaque > miAtaque) return _ResultadoTurno.golRival;
      }
      return _ResultadoTurno.nada;
    }

    // Uno tiene más ataque neto que el otro.
    if (miAtaqueNeto > rivalAtaqueNeto && miAtaqueNeto >= 2) {
      return _ResultadoTurno.golMio;
    }
    if (rivalAtaqueNeto > miAtaqueNeto && rivalAtaqueNeto >= 2) {
      return _ResultadoTurno.golRival;
    }

    return _ResultadoTurno.nada;
  }

  // ---------------------------------------------------------------------------
  // PENALES
  // ---------------------------------------------------------------------------

  // El usuario eligió dónde patear (o dónde se tira su arquero).
  void _resolverPenal(_ZonaPenal miEleccion) {
    HapticFeedback.selectionClick();

    if (_esTurnoMio) {
      // Yo pateo, el arquero rival se tira al azar.
      final arqueroRival = _ZonaPenal.values[_random.nextInt(3)];
      final esGol = arqueroRival != miEleccion;
      if (esGol) _penalesMi++;
      _tirosMi++;
      _detallesPenales.add(_DetallePenal(
        esMio: true,
        fueGol: esGol,
        tiro: miEleccion,
        arquero: arqueroRival,
      ));
      if (esGol) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    } else {
      // El rival patea, yo elijo dónde se tira mi arquero.
      final tiroRival = _ZonaPenal.values[_random.nextInt(3)];
      final esGol = tiroRival != miEleccion;
      if (esGol) _penalesRival++;
      _tirosRival++;
      _detallesPenales.add(_DetallePenal(
        esMio: false,
        fueGol: esGol,
        tiro: tiroRival,
        arquero: miEleccion,
      ));
      if (!esGol) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    }

    setState(() {});

    // Después de 1.5s, revisamos si continuamos o terminamos.
    _timerAnimacion = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _avanzarPenal();
    });
  }

  void _avanzarPenal() {
    // ¿Terminó la tanda regular de 5?
    if (!_esMuerteSubita && _tirosMi >= 5 && _tirosRival >= 5) {
      if (_penalesMi != _penalesRival) {
        // Alguien ganó.
        _terminarPenales();
        return;
      }
      // Empate: pasamos a muerte súbita.
      setState(() => _esMuerteSubita = true);
    }

    // ¿Es la muerte súbita y se sacaron ventaja?
    if (_esMuerteSubita) {
      // En muerte súbita se patea uno y otro, así que se define cuando
      // ambos patearon y hay diferencia.
      if (_tirosMi == _tirosRival && _penalesMi != _penalesRival) {
        _terminarPenales();
        return;
      }
      // ¿Quién patea ahora?
      if (_tirosMi == _tirosRival) {
        setState(() => _esTurnoMio = true);
      } else {
        setState(() => _esTurnoMio = false);
      }
      return;
    }

    // Tanda regular: alternamos entre yo y el rival.
    setState(() => _esTurnoMio = !_esTurnoMio);
  }

  void _terminarPenales() {
    final gane = _penalesMi > _penalesRival;
    _guardarResultadoRonda(gane);
    setState(() => _fase = _Fase.resultado);
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    switch (_fase) {
      case _Fase.bienvenida:
        return _vistaBienvenida();
      case _Fase.eligiendoEquipo:
        return _vistaElegirEquipo();
      case _Fase.jugandoTurno:
      case _Fase.revelandoTurno:
        return _vistaPartidoEnVivo();
      case _Fase.penales:
        return _vistaPenales();
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8B923), Color(0xFFB58A0F)],
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
                  _miniInfo('4', 'Rondas', textoPrincipal, textoSecundario),
                  Container(width: 1, height: 28, color: borde),
                  _miniInfo('6', 'Momentos', textoPrincipal, textoSecundario),
                  Container(width: 1, height: 28, color: borde),
                  _miniInfo('5', 'Estrategias', textoPrincipal, textoSecundario),
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

  Widget _miniInfo(String valor, String etiqueta, Color textoPrincipal, Color textoSecundario) {
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
  // VISTA: PARTIDO EN VIVO (turno a turno)
  // ===========================================================================

  Widget _vistaPartidoEnVivo() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = esOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;

    return Column(
      children: [
        _buildHeaderPartido(),
        Expanded(
          child: Container(
            color: fondo,
            child: _fase == _Fase.jugandoTurno ? _buildPanelTurno() : _buildPanelRevelacion(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderPartido() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    final minutoActual = _minutosClave.length > _indiceTurno ? _minutosClave[_indiceTurno] : 90;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: superficie,
        border: Border(bottom: BorderSide(color: borde, width: 0.8)),
      ),
      child: Column(
        children: [
          // Marcador
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _banderaCircular(_miEquipo!.codigoBandera, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _miEquipo!.nombre,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textoPrincipal),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: esOscuro ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_golesMi - $_golesRival',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textoPrincipal, letterSpacing: 2),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        _rivalEquipo!.nombre,
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textoPrincipal),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _banderaCircular(_rivalEquipo!.codigoBandera, size: 28),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Reloj / momento
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: textoSecundario),
              const SizedBox(width: 6),
              Text(
                minutoActual == 90 ? 'FIN DEL PARTIDO' : "Minuto $minutoActual · Ronda $_ronda de 4",
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textoSecundario, letterSpacing: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanelTurno() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final minutoActual = _minutosClave[_indiceTurno];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.acento.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MINUTO $minutoActual',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.acento, letterSpacing: 0.6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Momento clave del partido',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textoSecundario),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Formaciones
          Text('Formación', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: textoSecundario)),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _formaciones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final f = _formaciones[i];
                final elegida = _miFormacionTurno?.nombre == f.nombre;
                return _buildCardOpcion(
                  seleccionada: elegida,
                  color: AppColors.acento,
                  icono: f.icono,
                  titulo: f.nombre,
                  subtitulo: f.descripcion,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _miFormacionTurno = f);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Estilos
          Text('Forma de juego', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: textoSecundario)),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _estilos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final e = _estilos[i];
                final elegida = _miEstiloTurno?.nombre == e.nombre;
                return _buildCardOpcion(
                  seleccionada: elegida,
                  color: e.color,
                  icono: e.icono,
                  titulo: e.nombre,
                  subtitulo: e.descripcion,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _miEstiloTurno = e);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: (_miFormacionTurno != null && _miEstiloTurno != null) ? _confirmarTurno : null,
              icon: const Icon(Icons.sports_soccer_rounded, size: 22),
              label: const Text(
                'Confirmar jugada',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.acento,
                foregroundColor: Colors.white,
                disabledBackgroundColor: esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                shadowColor: AppColors.acento.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardOpcion({
    required bool seleccionada,
    required Color color,
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionada ? color.withValues(alpha: 0.10) : superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionada ? color : borde,
            width: seleccionada ? 1.8 : 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: seleccionada ? color : color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, size: 14, color: seleccionada ? Colors.white : color),
                ),
                const Spacer(),
                if (seleccionada)
                  Icon(Icons.check_circle_rounded, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: seleccionada ? color : textoPrincipal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitulo,
              style: TextStyle(fontSize: 9.5, color: textoSecundario),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // VISTA: REVELACIÓN DEL TURNO
  // ===========================================================================

  Widget _buildPanelRevelacion() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    final resultado = _resultadoTurnoActual;
    final esGol = resultado == _ResultadoTurno.golMio || resultado == _ResultadoTurno.golRival;

    final colorResultado = switch (resultado) {
      _ResultadoTurno.golMio => const Color(0xFF2E9E5B),
      _ResultadoTurno.golRival => const Color(0xFFE63946),
      _ => textoSecundario,
    };

    final textResultado = switch (resultado) {
      _ResultadoTurno.golMio => '¡GOL TUYO!',
      _ResultadoTurno.golRival => 'GOL DEL RIVAL',
      _ => 'SIN PELIGRO',
    };

    final iconoResultado = switch (resultado) {
      _ResultadoTurno.golMio => Icons.sports_soccer_rounded,
      _ResultadoTurno.golRival => Icons.sentiment_dissatisfied_rounded,
      _ => Icons.shield_rounded,
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Elección del rival
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: superficie,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borde, width: 0.8),
            ),
            child: Column(
              children: [
                Text(
                  'El rival eligió',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: textoSecundario),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.acento.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_rivalFormacionTurno?.icono ?? Icons.grid_view_rounded, size: 16, color: AppColors.acento),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Formación', style: TextStyle(fontSize: 10, color: textoSecundario)),
                              Text(_rivalFormacionTurno?.nombre ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textoPrincipal)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _rivalEstiloTurno?.color.withValues(alpha: 0.12) ?? Colors.grey.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_rivalEstiloTurno?.icono ?? Icons.bolt_rounded, size: 16, color: _rivalEstiloTurno?.color ?? Colors.grey),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Estilo', style: TextStyle(fontSize: 10, color: textoSecundario)),
                              Text(_rivalEstiloTurno?.nombre ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textoPrincipal)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Resultado del turno (animado)
          AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              decoration: BoxDecoration(
                color: colorResultado.withValues(alpha: esGol ? 0.14 : 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorResultado.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconoResultado, size: 46, color: colorResultado),
                  const SizedBox(height: 10),
                  Text(
                    textResultado,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: colorResultado,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (esGol) ...[
                    const SizedBox(height: 6),
                    Text(
                      '$_golesMi - $_golesRival',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textoPrincipal, letterSpacing: 3),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  // ===========================================================================
  // VISTA: PENALES
  // ===========================================================================

  Widget _vistaPenales() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final fondo = esOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;

    final mostrarResultado = _detallesPenales.isNotEmpty &&
        _timerAnimacion?.isActive == true;

    return Container(
      color: fondo,
      child: Column(
        children: [
          // Marcador de penales
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro,
              border: Border(
                bottom: BorderSide(
                  color: esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro,
                  width: 0.8,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _esMuerteSubita ? 'MUERTE SÚBITA' : 'PENALES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.pro,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _banderaCircular(_miEquipo!.codigoBandera, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _miEquipo!.nombre,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textoPrincipal),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: esOscuro ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_penalesMi - $_penalesRival',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textoPrincipal, letterSpacing: 2),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              _rivalEquipo!.nombre,
                              textAlign: TextAlign.end,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textoPrincipal),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _banderaCircular(_rivalEquipo!.codigoBandera, size: 28),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Historial de tiros (burbujas)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    max(_tirosMi, _tirosRival) + 1,
                    (i) {
                      final detalleMio = i < _detallesPenales.where((d) => d.esMio).length
                          ? _detallesPenales.where((d) => d.esMio).elementAt(i)
                          : null;
                      final detalleRival = i < _detallesPenales.where((d) => !d.esMio).length
                          ? _detallesPenales.where((d) => !d.esMio).elementAt(i)
                          : null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          children: [
                            _buildIndicadorPenal(detalleMio),
                            const SizedBox(height: 4),
                            _buildIndicadorPenal(detalleRival),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: mostrarResultado
                ? _buildResultadoPenal(esOscuro, textoPrincipal, textoSecundario)
                : _buildEleccionPenal(esOscuro, textoPrincipal, textoSecundario),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadorPenal(_DetallePenal? detalle) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    if (detalle == null) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borde, width: 1.5),
        ),
      );
    }
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: detalle.fueGol ? const Color(0xFF2E9E5B) : const Color(0xFFE63946),
      ),
      child: Icon(
        detalle.fueGol ? Icons.check_rounded : Icons.close_rounded,
        size: 10,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEleccionPenal(bool esOscuro, Color textoPrincipal, Color textoSecundario) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _esTurnoMio ? '¡Es tu turno de patear!' : '¡Atajá el penal del rival!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textoPrincipal),
          ),
          const SizedBox(height: 6),
          Text(
            _esTurnoMio
                ? 'Elige dónde patear'
                : 'Elige dónde se tira tu arquero',
            style: TextStyle(fontSize: 13, color: textoSecundario),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBotonZona(_ZonaPenal.izquierda, esOscuro),
              _buildBotonZona(_ZonaPenal.centro, esOscuro),
              _buildBotonZona(_ZonaPenal.derecha, esOscuro),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonZona(_ZonaPenal zona, bool esOscuro) {
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final icono = switch (zona) {
      _ZonaPenal.izquierda => Icons.arrow_back_rounded,
      _ZonaPenal.centro => Icons.arrow_downward_rounded,
      _ZonaPenal.derecha => Icons.arrow_forward_rounded,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _resolverPenal(zona),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.acento.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.acento.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 26, color: AppColors.acento),
            const SizedBox(height: 4),
            Text(
              switch (zona) {
                _ZonaPenal.izquierda => 'Izq',
                _ZonaPenal.centro => 'Centro',
                _ZonaPenal.derecha => 'Der',
              },
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textoPrincipal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoPenal(bool esOscuro, Color textoPrincipal, Color textoSecundario) {
    final ultimoDetalle = _detallesPenales.last;
    final color = ultimoDetalle.fueGol
        ? (ultimoDetalle.esMio ? const Color(0xFF2E9E5B) : const Color(0xFFE63946))
        : (ultimoDetalle.esMio ? const Color(0xFFE63946) : const Color(0xFF2E9E5B));

    final String texto;
    if (ultimoDetalle.esMio) {
      texto = ultimoDetalle.fueGol ? '¡GOL!' : '¡Atajó el arquero!';
    } else {
      texto = ultimoDetalle.fueGol ? '¡Gol del rival!' : '¡Atajaste!';
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(
              ultimoDetalle.fueGol ? Icons.sports_soccer_rounded : Icons.back_hand_rounded,
              size: 44,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            texto,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
        ],
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

    final huboPenales = _penalesMi != _penalesRival || _detallesPenales.isNotEmpty;
    final gane = huboPenales ? _penalesMi > _penalesRival : _golesMi > _golesRival;
    final esCampeon = gane && _ronda == 4;
    final color = gane ? const Color(0xFF2E9E5B) : const Color(0xFFE63946);

    final marcadorTexto = huboPenales
        ? '${_golesMi} - ${_golesRival}  ·  Penales ${_penalesMi} - ${_penalesRival}'
        : '$_golesMi - $_golesRival';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                                ? Icon(gano ? Icons.check_rounded : Icons.close_rounded, size: 16, color: colorRonda)
                                : Text('$numeroRonda', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colorRonda)),
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
                        gane ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(height: 22),

            Text(
              esCampeon ? '¡Campeón!' : (gane ? '¡Victoria!' : 'Eliminado'),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _banderaCircular(_miEquipo!.codigoBandera, size: 32),
                const SizedBox(width: 12),
                Text(
                  marcadorTexto,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textoPrincipal, letterSpacing: 2),
                ),
                const SizedBox(width: 12),
                _banderaCircular(_rivalEquipo!.codigoBandera, size: 32),
              ],
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
                    ? '${_miEquipo!.nombre} ganó el Mini Mundial'
                    : (gane
                        ? 'Le ganaste a ${_rivalEquipo!.nombre} en ${_etiquetaRonda(_ronda)}'
                        : 'Te eliminó ${_rivalEquipo!.nombre} en ${_etiquetaRonda(_ronda)}'),
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
                    : (gane ? _siguienteRonda : _reiniciarTorneo),
                icon: Icon(
                  esCampeon ? Icons.refresh_rounded : (gane ? Icons.arrow_forward_rounded : Icons.replay_rounded),
                  size: 20,
                ),
                label: Text(
                  esCampeon ? 'Jugar de nuevo' : (gane ? 'Siguiente ronda' : 'Intentar de nuevo'),
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