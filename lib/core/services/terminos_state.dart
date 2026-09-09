import 'package:shared_preferences/shared_preferences.dart';

class TerminosState {
  static const _clave = 'terminos_aceptados';

  static Future<bool> yaAcepto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_clave) ?? false;
  }

  static Future<void> marcarAceptados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clave, true);
  }
}