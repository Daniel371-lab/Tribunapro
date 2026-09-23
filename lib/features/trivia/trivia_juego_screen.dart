import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/models/trivia_pregunta.dart';

class TriviaJuegoScreen extends StatefulWidget {
  final List<TriviaPregunta> preguntas;
  const TriviaJuegoScreen({super.key, required this.preguntas});

  @override
  State<TriviaJuegoScreen> createState() => _TriviaJuegoScreenState();
}

class _TriviaJuegoScreenState extends State<TriviaJuegoScreen> {
  int _indice = 0;
  int _aciertos = 0;
  int? _opcionElegida;
  bool _respondido = false;

  void _responder(int opcion) {
    if (_respondido) return;
    setState(() {
      _opcionElegida = opcion;
      _respondido = true;
      if (opcion == widget.preguntas[_indice].correcta) _aciertos++;
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
        content: const Text('Si salís ahora, perdés el progreso de hoy y no vas a poder repetirlo hasta mañana.'),
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

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = esOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    final pregunta = widget.preguntas[_indice];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmarSalir();
      },
      child: Scaffold(
        backgroundColor: fondo,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textoSecundario),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_indice + (_respondido ? 1 : 0)) / widget.preguntas.length,
                    minHeight: 6,
                    backgroundColor: borde,
                    valueColor: const AlwaysStoppedAnimation(AppColors.acento),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  pregunta.pregunta,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textoPrincipal, height: 1.3),
                ),
                const SizedBox(height: 28),
                ...List.generate(pregunta.opciones.length, (i) {
                  final esCorrecta = i == pregunta.correcta;
                  final esElegida = i == _opcionElegida;

                  Color colorBorde = borde;
                  Color colorFondo = superficie;
                  if (_respondido) {
                    if (esCorrecta) {
                      colorBorde = Colors.green;
                      colorFondo = Colors.green.withOpacity(0.12);
                    } else if (esElegida) {
                      colorBorde = Colors.red;
                      colorFondo = Colors.red.withOpacity(0.12);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _responder(i),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: colorFondo,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colorBorde, width: 1.2),
                        ),
                        child: Text(
                          pregunta.opciones[i],
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textoPrincipal),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                if (_respondido)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _siguiente,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.acento,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_indice == widget.preguntas.length - 1 ? 'Ver resultado' : 'Siguiente'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}