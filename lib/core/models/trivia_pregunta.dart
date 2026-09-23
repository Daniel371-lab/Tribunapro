class TriviaPregunta {
  final String id;
  final String pregunta;
  final List<String> opciones;
  final int correcta;
  final String dificultad;

  TriviaPregunta({
    required this.id,
    required this.pregunta,
    required this.opciones,
    required this.correcta,
    required this.dificultad,
  });

  factory TriviaPregunta.fromJson(Map<String, dynamic> json) {
    return TriviaPregunta(
      id: json['id'] as String,
      pregunta: json['pregunta'] as String,
      opciones: (json['opciones'] as List).map((e) => e as String).toList(),
      correcta: json['correcta'] as int,
      dificultad: json['dificultad'] as String? ?? 'media',
    );
  }
}