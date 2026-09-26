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
  final List<int> lineas;
  const _FormacionInfo(this.nombre, this.ataque, this.defensa, this.descripcion, this.icono, this.lineas);
}

class _EstiloInfo {
  final String nombre;
  final int ataqueBonus;
  final int defensaBonus;
  final int costoEnergia;
  final String descripcion;
  final IconData icono;
  final Color color;
  const _EstiloInfo(this.nombre, this.ataqueBonus, this.defensaBonus, this.costoEnergia, this.descripcion, this.icono, this.color);
}

enum _ResultadoTurno { golMio, golRival, nada }
enum _Fase { bienvenida, eligiendoEquipo, corriendoReloj, jugandoTurno, revelandoTurno, penales, resultado }
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
  _FormacionInfo('4-4-2', 5, 5, 'Equilibrada', Icons.grid_view_rounded, [4, 4, 2]),
  _FormacionInfo('4-3-3', 7, 3, 'Ofensiva', Icons.arrow_upward_rounded, [4, 3, 3]),
  _FormacionInfo('5-4-1', 3, 7, 'Defensiva', Icons.shield_rounded, [5, 4, 1]),
  _FormacionInfo('3-4-3', 8, 2, 'Ataque total', Icons.bolt_rounded, [3, 4, 3]),
  _FormacionInfo('4-2-3-1', 6, 4, 'Creativa', Icons.auto_awesome_rounded, [4, 2, 3, 1]),
];

const _estilos = [
  _EstiloInfo('Posesión', 2, 1, 5, 'Controlá el balón', Icons.psychology_rounded, Color(0xFF3B82F6)),
  _EstiloInfo('Contraataque', 1, 2, -5, 'Esperá y explotá', Icons.bolt_rounded, Color(0xFFE8B923)),
  _EstiloInfo('Presión Alta', 3, 0, -20, 'Asfixiá al rival', Icons.local_fire_department_rounded, Color(0xFFE63946)),
  _EstiloInfo('Juego de Bandas', 2, 0, -10, 'Jugá por los costados', Icons.swap_horiz_rounded, Color(0xFF8B5CF6)),
  _EstiloInfo('Defensa Cerrada', 0, 3, 10, 'Cerrá el arco', Icons.shield_rounded, Color(0xFF2E9E5B)),
];

// ============================================================================
// WIDGET
// ============================================================================

class MiniMundialScreen extends StatefulWidget {
  const MiniMundialScreen({super.key});

  @override
  State<MiniMundialScreen> createState() => _MiniMundialScreenState();
}

class _MiniMundialScreenState extends State<MiniMundialScreen> with TickerProviderStateMixin {
  final _random = Random();

  _Fase _fase = _Fase.bienvenida;
  _Seleccion? _miEquipo;
  _Seleccion? _rivalEquipo;
  int _ronda = 1;
  final List<bool> _historialRondas = [];

  int _golesMi = 0;
  int _golesRival = 0;
  List<int> _minutosClave = [];
  int _indiceTurno = 0;
  int _minutoMostrado = 0;

  // Energía: por partido, arranca en 100.
  double _energia = 100;
  // Moral: por torneo, arranca en 100. Baja a 50 si empatás.
  double _moral = 100;

  _FormacionInfo? _miFormacionTurno;
  _EstiloInfo? _miEstiloTurno;
  _FormacionInfo? _rivalFormacionTurno;
  _EstiloInfo? _rivalEstiloTurno;
  _ResultadoTurno? _resultadoTurnoActual;

  int _penalesMi = 0;
  int _penalesRival = 0;
  int _tirosMi = 0;
  int _tirosRival = 0;
  bool _esTurnoMio = true;
  bool _esMuerteSubita = false;
  final List<_DetallePenal> _detallesPenales = [];

  Timer? _timerAnimacion;
  late final AnimationController _flipController;
  late final AnimationController _dotsRivalController;
  late final AnimationController _relojController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _dotsRivalController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _relojController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  }

  @override
  void dispose() {
    _timerAnimacion?.cancel();
    _flipController.dispose();
    _dotsRivalController.dispose();
    _relojController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // MINUTOS
  // ---------------------------------------------------------------------------

  List<int> _generarMinutos() {
    final primerTiempo = List.generate(3, (_) => 5 + _random.nextInt(40)).toList()..sort();
    final segundoTiempo = List.generate(3, (_) => 50 + _random.nextInt(40)).toList()..sort();
    return [...primerTiempo, ...segundoTiempo];
  }

  // ---------------------------------------------------------------------------
  // FLUJO
  // ---------------------------------------------------------------------------

  void _empezar() {
    setState(() {
      _historialRondas.clear();
      _ronda = 1;
      _moral = 100;
      _fase = _Fase.eligiendoEquipo;
    });
  }

  void _elegirEquipo(_Seleccion equipo) {
    final restantes = _selecciones.where((s) => s.nombre != equipo.nombre).toList();
    setState(() {
      _miEquipo = equipo;
      _rivalEquipo = restantes[_random.nextInt(restantes.length)];
      _ronda = 1;
      _moral = 100;
      _historialRondas.clear();
      _iniciarPartido();
    });
  }

  void _iniciarPartido() {
    _golesMi = 0;
    _golesRival = 0;
    _minutosClave = _generarMinutos();
    _indiceTurno = 0;
    _minutoMostrado = 0;
    _energia = 100;
    _miFormacionTurno = null;
    _miEstiloTurno = null;
    _rivalFormacionTurno = null;
    _rivalEstiloTurno = null;
    _resultadoTurnoActual = null;
    _flipController.reset();
    _dotsRivalController.reset();
    _iniciarRelojTurno();
  }

  void _iniciarRelojTurno() {
    final minutoAnterior = _indiceTurno == 0 ? 0 : _minutosClave[_indiceTurno - 1];
    final minutoActual = _minutosClave[_indiceTurno];

    _minutoMostrado = minutoAnterior;
    setState(() => _fase = _Fase.corriendoReloj);

    _relojController.reset();
    _relojController.duration = Duration(
      milliseconds: 1500 + ((minutoActual - minutoAnterior) * 30).clamp(1000, 3000),
    );

    void listener() {
      final valor = _relojController.value;
      final minuto = (minutoAnterior + (minutoActual - minutoAnterior) * valor).round();
      if (mounted && minuto != _minutoMostrado) {
        setState(() => _minutoMostrado = minuto);
      }
    }

    _relojController.addListener(listener);

    _relojController.forward().then((_) {
      _relojController.removeListener(listener);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _fase = _Fase.jugandoTurno);
    });
  }

  void _confirmarTurno() {
    if (_miFormacionTurno == null || _miEstiloTurno == null) return;
    HapticFeedback.selectionClick();

    // Aplicamos el costo/recuperación de energía del estilo elegido.
    final nuevaEnergia = (_energia + _miEstiloTurno!.costoEnergia).clamp(0.0, 100.0);

    final rivalForm = _formaciones[_random.nextInt(_formaciones.length)];
    final rivalEst = _estilos[_random.nextInt(_estilos.length)];
    final resultado = _resolverTurno(_miFormacionTurno!, _miEstiloTurno!, rivalForm, rivalEst, nuevaEnergia);

    setState(() {
      _energia = nuevaEnergia;
      _rivalFormacionTurno = rivalForm;
      _rivalEstiloTurno = rivalEst;
      _resultadoTurnoActual = resultado;
      _fase = _Fase.revelandoTurno;
    });

    _dotsRivalController.forward(from: 0).then((_) {
      if (!mounted) return;
      _flipController.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() {
          if (resultado == _ResultadoTurno.golMio) {
            _golesMi++;
            HapticFeedback.mediumImpact();
          } else if (resultado == _ResultadoTurno.golRival) {
            _golesRival++;
            HapticFeedback.heavyImpact();
          }
        });
        _timerAnimacion = Timer(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          _avanzarTurno();
        });
      });
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
      _flipController.reset();
      _dotsRivalController.reset();
    });
    _iniciarRelojTurno();
  }

  void _terminarPartido() {
    if (_golesMi == _golesRival) {
      // Empate: la moral baja a 50 (mínimo).
      setState(() {
        if (_moral > 50) _moral = 50;
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
    final gane = _golesMi > _golesRival;
    // Si ganó y la moral estaba en 50, vuelve a 100.
    if (gane && _moral < 100) {
      _moral = 100;
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
      _moral = 100;
      _energia = 100;
      _fase = _Fase.eligiendoEquipo;
    });
  }

  // ---------------------------------------------------------------------------
  // MODIFICADORES DE ENERGÍA Y MORAL
  // ---------------------------------------------------------------------------

  // Devuelve los modificadores (ataque, defensa) según la energía.
  // 100-80: 0/0 · 79-60: -1/0 · 59-40: -1/-1 · 39-20: -2/-1 · 19-0: -2/-2
  Map<String, int> _modificadorEnergia(double energia) {
    if (energia >= 80) return {'ataque': 0, 'defensa': 0};
    if (energia >= 60) return {'ataque': -1, 'defensa': 0};
    if (energia >= 40) return {'ataque': -1, 'defensa': -1};
    if (energia >= 20) return {'ataque': -2, 'defensa': -1};
    return {'ataque': -2, 'defensa': -2};
  }

  // Devuelve el modificador de moral (solo ataque).
  // 100: 0 · 50: -1
  int _modificadorMoral(double moral) {
    if (moral >= 100) return 0;
    return -1;
  }

  // ---------------------------------------------------------------------------
  // TURNO
  // ---------------------------------------------------------------------------

  _ResultadoTurno _resolverTurno(
    _FormacionInfo miForm,
    _EstiloInfo miEst,
    _FormacionInfo rivalForm,
    _EstiloInfo rivalEst,
    double energiaEfectiva,
  ) {
    // Stats base
    int miAtaque = miForm.ataque + miEst.ataqueBonus;
    int miDefensa = miForm.defensa + miEst.defensaBonus;

    // Modificadores de energía
    final modEnergia = _modificadorEnergia(energiaEfectiva);
    miAtaque += modEnergia['ataque']!;
    miDefensa += modEnergia['defensa']!;

    // Modificador de moral (solo ataque)
    miAtaque += _modificadorMoral(_moral);

    // El rival no tiene energía ni moral.
    final rivalAtaque = rivalForm.ataque + rivalEst.ataqueBonus;
    final rivalDefensa = rivalForm.defensa + rivalEst.defensaBonus;

    final miAtaqueNeto = miAtaque - rivalDefensa;
    final rivalAtaqueNeto = rivalAtaque - miDefensa;

    if (miAtaqueNeto == rivalAtaqueNeto) {
      if (miAtaqueNeto >= 2) {
        if (miAtaque > rivalAtaque) return _ResultadoTurno.golMio;
        if (rivalAtaque > miAtaque) return _ResultadoTurno.golRival;
      }
      return _ResultadoTurno.nada;
    }
    if (miAtaqueNeto > rivalAtaqueNeto && miAtaqueNeto >= 2) return _ResultadoTurno.golMio;
    if (rivalAtaqueNeto > miAtaqueNeto && rivalAtaqueNeto >= 2) return _ResultadoTurno.golRival;
    return _ResultadoTurno.nada;
  }

  // ---------------------------------------------------------------------------
  // PENALES
  // ---------------------------------------------------------------------------

  void _resolverPenal(_ZonaPenal miEleccion) {
    HapticFeedback.selectionClick();
    if (_esTurnoMio) {
      final arqueroRival = _ZonaPenal.values[_random.nextInt(3)];
      final esGol = arqueroRival != miEleccion;
      if (esGol) _penalesMi++;
      _tirosMi++;
      _detallesPenales.add(_DetallePenal(esMio: true, fueGol: esGol, tiro: miEleccion, arquero: arqueroRival));
      if (esGol) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    } else {
      final tiroRival = _ZonaPenal.values[_random.nextInt(3)];
      final esGol = tiroRival != miEleccion;
      if (esGol) _penalesRival++;
      _tirosRival++;
      _detallesPenales.add(_DetallePenal(esMio: false, fueGol: esGol, tiro: tiroRival, arquero: miEleccion));
      if (!esGol) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    }
    setState(() {});
    _timerAnimacion = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _avanzarPenal();
    });
  }

  void _avanzarPenal() {
    if (!_esMuerteSubita && _tirosMi >= 5 && _tirosRival >= 5) {
      if (_penalesMi != _penalesRival) {
        _terminarPenales();
        return;
      }
      setState(() => _esMuerteSubita = true);
    }
    if (_esMuerteSubita) {
      if (_tirosMi == _tirosRival && _penalesMi != _penalesRival) {
        _terminarPenales();
        return;
      }
      setState(() => _esTurnoMio = _tirosMi == _tirosRival);
      return;
    }
    setState(() => _esTurnoMio = !_esTurnoMio);
  }

  void _terminarPenales() {
    final gane = _penalesMi > _penalesRival;
    // Si ganó por penales, la moral no sube (porque empató los 90').
    // Se queda en 50. En la próxima ronda, si gana, subirá a 100.
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
      case _Fase.corriendoReloj:
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
  // BIENVENIDA
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
                  BoxShadow(color: const Color(0xFFE8B923).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text('Mini Mundial', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textoPrincipal, letterSpacing: -0.5)),
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
                label: const Text('Comenzar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
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
  // ELEGIR EQUIPO
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
              decoration: BoxDecoration(color: const Color(0xFFE8B923).withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events_rounded, size: 20, color: Color(0xFFE8B923)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Elige tu selección', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textoPrincipal, letterSpacing: -0.2)),
                  Text('Enfrentarás rivales al azar hasta la final', style: TextStyle(fontSize: 12, color: textoSecundario)),
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
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: textoPrincipal, height: 1.15),
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
  // PARTIDO EN VIVO
  // ===========================================================================

  Widget _vistaPartidoEnVivo() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = esOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;
    final revelando = _fase == _Fase.revelandoTurno;
    final corriendo = _fase == _Fase.corriendoReloj;

    return Column(
      children: [
        _buildHeaderPartido(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: _buildPizarra(revelando),
        ),
        Expanded(
          child: Container(
            color: fondo,
            child: revelando
                ? _buildPanelRevelacion()
                : (corriendo ? _buildPanelReloj() : _buildPanelTurno()),
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

    final minutoActual = _fase == _Fase.corriendoReloj
        ? _minutoMostrado
        : (_minutosClave.length > _indiceTurno ? _minutosClave[_indiceTurno] : 90);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: superficie,
        border: Border(bottom: BorderSide(color: borde, width: 0.8)),
      ),
      child: Column(
        children: [
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
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, size: 13, color: textoSecundario),
              const SizedBox(width: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  minutoActual == 90 ? 'FIN DEL PARTIDO' : "Minuto $minutoActual' · Ronda $_ronda de 4",
                  key: ValueKey(minutoActual),
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textoSecundario, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Chips de energía y moral
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChipEstado(
                icono: Icons.speed_rounded,
                etiqueta: 'Energía',
                valor: _energia,
                color: _colorEnergia(_energia),
              ),
              const SizedBox(width: 8),
              _buildChipEstado(
                icono: Icons.psychology_rounded,
                etiqueta: 'Moral',
                valor: _moral,
                color: _colorMoral(_moral),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipEstado({
    required IconData icono,
    required String etiqueta,
    required double valor,
    required Color color,
  }) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            etiqueta,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textoPrincipal),
          ),
          const SizedBox(width: 4),
          Text(
            '${valor.round()}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PIZARRA
  // ===========================================================================

  Widget _buildPizarra(bool revelando) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;
    final rivalFormEnPizarra = revelando ? _rivalFormacionTurno : null;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde, width: 0.8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF1B6B40), Color(0xFF0E4A28)],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _CanchaHorizontalPainter())),
            if (rivalFormEnPizarra != null)
              ..._construirDotsFormacion(rivalFormEnPizarra, esRival: true, controller: _dotsRivalController),
            if (_miFormacionTurno != null)
              ..._construirDotsFormacion(_miFormacionTurno!, esRival: false, controller: null),
            Positioned(
              top: 4,
              right: 6,
              child: _buildPillEquipo(_rivalEquipo!.codigoBandera, _rivalEquipo!.nombre, Colors.red.shade900),
            ),
            Positioned(
              bottom: 4,
              left: 6,
              child: _buildPillEquipo(_miEquipo!.codigoBandera, _miEquipo!.nombre, AppColors.acento),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillEquipo(String codigoBandera, String nombre, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _banderaCircular(codigoBandera, size: 12),
          const SizedBox(width: 4),
          Text(
            nombre,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  List<Widget> _construirDotsFormacion(
    _FormacionInfo formacion, {
    required bool esRival,
    required AnimationController? controller,
  }) {
    final dots = <Widget>[];
    final lineas = formacion.lineas;
    final totalLineas = lineas.length;

    for (int i = 0; i < totalLineas; i++) {
      final cantidad = lineas[i];
      final double fraccionLinea = i / (totalLineas - 1 == 0 ? 1 : totalLineas - 1);

      final double x;
      if (esRival) {
        x = 0.88 - fraccionLinea * 0.32;
      } else {
        x = 0.12 + fraccionLinea * 0.32;
      }

      for (int j = 0; j < cantidad; j++) {
        final double y = (j + 1) / (cantidad + 1);

        final dot = Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: esRival ? Colors.red.shade200 : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: esRival ? Colors.red.shade900 : AppColors.acento, width: 1.3),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
        );

        Widget dotFinal = dot;
        if (controller != null) {
          dotFinal = AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Opacity(
                opacity: controller.value,
                child: Transform.scale(scale: 0.6 + controller.value * 0.4, child: child),
              );
            },
            child: dot,
          );
        }

        dots.add(Align(alignment: Alignment(x * 2 - 1, y * 2 - 1), child: dotFinal));
      }
    }
    return dots;
  }

  // ===========================================================================
  // PANEL: RELOJ CORRIENDO (sin "próximo momento")
  // ===========================================================================

  Widget _buildPanelReloj() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_soccer_rounded, size: 40, color: AppColors.acento),
          const SizedBox(height: 12),
          Text('El partido sigue...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textoPrincipal)),
          const SizedBox(height: 4),
          Text('Momento clave en camino', style: TextStyle(fontSize: 12.5, color: textoSecundario)),
        ],
      ),
    );
  }

  // ===========================================================================
  // PANEL: ELEGIR TURNO
  // ===========================================================================

  Widget _buildPanelTurno() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final minutoActual = _minutosClave[_indiceTurno];

    // Preview de energía: si hay estilo seleccionado, mostrar el efecto.
    final energiaPreview = _miEstiloTurno == null
        ? _energia
        : (_energia + _miEstiloTurno!.costoEnergia).clamp(0.0, 100.0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.acento.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "MINUTO $minutoActual'",
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.acento, letterSpacing: 0.6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Elegí tu estrategia',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textoSecundario),
                ),
              ),
            ],
          ),
        ),

        // Barras de energía y moral (con preview de energía)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro, width: 0.8),
            ),
            child: Column(
              children: [
                _buildBarraEstado(
                  icono: Icons.speed_rounded,
                  etiqueta: 'Energía',
                  valor: energiaPreview,
                  color: _colorEnergia(energiaPreview),
                ),
                const SizedBox(height: 8),
                _buildBarraEstado(
                  icono: Icons.psychology_rounded,
                  etiqueta: 'Moral',
                  valor: _moral,
                  color: _colorMoral(_moral),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Formación', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: textoSecundario)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _formaciones.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final f = _formaciones[i];
                      final elegida = _miFormacionTurno?.nombre == f.nombre;
                      return _buildCardFormacion(f, elegida);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text('Forma de juego', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: textoSecundario)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 98,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _estilos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final e = _estilos[i];
                      final elegida = _miEstiloTurno?.nombre == e.nombre;
                      return _buildCardEstilo(e, elegida);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: (_miFormacionTurno != null && _miEstiloTurno != null) ? _confirmarTurno : null,
              icon: const Icon(Icons.sports_soccer_rounded, size: 20),
              label: const Text('Confirmar jugada', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.acento,
                foregroundColor: Colors.white,
                disabledBackgroundColor: esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 6,
                shadowColor: AppColors.acento.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarraEstado({
    required IconData icono,
    required String etiqueta,
    required double valor,
    required Color color,
  }) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Row(
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            etiqueta,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textoPrincipal),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: valor / 100,
              minHeight: 8,
              backgroundColor: textoSecundario.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '${valor.round()}',
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildCardFormacion(_FormacionInfo f, bool elegida) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _miFormacionTurno = f);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: elegida ? AppColors.acento.withValues(alpha: 0.10) : superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: elegida ? AppColors.acento : borde, width: elegida ? 1.8 : 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: elegida ? AppColors.acento : AppColors.acento.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(f.icono, size: 11, color: elegida ? Colors.white : AppColors.acento),
                ),
                const Spacer(),
                if (elegida) const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.acento),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              f.nombre,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: elegida ? AppColors.acento : textoPrincipal),
            ),
            Text(
              f.descripcion,
              style: TextStyle(fontSize: 8.5, color: textoSecundario),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'ATQ ${f.ataque} · DEF ${f.defensa}',
              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: textoSecundario),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardEstilo(_EstiloInfo e, bool elegida) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    final textoEnergia = e.costoEnergia > 0
        ? '+${e.costoEnergia}'
        : '${e.costoEnergia}';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _miEstiloTurno = e);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 106,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: elegida ? e.color.withValues(alpha: 0.10) : superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: elegida ? e.color : borde, width: elegida ? 1.8 : 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: elegida ? e.color : e.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(e.icono, size: 11, color: elegida ? Colors.white : e.color),
                ),
                const Spacer(),
                if (elegida) Icon(Icons.check_circle_rounded, size: 14, color: e.color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              e.nombre,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: elegida ? e.color : textoPrincipal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'ATQ +${e.ataqueBonus} · DEF +${e.defensaBonus}',
              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: textoSecundario),
            ),
            Text(
              'Energía $textoEnergia',
              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: e.color),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PANEL: REVELACIÓN
  // ===========================================================================

  Widget _buildPanelRevelacion() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMiJugadaCarta()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('VS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textoSecundario, letterSpacing: 1)),
              ),
              Expanded(child: _buildRivalJugadaCarta()),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _flipController,
                builder: (context, _) {
                  final mostrarResultado = _flipController.value >= 1.0;
                  return AnimatedOpacity(
                    opacity: mostrarResultado ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedScale(
                      scale: mostrarResultado ? 1.0 : 0.8,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorResultado.withValues(alpha: esGol ? 0.14 : 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorResultado.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconoResultado, size: 32, color: colorResultado),
                            const SizedBox(height: 6),
                            Text(
                              textResultado,
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: colorResultado, letterSpacing: 0.5),
                            ),
                            if (esGol) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$_golesMi - $_golesRival',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textoPrincipal, letterSpacing: 3),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiJugadaCarta() {
    return Column(
      children: [
        _buildCartaVolteada(
          color: AppColors.acento,
          icono: _miFormacionTurno?.icono ?? Icons.grid_view_rounded,
          titulo: _miFormacionTurno?.nombre ?? '',
          subtitulo: 'Formación',
        ),
        const SizedBox(height: 6),
        _buildCartaVolteada(
          color: _miEstiloTurno?.color ?? AppColors.acento,
          icono: _miEstiloTurno?.icono ?? Icons.bolt_rounded,
          titulo: _miEstiloTurno?.nombre ?? '',
          subtitulo: 'Estilo',
        ),
      ],
    );
  }

  Widget _buildRivalJugadaCarta() {
    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, _) {
        final angle = _flipController.value * pi;
        final mostrarFrente = angle > pi / 2;
        return Column(
          children: [
            _buildCartaConFlip(
              angulo: angle,
              mostrarFrente: mostrarFrente,
              color: const Color(0xFFE63946),
              icono: _rivalFormacionTurno?.icono ?? Icons.grid_view_rounded,
              titulo: _rivalFormacionTurno?.nombre ?? '',
              subtitulo: 'Formación',
            ),
            const SizedBox(height: 6),
            _buildCartaConFlip(
              angulo: angle,
              mostrarFrente: mostrarFrente,
              color: _rivalEstiloTurno?.color ?? const Color(0xFFE63946),
              icono: _rivalEstiloTurno?.icono ?? Icons.bolt_rounded,
              titulo: _rivalEstiloTurno?.nombre ?? '',
              subtitulo: 'Estilo',
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartaConFlip({
    required double angulo,
    required bool mostrarFrente,
    required Color color,
    required IconData icono,
    required String titulo,
    required String subtitulo,
  }) {
    return Transform(
      transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angulo),
      alignment: Alignment.center,
      child: mostrarFrente
          ? Transform(
              transform: Matrix4.identity()..rotateY(pi),
              alignment: Alignment.center,
              child: _buildCartaVolteada(color: color, icono: icono, titulo: titulo, subtitulo: subtitulo),
            )
          : _buildCartaDorso(),
    );
  }

  Widget _buildCartaVolteada({
    required Color color,
    required IconData icono,
    required String titulo,
    required String subtitulo,
  }) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.3),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icono, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitulo,
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: textoSecundario),
                ),
                Text(
                  titulo,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: textoPrincipal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartaDorso() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: esOscuro
              ? [const Color(0xFF3A1F24), const Color(0xFF1F1114)]
              : [const Color(0xFF8B1A29), const Color(0xFF5A1018)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE63946).withValues(alpha: 0.5), width: 1.3),
        boxShadow: [BoxShadow(color: const Color(0xFFE63946).withValues(alpha: 0.20), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.help_outline_rounded, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ELEGIDA',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.white.withValues(alpha: 0.7)),
                ),
                const Text('???', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PENALES
  // ===========================================================================

  Widget _vistaPenales() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final fondo = esOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;

    final mostrarResultado = _detallesPenales.isNotEmpty && _timerAnimacion?.isActive == true;

    return Container(
      color: fondo,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro,
              border: Border(bottom: BorderSide(color: esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro, width: 0.8)),
            ),
            child: Column(
              children: [
                Text(
                  _esMuerteSubita ? 'MUERTE SÚBITA' : 'PENALES',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.pro, letterSpacing: 2),
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
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: borde, width: 1.5)),
      );
    }
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: detalle.fueGol ? const Color(0xFF2E9E5B) : const Color(0xFFE63946),
      ),
      child: Icon(detalle.fueGol ? Icons.check_rounded : Icons.close_rounded, size: 10, color: Colors.white),
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
            _esTurnoMio ? 'Elige dónde patear' : 'Elige dónde se tira tu arquero',
            style: TextStyle(fontSize: 13, color: textoSecundario),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBotonZona(_ZonaPenal.izquierda),
              _buildBotonZona(_ZonaPenal.centro),
              _buildBotonZona(_ZonaPenal.derecha),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonZona(_ZonaPenal zona) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
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
            child: Icon(ultimoDetalle.fueGol ? Icons.sports_soccer_rounded : Icons.back_hand_rounded, size: 44, color: color),
          ),
          const SizedBox(height: 16),
          Text(texto, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  // ===========================================================================
  // RESULTADO
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
                        Text(_etiquetaRonda(numeroRonda), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textoSecundario)),
                      ],
                    ),
                    if (numeroRonda < 4)
                      Container(width: 18, height: 2, margin: const EdgeInsets.only(bottom: 16), color: yaJugo ? colorRonda.withValues(alpha: 0.4) : borde),
                  ],
                );
              }),
            ),
            const SizedBox(height: 30),
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
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.40), blurRadius: 26, offset: const Offset(0, 10))],
              ),
              child: Center(
                child: esCampeon
                    ? const Text('🏆', style: TextStyle(fontSize: 52))
                    : Icon(gane ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded, size: 56, color: Colors.white),
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
                Text(marcadorTexto, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textoPrincipal, letterSpacing: 2)),
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
                onPressed: esCampeon ? _reiniciarTorneo : (gane ? _siguienteRonda : _reiniciarTorneo),
                icon: Icon(esCampeon ? Icons.refresh_rounded : (gane ? Icons.arrow_forward_rounded : Icons.replay_rounded), size: 20),
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
  // COLORES DE ESTADO
  // ===========================================================================

  Color _colorEnergia(double valor) {
    if (valor >= 80) return const Color(0xFF2E9E5B);
    if (valor >= 40) return const Color(0xFFE8B923);
    return const Color(0xFFE63946);
  }

  Color _colorMoral(double valor) {
    if (valor >= 100) return const Color(0xFF2E9E5B);
    return const Color(0xFFE63946);
  }

  // ===========================================================================
  // BANDERA
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

// ============================================================================
// PAINTER: CANCHA HORIZONTAL
// ============================================================================

class _CanchaHorizontalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final margen = 6.0;

    final rect = Rect.fromLTWH(margen, margen, size.width - margen * 2, size.height - margen * 2);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);

    canvas.drawLine(Offset(size.width / 2, margen), Offset(size.width / 2, size.height - margen), paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.height * 0.26, paint);

    final areaAncho = size.width * 0.12;
    final areaAlto = size.height * 0.55;
    canvas.drawRect(Rect.fromLTWH(margen, (size.height - areaAlto) / 2, areaAncho, areaAlto), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - margen - areaAncho, (size.height - areaAlto) / 2, areaAncho, areaAlto), paint);

    final areaChicaAncho = size.width * 0.05;
    final areaChicaAlto = size.height * 0.28;
    canvas.drawRect(Rect.fromLTWH(margen, (size.height - areaChicaAlto) / 2, areaChicaAncho, areaChicaAlto), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - margen - areaChicaAncho, (size.height - areaChicaAlto) / 2, areaChicaAncho, areaChicaAlto), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}