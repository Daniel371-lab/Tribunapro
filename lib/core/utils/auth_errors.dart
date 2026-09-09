import 'package:firebase_auth/firebase_auth.dart';

String mensajeErrorAuth(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
        return 'No existe ninguna cuenta con ese correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo ingresado no es válido.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta registrada con ese correo.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Probá de nuevo.';
      case 'too-many-requests':
        return 'Demasiados intentos. Esperá un momento y volvé a intentar.';
      default:
        return 'Ocurrió un error inesperado. Intentá de nuevo.';
    }
  }
  return 'Ocurrió un error inesperado. Intentá de nuevo.';
}