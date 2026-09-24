import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/trivia_service.dart';
import 'trivia_juego_screen.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _EstadoTrivia {
  final bool yaJugoHoy;
  final int aciertos;
  final bool esInvitado;
  final Set<String> insignias;

  _EstadoTrivia({
    required this.yaJugoHoy,
    required this.aciertos,
    required this.esInvitado,
    required this.insignias,
  });
}

class _InsigniaInfo {
  final String clave;
  final String titulo;
  final IconData icono;
  final Color color;

  const _InsigniaInfo({required this.clave, required this.titulo, required this.icono, required this.color});
}

const _definicionInsignias = [
  _InsigniaInfo(clave: 'racha_3', titulo: '3 días seguidos', icono: Icons.bolt_rounded, color: Colors.amber),
  _InsigniaInfo(clave: 'racha_7', titulo: '7 días seguidos', icono: Icons.local_fire_department_rounded, color: Colors.deepOrange),
  _InsigniaInfo(clave: 'racha_30', titulo: '30 días seguidos', icono: Icons.whatshot_rounded, color: Colors.red),
  _InsigniaInfo(clave: 'rendimiento_3', titulo: '3 días con 6+', icono: Icons.trending_up_rounded, color: Colors.teal),
  _InsigniaInfo(clave: 'rendimiento_7', titulo: '7 días con 8+', icono: Icons.military_tech_rounded, color: Colors.indigo),
  _InsigniaInfo(clave: 'perfecto_10', titulo: '10/10 perfecto', icono: Icons.workspace_premium_rounded, color: Colors.purple),
  _InsigniaInfo(clave: 'volumen_10', titulo: '10 retos jugados', icono: Icons.auto_stories_rounded, color: Colors.blueGrey),
  _InsigniaInfo(clave: 'volumen_50', titulo: '50 retos jugados', icono: Icons.menu_book_rounded, color: Colors.blueGrey),
  _InsigniaInfo(clave: 'volumen_100', titulo: '100 retos jugados', icono: Icons.school_rounded, color: Colors.blueGrey),
];

class _TriviaScreenState extends State<TriviaScreen> {
  final _servicio = TriviaService();
  late Future<_EstadoTrivia> _estadoFuture;

  @override
  void initState() {
    super.initState();
    _estadoFuture = _cargarEstado();
  }

  Future<_EstadoTrivia> _cargarEstado() async {
    final yaJugo = await _servicio.yaJugoHoy();
    final aciertos = yaJugo ? await _servicio.aciertosDeHoy() : 0;
    final user = FirebaseAuth.instance.currentUser;
    final esInvitado = user == null || user.isAnonymous;
    final insignias = esInvitado ? <String>{} : await _servicio.obtenerInsigniasDesbloqueadas();
    return _EstadoTrivia(yaJugoHoy: yaJugo, aciertos: aciertos, esInvitado: esInvitado, insignias: insignias);
  }

  Future<void> _jugar() async {
    final preguntas = await _servicio.armarRetoDeHoy();
    if (!mounted) return;
    final resultado = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => TriviaJuegoScreen(preguntas: preguntas)),
    );

    if (resultado == null || resultado < 0) return;

    await _servicio.guardarResultado(resultado, preguntas.map((p) => p.id).toList());
    if (!mounted) return;
    setState(() => _estadoFuture = _cargarEstado());
  }

  Color _colorSegunAciertos(int aciertos) {
    if (aciertos <= 3) return Colors.redAccent;
    if (aciertos <= 5) return Colors.orangeAccent;
    if (aciertos <= 8) return AppColors.acento;
    return AppColors.pro;
  }

  String _mensajeSegunAciertos(int aciertos) {
    if (aciertos <= 3) return 'Falta mejorar';
    if (aciertos <= 5) return 'Punto medio';
    if (aciertos <= 8) return 'Buen nivel';
    return 'Máximo conocimiento';
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = esOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: FutureBuilder<_EstadoTrivia>(
          future: _estadoFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final estado = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                Text(
                  'Trivia',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: textoPrincipal),
                ),
                const SizedBox(height: 20),
                // Tarjeta principal con degradé para que la sección sea más
                // llamativa, en vez del contenedor plano que tenía antes.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.acento.withOpacity(0.18),
                        AppColors.pro.withOpacity(0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borde, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      // Círculo más chico que antes (72 en vez de 140).
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: CircularProgressIndicator(
                                value: estado.yaJugoHoy ? estado.aciertos / 10 : 0,
                                strokeWidth: 6,
                                backgroundColor: borde,
                                valueColor: AlwaysStoppedAnimation(_colorSegunAciertos(estado.aciertos)),
                              ),
                            ),
                            Text(
                              estado.yaJugoHoy ? '${estado.aciertos}/10' : '—',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textoPrincipal),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              estado.yaJugoHoy ? 'Ya completaste tu reto de hoy' : 'Poné a prueba tu conocimiento hoy',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textoPrincipal),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              estado.yaJugoHoy
                                  ? _mensajeSegunAciertos(estado.aciertos)
                                  : '10 preguntas de fútbol te esperan',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: estado.yaJugoHoy ? FontWeight.w600 : FontWeight.normal,
                                color: estado.yaJugoHoy ? _colorSegunAciertos(estado.aciertos) : textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!estado.yaJugoHoy)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _jugar,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Jugar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.acento,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: superficie,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borde, width: 0.8),
                    ),
                    child: Center(
                      child: Text(
                        'Volvé mañana para un nuevo reto',
                        style: TextStyle(fontSize: 12.5, color: textoSecundario),
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                Text(
                  'INSIGNIAS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textoSecundario),
                ),
                const SizedBox(height: 10),
                if (estado.esInvitado)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    decoration: BoxDecoration(
                      color: superficie,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borde, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: textoSecundario, size: 28),
                        const SizedBox(height: 10),
                        Text(
                          'Creá una cuenta para desbloquear insignias',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textoPrincipal),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tu progreso de invitado no se guarda de forma permanente',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: textoSecundario),
                        ),
                      ],
                    ),
                  )
                else
                  // Carrusel horizontal deslizable, en vez de la grilla fija
                  // de antes. Tarjetas más chicas (88 de ancho).
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _definicionInsignias.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final insignia = _definicionInsignias[index];
                        final desbloqueada = estado.insignias.contains(insignia.clave);

                        return Container(
                          width: 88,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                          decoration: BoxDecoration(
                            color: superficie,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borde, width: 0.8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                insignia.icono,
                                size: 22,
                                color: desbloqueada ? insignia.color : textoSecundario.withOpacity(0.4),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                insignia.titulo,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: desbloqueada ? textoPrincipal : textoSecundario.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}