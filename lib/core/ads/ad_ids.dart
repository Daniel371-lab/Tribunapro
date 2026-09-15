class AdIds {
  // Cambiar a false SOLO cuando la app ya esté en producción (no en Prueba cerrada).
  static const bool _modoPrueba = true;

  static const String banner = _modoPrueba
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-2628699742979891/6694281689';

  static const String intersticial = _modoPrueba
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-2628699742979891/9811882110';

  static const String recompensado = _modoPrueba
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-2628699742979891/3434904972';
}