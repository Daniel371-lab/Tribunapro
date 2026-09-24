import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class _Seleccion {
  final String nombre;
  final String bandera;
  const _Seleccion(this.nombre, this.bandera);
}

const _selecciones = [
  _Seleccion('Argentina', '🇦🇷'),
  _Seleccion('Brasil', '🇧🇷'),
  _Seleccion('Uruguay', '🇺🇾'),
  _Seleccion('Paraguay', '🇵🇾'),
  _Seleccion('México', '🇲🇽'),
  _Seleccion('Colombia', '🇨🇴'),
  _Seleccion('Chile', '🇨🇱'),
  _Seleccion('Francia', '🇫🇷'),
  _Seleccion('Alemania', '🇩🇪'),
  _Seleccion('España', '🇪🇸'),
  _Seleccion('Italia', '🇮🇹'),
  _Seleccion('Portugal', '🇵🇹'),
  _Seleccion('Países Bajos', '🇳🇱'),
  _Seleccion('Bélgica', '🇧🇪'),
  _Seleccion('Croacia', '🇭🇷'),
  _Seleccion('Japón', '🇯🇵'),
];

const _formaciones = ['4-4-2', '4-3-3', '5-4-1', '3-4-3', '4-2-3-1'];

const _estilos = ['Posesión', 'Contraataque', 'Presión Alta', 'Juego de Bandas', 'Defensa Cerrada'];

// Para cada estilo, los dos que le gana.
const _vence = {
  'Posesión': ['Contraataque', 'Presión Alta'],
  'Contraataque': ['Presión Alta', 'Juego de Bandas'],
  'Presión Alta': ['Juego de Bandas', 'Defensa Cerrada'],
  'Juego de Bandas': ['Defensa Cerrada', 'Posesión'],
  'Defensa Cerrada': ['Posesión', 'Contraataque'],
};

enum _Fase { eligiendoEquipo, eligiendoJugada, resolviendo, resultado }

class MiniMundialScreen extends StatefulWidget {
  const MiniMundialScreen({super.key});

  @override
  State<MiniMundialScreen> createState() => _MiniMundialScreenState();
}

class _MiniMundialScreenState extends State<MiniMundialScreen> {
  final _random = Random();
  _Fase _fase = _Fase.eligiendoEquipo;

  late _Seleccion _miEquipo;
  late _Seleccion _rivalEquipo;
  int _ronda = 1;

  String? _miFormacion;
  String? _miEstilo;
  String? _rivalEstilo;

  String _marcadorTexto = '';
  bool _mostrandoPenales = false;
  bool? _gane;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _elegirEquipo(_Seleccion equipo) {
    final restantes = _selecciones.where((s) => s.nombre != equipo.nombre).toList();
    setState(() {
      _miEquipo = equipo;
      _rivalEquipo = restantes[_random.nextInt(restantes.length)];
      _ronda = 1;
      _miFormacion = null;
      _miEstilo = null;
      _fase = _Fase.eligiendoJugada;
    });
  }

  void _jugar() {
    if (_miFormacion == null || _miEstilo == null) return;

    _rivalEstilo = _estilos[_random.nextInt(_estilos.length)];
    setState(() {
      _fase = _Fase.resolviendo;
      _marcadorTexto = '';
      _mostrandoPenales = false;
      _gane = null;
    });

    _timer = Timer(const Duration(milliseconds: 1200), _resolverPartido);
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
      // Mismo estilo: sorteo directo 3 vs 3, sin pasar por empate.
      final ganoUsuario = _random.nextBool();
      gane = ganoUsuario;
      marcador = ganoUsuario
          ? misGanadores3[_random.nextInt(3)]
          : rivalGanadores3[_random.nextInt(3)];
    } else if (_vence[_miEstilo]!.contains(_rivalEstilo)) {
      // Yo le gano al rival en el pentágono: 5 marcadores a mi favor + empate.
      final opcion = _random.nextInt(6);
      if (opcion == 5) {
        esEmpate = true;
        marcador = empates[_random.nextInt(3)];
      } else {
        gane = true;
        marcador = misGanadores5[opcion];
      }
    } else {
      // El rival me gana a mí: 5 marcadores a su favor + empate.
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
    });

    if (esEmpate) {
      _timer = Timer(const Duration(milliseconds: 1300), () {
        setState(() => _mostrandoPenales = true);
        _timer = Timer(const Duration(milliseconds: 1300), _resolverPenales);
      });
    } else {
      _timer = Timer(const Duration(milliseconds: 900), () {
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
      setState(() => _fase = _Fase.resultado);
    });
  }

  void _siguienteRonda() {
    if (_ronda >= 4) return; // ya era la final, no debería llamarse esto
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
    setState(() => _fase = _Fase.eligiendoEquipo);
  }

  @override
  Widget build(BuildContext context) {
    switch (_fase) {
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
        Text(
          'Elegí tu selección',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textoPrincipal),
        ),
        const SizedBox(height: 4),
        Text(
          'Vas a enfrentar rivales al azar hasta llegar a la final',
          style: TextStyle(fontSize: 12.5, color: textoSecundario),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selecciones.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (context, index) {
            final s = _selecciones[index];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _elegirEquipo(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: superficie,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borde, width: 0.8),
                ),
                child: Row(
                  children: [
                    Text(s.bandera, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.nombre,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textoPrincipal),
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

  Widget _vistaElegirJugada() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Ronda $_ronda de 4',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textoSecundario),
        ),
        const SizedBox(height: 6),
        Text(
          '${_miEquipo.bandera} ${_miEquipo.nombre}  vs  ${_rivalEquipo.bandera} ${_rivalEquipo.nombre}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textoPrincipal),
        ),
        const SizedBox(height: 24),
        Text('Alineación', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textoSecundario)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _formaciones.map((f) {
            final elegida = _miFormacion == f;
            return ChoiceChip(
              label: Text(f),
              selected: elegida,
              onSelected: (_) => setState(() => _miFormacion = f),
              selectedColor: AppColors.acento,
              labelStyle: TextStyle(
                color: elegida ? Colors.white : textoPrincipal,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Forma de juego', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textoSecundario)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _estilos.map((e) {
            final elegido = _miEstilo == e;
            return ChoiceChip(
              label: Text(e),
              selected: elegido,
              onSelected: (_) => setState(() => _miEstilo = e),
              selectedColor: AppColors.pro,
              labelStyle: TextStyle(
                color: elegido ? Colors.white : textoPrincipal,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: (_miFormacion != null && _miEstilo != null) ? _jugar : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.acento,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Jugar'),
          ),
        ),
      ],
    );
  }

  Widget _vistaResolviendo() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(_miEquipo.bandera, style: const TextStyle(fontSize: 44)),
                    const SizedBox(height: 6),
                    Text(_miEstilo ?? '', style: TextStyle(fontSize: 11, color: textoSecundario)),
                  ],
                ),
                Text('VS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textoSecundario)),
                Column(
                  children: [
                    Text(_rivalEquipo.bandera, style: const TextStyle(fontSize: 44)),
                    const SizedBox(height: 6),
                    Text(_rivalEstilo ?? '', style: TextStyle(fontSize: 11, color: textoSecundario)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_mostrandoPenales)
              Text('PENALES', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.pro))
            else if (_marcadorTexto.isEmpty)
              const CircularProgressIndicator()
            else if (_gane == null)
              Text('EMPATE $_marcadorTexto', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textoPrincipal))
            else
              Text(_marcadorTexto, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textoPrincipal)),
          ],
        ),
      ),
    );
  }

  Widget _vistaResultado() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final esCampeon = _gane == true && _ronda == 4;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              esCampeon ? '🏆' : (_gane == true ? _miEquipo.bandera : _rivalEquipo.bandera),
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              esCampeon ? '¡CAMPEÓN!' : (_gane == true ? '¡VICTORIA!' : 'DERROTA'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _gane == true ? Colors.green : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _marcadorTexto,
              style: TextStyle(fontSize: 16, color: textoSecundario),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: esCampeon
                    ? _reiniciarTorneo
                    : (_gane == true ? _siguienteRonda : _reiniciarTorneo),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.acento,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  esCampeon ? 'Jugar de nuevo' : (_gane == true ? 'Siguiente ronda' : 'Intentar de nuevo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}