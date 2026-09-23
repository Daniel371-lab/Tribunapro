import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maneja el "Pro temporal" de 24 horas que se desbloquea viendo 5
/// anuncios recompensados. NO deshabilita anuncios de la app (eso solo
/// lo hace el Pro real). Solo desbloquea los partidos marcados como Pro.
///
/// Todo se guarda en SharedPreferences (el celular), no en Firestore.
/// Si el usuario cambia de dispositivo, pierde el Pro temporal.
class ProTemporalService {
  ProTemporalService._();
  static final ProTemporalService instance = ProTemporalService._();

  static const _keyVencimiento = 'pro_temporal_vencimiento_ms';

  /// Notifica en vivo si el Pro temporal está activo o no. La pantalla
  /// del detalle de partido lo escucha para mostrar las predicciones
  /// cuando el usuario vuelve de ver los 5 anuncios.
  final ValueNotifier<bool> proTemporalActivo = ValueNotifier<bool>(false);

  /// Flag en memoria: si el modal de bienvenida ya se mostró en esta
  /// sesión de app. Se resetea cada vez que el usuario abre la app.
  bool _modalMostradoEstaSesion = false;

  Future<void> refrescar() async {
    final activo = await estaActivo();
    proTemporalActivo.value = activo;
  }

  Future<bool> estaActivo() async {
    final prefs = await SharedPreferences.getInstance();
    final vencimiento = prefs.getInt(_keyVencimiento);
    if (vencimiento == null) return false;

    final ahora = DateTime.now().millisecondsSinceEpoch;
    if (ahora >= vencimiento) {
      await prefs.remove(_keyVencimiento);
      return false;
    }
    return true;
  }

  Future<void> activarPor24Horas() async {
    final prefs = await SharedPreferences.getInstance();
    final vencimiento = DateTime.now()
        .add(const Duration(hours: 24))
        .millisecondsSinceEpoch;
    await prefs.setInt(_keyVencimiento, vencimiento);
    proTemporalActivo.value = true;
  }

  /// ¿El modal de bienvenida ya se mostró en esta sesión de app?
  bool get modalMostradoEstaSesion => _modalMostradoEstaSesion;

  /// Marca el modal como mostrado en esta sesión.
  void marcarModalMostradoEstaSesion() {
    _modalMostradoEstaSesion = true;
  }
}