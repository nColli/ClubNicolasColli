import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.setLanguageCode('es'); // Envía el email en español
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateDisplayName(String nombre) async {
    await _auth.currentUser?.updateDisplayName(nombre);
  }

  /// Borra la cuenta recién creada; ignora errores porque se usa como rollback.
  Future<void> deleteCurrentUser() async {
    await _auth.currentUser?.delete().catchError((_) {});
  }

  Future<void> signOut() => _auth.signOut();
}
