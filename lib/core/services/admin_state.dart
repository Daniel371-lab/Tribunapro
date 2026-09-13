import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Detecta si el usuario logueado tiene el claim admin:true en su token
/// (asignado una sola vez con el script asignarAdmin.js).
final ValueNotifier<bool> esAdminNotifier = ValueNotifier<bool>(false);

class AdminState {
  static Future<void> verificar({bool forzarRenovacion = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      esAdminNotifier.value = false;
      return;
    }
    try {
      final resultado = await user.getIdTokenResult(forzarRenovacion);
      esAdminNotifier.value = resultado.claims?['admin'] == true;
    } catch (_) {
      // Si falla la consulta del claim (red, token recién creado, etc.),
      // no tocamos la sesión para nada. Simplemente asumimos "no admin"
      // por ahora, sin arriesgar el estado de login del usuario.
      esAdminNotifier.value = false;
    }
  }
}