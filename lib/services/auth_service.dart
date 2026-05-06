import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // REGISTRAZIONE: Crea profilo senza ruolo
  Future<void> registraUtente({
    required String email, 
    required String password, 
    required String nome
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // Salvataggio dati minimi su Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': nome,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // LOGIN: Semplice accesso
  Future<void> loginUtente(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}