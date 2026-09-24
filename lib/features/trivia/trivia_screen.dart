import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/trivia_service.dart';
import 'trivia_juego_screen.dart';
import 'mini_mundial_screen.dart';

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

class _TriviaScreenState extends State<TriviaScreen> with SingleTickerProviderStateMixin {
  final _servicio = TriviaService();
  late Future<_EstadoTrivia> _estadoFuture;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _estadoFuture = _cargarEstado();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    if (aciertos <= 3) return 'A seguir practicando';
    if (aciertos <= 5) return 'Vas por buen camino';
    if (aciertos <= 8) return '¡Buen nivel!';
    return '¡Conocimiento máximo!';
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = esOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Juegos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: textoPrincipal),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.acento,
              unselectedLabelColor: esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro,
              indicatorColor: AppColors.acento,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Reto diario'),
                Tab(text: 'Mini Mundial'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _retoDiarioTab(),
                  const MiniMundialScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _retoDiarioTab() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    return FutureBuilder<_EstadoTrivia>(
      future: _estadoFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final estado = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildHeaderCard(estado, textoPrincipal, textoSecundario, borde),
            const SizedBox(height: 18),
            if (!estado.yaJugoHoy) _buildBotonJugar() else _buildEstadoCompletado(textoSecundario, borde, superficie),
            const SizedBox(height: 28),
            Text(
              'INSIGNIAS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textoSecundario),
            ),
            const SizedBox(height: 12),
            if (estado.esInvitado)
              _buildBloqueoInvitado(textoPrincipal, textoSecundario, borde, superficie)
            else
              _buildCarruselInsignias(estado, textoPrincipal, textoSecundario, borde, superficie),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard(_EstadoTrivia estado, Color textoPrincipal, Color textoSecundario, Color borde) {
    final bool completado = estado.yaJugoHoy;
    final color = completado ? _colorSegunAciertos(estado.aciertos) : AppColors.acento;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildCirculoHeader(estado, color, borde),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completado ? 'Reto completado' : 'Reto diario',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textoPrincipal,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completado ? _mensajeSegunAciertos(estado.aciertos) : '10 preguntas de fútbol',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: completado ? FontWeight.w700 : FontWeight.w500,
                    color: completado ? color : textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCirculoHeader(_EstadoTrivia estado, Color color, Color borde) {
    const double size = 82;
    const double stroke = 7;

    // No jugó: círculo sólido con ícono.
    if (!estado.yaJugoHoy) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.acento,
              AppColors.acento.withValues(alpha: 0.65),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.acento.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.sports_esports_rounded, size: 38, color: Colors.white),
      );
    }

    // Ya jugó: anillo con progreso + número adentro.
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anillo de fondo
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: stroke,
              valueColor: AlwaysStoppedAnimation(borde),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Anillo de progreso
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: estado.aciertos / 10,
              strokeWidth: stroke,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Número central
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${estado.aciertos}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1),
              ),
              Text(
                'de 10',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.75), height: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonJugar() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: _jugar,
        icon: const Icon(Icons.play_arrow_rounded, size: 24),
        label: const Text('Jugar reto de hoy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.acento,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          shadowColor: AppColors.acento.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _buildEstadoCompletado(Color textoSecundario, Color borde, Color superficie) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borde, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: AppColors.acento),
          const SizedBox(width: 8),
          Text(
            'Volvé mañana para un nuevo reto',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textoSecundario),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INSIGNIAS
  // ---------------------------------------------------------------------------

  Widget _buildBloqueoInvitado(Color textoPrincipal, Color textoSecundario, Color borde, Color superficie) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borde, width: 0.8),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: textoSecundario.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded, color: textoSecundario, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea una cuenta para desbloquear insignias',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textoPrincipal),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu progreso de invitado no se guarda de forma permanente',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textoSecundario),
          ),
        ],
      ),
    );
  }

  Widget _buildCarruselInsignias(_EstadoTrivia estado, Color textoPrincipal, Color textoSecundario, Color borde, Color superficie) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _definicionInsignias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final insignia = _definicionInsignias[index];
          final desbloqueada = estado.insignias.contains(insignia.clave);
          return _buildInsignia(insignia, desbloqueada, textoPrincipal, textoSecundario, borde, superficie);
        },
      ),
    );
  }

  Widget _buildInsignia(
    _InsigniaInfo insignia,
    bool desbloqueada,
    Color textoPrincipal,
    Color textoSecundario,
    Color borde,
    Color superficie,
  ) {
    final Color colorIcono = desbloqueada ? insignia.color : textoSecundario.withValues(alpha: 0.35);
    final Color colorFondo = desbloqueada ? insignia.color.withValues(alpha: 0.14) : textoSecundario.withValues(alpha: 0.06);
    final Color colorBorde = desbloqueada ? insignia.color.withValues(alpha: 0.40) : borde;

    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorBorde, width: desbloqueada ? 1.4 : 0.8),
        boxShadow: desbloqueada
            ? [
                BoxShadow(
                  color: insignia.color.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorFondo,
              shape: BoxShape.circle,
            ),
            child: Icon(
              desbloqueada ? insignia.icono : Icons.lock_rounded,
              size: 24,
              color: colorIcono,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insignia.titulo,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: desbloqueada ? textoPrincipal : textoSecundario.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}