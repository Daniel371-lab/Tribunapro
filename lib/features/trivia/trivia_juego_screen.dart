import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/models/trivia_pregunta.dart';

class TriviaJuegoScreen extends StatefulWidget {
  final List<TriviaPregunta> preguntas;
  const TriviaJuegoScreen({super.key, required this.preguntas});

  @override
  State<TriviaJuegoScreen> createState() => _TriviaJuegoScreenState();
}

class _TriviaJuegoScreenState extends State<TriviaJuegoScreen> with TickerProviderStateMixin {
  int _indice = 0;
  int _aciertos = 0;
  int? _opcionElegida;
  bool _respondido = false;
  bool _mostrarFeedback = false;
  Timer? _timerFeedback;

  late final List<bool?> _resultados = List.filled(widget.preguntas.length, null);

  late final AnimationController _feedbackController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    _timerFeedback?.cancel();
    _feedbackController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _responder(int opcion) {
    if (_respondido) return;
    final esCorrecta = opcion == widget.preguntas[_indice].correcta;

    setState(() {
      _opcionElegida = opcion;
      _respondido = true;
      _resultados[_indice] = esCorrecta;
      _mostrarFeedback = true;
      if (esCorrecta) _aciertos++;
    });

    _feedbackController.forward(from: 0);
    _pulseController.repeat(reverse: true);

    // A los 1.5s se cierra el feedback y se pasa AUTOMÁTICAMENTE a la
    // siguiente pregunta (o se cierra la pantalla si era la última).
    _timerFeedback = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _mostrarFeedback = false;
      });
      _feedbackController.reset();
      _pulseController.stop();
      _pulseController.reset();
      _avanzarAutomaticamente();
    });
  }

  void _avanzarAutomaticamente() {
    if (_indice == widget.preguntas.length - 1) {
      // Era la última pregunta: cerramos con el puntaje.
      Navigator.of(context).pop(_aciertos);
      return;
    }
    setState(() {
      _indice++;
      _opcionElegida = null;
      _respondido = false;
    });
  }

  // BUG FIX: capturamos el navigator ANTES de abrir el diálogo, para
  // poder cerrar la pantalla sin depender de un context destruido.
  void _confirmarSalir() {
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir del reto?'),
        content: const Text(
          'Si sales ahora, pierdes el progreso de hoy y no vas a poder repetirlo hasta mañana.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              navigator.pop(-1);
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  String _etiquetaDificultad(String dificultad) {
    switch (dificultad) {
      case 'facil':
        return 'Fácil';
      case 'dificil':
        return 'Difícil';
      default:
        return 'Media';
    }
  }

  Color _colorDificultad(String dificultad) {
    switch (dificultad) {
      case 'facil':
        return const Color(0xFF2E9E5B);
      case 'dificil':
        return const Color(0xFFE63946);
      default:
        return const Color(0xFFE8B923);
    }
  }

  IconData _iconoDificultad(String dificultad) {
    switch (dificultad) {
      case 'facil':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'dificil':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.balance_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = esOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    final pregunta = widget.preguntas[_indice];
    final acertoLaActual = _resultados[_indice] == true;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmarSalir();
      },
      child: Scaffold(
        backgroundColor: fondo,
        body: SafeArea(
          child: Stack(
            children: [
              // Contenido scrolleable: la pregunta y las opciones pueden
              // ser más largas que la pantalla, pero el usuario puede
              // bajar para ver todo.
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header ───
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: textoPrincipal),
                          onPressed: _confirmarSalir,
                        ),
                        Expanded(
                          child: Text(
                            'Pregunta ${_indice + 1} de ${widget.preguntas.length}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: textoSecundario,
                            ),
                          ),
                        ),
                        _buildAnilloProgreso(esOscuro),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ─── Barra de circulitos ───
                    Row(
                      children: List.generate(_resultados.length, (i) {
                        final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;
                        Color color = borde;
                        if (_resultados[i] == true) color = const Color(0xFF2E9E5B);
                        if (_resultados[i] == false) color = const Color(0xFFE63946);
                        final esActual = i == _indice;

                        return Expanded(
                          child: Container(
                            height: 8,
                            margin: EdgeInsets.only(right: i == _resultados.length - 1 ? 0 : 5),
                            decoration: BoxDecoration(
                              color: esActual && _resultados[i] == null
                                  ? AppColors.acento.withValues(alpha: 0.35)
                                  : color,
                              borderRadius: BorderRadius.circular(8),
                              border: esActual && _resultados[i] == null
                                  ? Border.all(color: AppColors.acento, width: 1.5)
                                  : (color == borde ? Border.all(color: borde, width: 1) : null),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),

                    // ─── Chip de dificultad ───
                    _buildChipDificultad(pregunta.dificultad),
                    const SizedBox(height: 14),

                    // ─── Pregunta ───
                    _buildTarjetaPregunta(pregunta.pregunta, esOscuro, textoPrincipal),
                    const SizedBox(height: 22),

                    // ─── Opciones ───
                    ...List.generate(pregunta.opciones.length, (i) {
                      return _buildOpcion(i, pregunta, textoPrincipal);
                    }),
                  ],
                ),
              ),

              // ─── Feedback flotante ───
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _mostrarFeedback ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _feedbackController,
                        curve: Curves.easeOutBack,
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 28),
                          decoration: BoxDecoration(
                            color: acertoLaActual ? const Color(0xFF2E9E5B) : const Color(0xFFE63946),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: (acertoLaActual ? const Color(0xFF2E9E5B) : const Color(0xFFE63946))
                                    .withValues(alpha: 0.40),
                                blurRadius: 26,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  acertoLaActual ? Icons.check_rounded : Icons.close_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                acertoLaActual ? '¡Correcto!' : 'Incorrecto',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 21,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipDificultad(String dificultad) {
    final colorDificultad = _colorDificultad(dificultad);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorDificultad.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorDificultad.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconoDificultad(dificultad), size: 14, color: colorDificultad),
          const SizedBox(width: 6),
          Text(
            _etiquetaDificultad(dificultad),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: colorDificultad,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaPregunta(String texto, bool esOscuro, Color textoPrincipal) {
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borde, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: (esOscuro ? Colors.black : const Color(0xFF1A1A1A)).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: textoPrincipal,
          height: 1.35,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildOpcion(int i, dynamic pregunta, Color textoPrincipal) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    final esCorrecta = i == pregunta.correcta;
    final esElegida = i == _opcionElegida;

    Color colorBorde = borde;
    Color colorFondo = superficie;
    Color colorLetra = AppColors.acento;
    Color colorLetraFondo = AppColors.acento.withValues(alpha: 0.12);
    IconData? iconoEstado;

    if (_respondido) {
      if (esCorrecta) {
        colorBorde = const Color(0xFF2E9E5B);
        colorFondo = const Color(0xFF2E9E5B).withValues(alpha: 0.10);
        colorLetra = Colors.white;
        colorLetraFondo = const Color(0xFF2E9E5B);
        iconoEstado = Icons.check_rounded;
      } else if (esElegida) {
        colorBorde = const Color(0xFFE63946);
        colorFondo = const Color(0xFFE63946).withValues(alpha: 0.10);
        colorLetra = Colors.white;
        colorLetraFondo = const Color(0xFFE63946);
        iconoEstado = Icons.close_rounded;
      }
    }

    final tieneLatido = _respondido && esCorrecta;

    Widget contenido = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorBorde,
          width: _respondido && (esCorrecta || esElegida) ? 1.8 : 1.2,
        ),
        boxShadow: _respondido && esCorrecta
            ? [
                BoxShadow(
                  color: const Color(0xFF2E9E5B).withValues(alpha: 0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorLetraFondo,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + i),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: colorLetra,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              pregunta.opciones[i],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textoPrincipal,
                height: 1.3,
              ),
            ),
          ),
          if (iconoEstado != null)
            Icon(iconoEstado, size: 22, color: colorBorde),
        ],
      ),
    );

    if (tieneLatido) {
      contenido = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final escala = 1.0 + (_pulseController.value * 0.06);
          return Transform.scale(scale: escala, child: child);
        },
        child: contenido,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _responder(i),
        child: contenido,
      ),
    );
  }

  Widget _buildAnilloProgreso(bool esOscuro) {
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation(borde),
              strokeCap: StrokeCap.round,
            ),
          ),
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: (_indice + 1) / widget.preguntas.length,
              strokeWidth: 3.5,
              valueColor: const AlwaysStoppedAnimation(AppColors.acento),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${_indice + 1}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.acento),
          ),
        ],
      ),
    );
  }
}