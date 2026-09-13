import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Detecta si el usuario logueado tiene el claim admin:true en su token
/// (asignado una sola vez con el script asignarAdmin.js).
final ValueNotifier<bool> esAdminNotifier = ValueNotifier<bool>(false);

class AdminState {
  static Future<void> verificar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      esAdminNotifier.value = false;
      return;
    }
    final resultado = await user.getIdTokenResult(true);
    esAdminNotifier.value = resultado.claims?['admin'] == true;
  }
}