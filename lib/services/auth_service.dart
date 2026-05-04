import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> login(String email, String password) async {
  try {
    // 1. Tenta l'autenticazione
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Recupera il documento dell'utente da Firestore usando l'UID
    DocumentSnapshot userDoc = await _db
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    // 3. Restituisce il ruolo salvato (Admin, Staff, Performer, etc.)
    if (userDoc.exists) {
      return userDoc.get('role') as String?;
    }
    return null;
  } catch (e) {
    print("Errore durante il login: $e");
    return null; 
  }
}
  // Registrazione specifica per Performer (US 4.2)
  // Ora la funzione accetta anche la stringa 'role'
Future<bool> registerUser({
  required String email,
  required String password,
  required String name,
  required String role, // <--- Aggiunto il ruolo
}) async {
  try {
    // 1. Crea l'utente in Authentication
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Salva i dati su Firestore con il ruolo corretto
    await _db.collection('users').doc(userCredential.user!.uid).set({
      'uid': userCredential.user!.uid,
      'name': name,
      'email': email,
      'role': role, // <--- Qui scriverà "Pubblico" o "Performer"
      'createdAt': DateTime.now(),
    });

    return true;
  } catch (e) {
    print("Errore registrazione: $e");
    return false;
  }
}
}