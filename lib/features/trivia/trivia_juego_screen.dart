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

class _TriviaJuegoScreenState extends State<TriviaJuegoScreen> with SingleTickerProviderStateMixin {
  int _indice = 0;
  int _aciertos = 0;
  int? _opcionElegida;
  bool _respondido = false;
  bool _mostrarFeedback = false;
  Timer? _timerFeedback;

  late final List<bool?> _resultados = List.filled(widget.preguntas.length, null);

  late final AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _timerFeedback?.cancel();
    _feedbackController.dispose();
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

    _timerFeedback = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _mostrarFeedback = false);
        _feedbackController.reset();
      }
    });
  }

  void _siguiente() {
    if (_indice == widget.preguntas.length - 1) {
      Navigator.of(context).pop(_aciertos);
      return;
    }
    setState(() {
      _indice++;
      _opcionElegida = null;
      _respondido = false;
    });
  }

  void _confirmarSalir() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir del reto?'),
        content: const Text('Si sales ahora, pierdes el progreso de hoy y no vas a poder repetirlo hasta mañana.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(-1);
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
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    final pregunta = widget.preguntas[_indice];
    final acertoLaActual = _resultados[_indice] == true;
    final colorDificultad = _colorDificultad(pregunta.dificultad);

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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header: X + anillo de progreso ───
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

                    // ─── Barra de circulitos (uno por pregunta) ───
                    Row(
                      children: List.generate(_resultados.length, (i) {
                        Color color = borde;
                        Color colorBorde = borde;
                        if (_resultados[i] == true) {
                          color = const Color(0xFF2E9E5B);
                          colorBorde = const Color(0xFF2E9E5B);
                        }
                        if (_resultados[i] == false) {
                          color = const Color(0xFFE63946);
                          colorBorde = const Color(0xFFE63946);
                        }
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
                                  : (color == borde ? Border.all(color: colorBorde, width: 1) : null),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),

                    // ─── Chip de dificultad ───
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorDificultad.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorDificultad.withValues(alpha: 0.35), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_iconoDificultad(pregunta.dificultad), size: 14, color: colorDificultad),
                          const SizedBox(width: 6),
                          Text(
                            _etiquetaDificultad(pregunta.dificultad),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: colorDificultad,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ─── Pregunta en tarjeta ───
                    Container(
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
                        pregunta.pregunta,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: textoPrincipal,
                          height: 1.35,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ─── Opciones con letra A/B/C/D ───
                    ...List.generate(pregunta.opciones.length, (i) {
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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnimatedScale(
                          scale: _respondido && (esCorrecta || esElegida) ? 1.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _responder(i),
                            child: AnimatedContainer(
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
                                  // Letra identificadora
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: colorLetraFondo,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + i), // A, B, C, D
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
                            ),
                          ),
                        ),
                      );
                    }),

                    const Spacer(),

                    // ─── Botón siguiente ───
                    if (_respondido)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: _siguiente,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.acento,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 6,
                            shadowColor: AppColors.acento.withValues(alpha: 0.45),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _indice == widget.preguntas.length - 1 ? 'Ver resultado' : 'Siguiente',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _indice == widget.preguntas.length - 1
                                    ? Icons.emoji_events_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ─── Feedback flotante con animación de entrada ───
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

  // ─── Anillo de progreso del header ───
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