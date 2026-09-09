import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get cambiosDeSesion => _auth.authStateChanges();
  User? get usuarioActual => _auth.currentUser;

  Future<UserCredential> iniciarSesionInvitado() {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> registrarConEmail({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credencial.user?.updateDisplayName('$nombre $apellido');
    return credencial;
  }

  Future<UserCredential> iniciarSesionConEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> enviarEmailRecuperacion(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> cerrarSesion() {
    return _auth.signOut();
  }
}