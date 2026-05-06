import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. REGISTRAZIONE - Ora accetta parametri NOMINATI con {}
  Future<User?> registraUtente({
    required String email, 
    required String password, 
    String? nome
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'nome': nome ?? 'Utente StageLive',
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print("Errore Registrazione: $e");
      rethrow;
    }
  }

  // 2. LOGIN - Anche questo con parametri NOMINATI per coerenza
  Future<User?> loginUtente({
    required String email, 
    required String password
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      print("Errore Login: $e");
      rethrow;
    }
  }

  // 3. LOGOUT
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Errore Logout: $e");
    }
  }

  // 4. CREAZIONE EVENTO
  Future<void> creaEvento({
    required String titolo,
    required String data,
    required String luogo,
    required String descrizione,
  }) async {
    try {
      String? uid = _auth.currentUser?.uid;
      
      if (uid == null) throw Exception("Utente non autenticato");

      await _firestore.collection('events').add({
        'titolo': titolo,
        'data': data,
        'luogo': luogo,
        'descrizione': descrizione,
        'adminId': uid,
        'spettatori': [], 
        'concorrenti': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Errore Creazione Evento: $e");
      rethrow;
    }
  }
}