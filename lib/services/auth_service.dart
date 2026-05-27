import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  String? get currentUid => _auth.currentUser?.uid;

  // LOGIN
  Future<User?> loginUtente({required String email, required String password}) async {
    UserCredential res = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return res.user;
  }

  // REGISTRAZIONE
  Future<User?> registraUtente({required String email, required String password, required String nome}) async {
    UserCredential res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    // Salva i dati extra dell'utente
    await _firestore.collection('users').doc(res.user!.uid).set({
      'uid': res.user!.uid,
      'nome': nome,
      'email': email,
    });
    return res.user;
  }

  // LOGOUT
  Future<void> signOut() async => await _auth.signOut();

  // CREAZIONE EVENTO 
  Future<void> creaEvento({
    required String titolo,
    required String data,
    required String luogo,
    required String descrizione,
  }) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('eventi').add({
      'titolo': titolo,
      'data': data,
      'luogo': luogo,
      'descrizione': descrizione,
      'adminId': uid, // Identifica il creatore
      'createdAt': FieldValue.serverTimestamp(),
      'spettatori': [],
      'concorrenti': [],
    });
  }

 Future<void> partecipaEvento({required String eventId, required String ruolo}) async {
  try {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Devi essere loggato");

    DocumentSnapshot eventDoc = await _firestore.collection('eventi').doc(eventId).get();
    if (!eventDoc.exists) throw Exception("Evento non trovato");
    
    Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
    List spettatori = data['spettatori'] ?? [];
    List concorrenti = data['concorrenti'] ?? [];

    if (ruolo == 'Spettatore') {
      // Se è già concorrente, BLOCCO (Errore)
      if (concorrenti.contains(uid)) {
        throw Exception("non puoi entrare come spettatore perché sei già concorrente.");
      }
      // Se è già spettatore, ESCI CON SUCCESSO (Nessun errore)
      if (spettatori.contains(uid)) return; 
      
    } else if (ruolo == 'Concorrente') {
      // Se è già spettatore, BLOCCO (Errore)
      if (spettatori.contains(uid)) {
        throw Exception("non puoi entrare come concorrente perché sei già spettatore.");
      }
      // Se è già concorrente, ESCI CON SUCCESSO (Nessun errore)
      if (concorrenti.contains(uid)) return;
    }

    // Aggiunta al DB solo se non era già presente
    String campo = (ruolo == 'Spettatore') ? 'spettatori' : 'concorrenti';
    await _firestore.collection('eventi').doc(eventId).update({
      campo: FieldValue.arrayUnion([uid])
    });

  } catch (e) {
    rethrow; 
  }
}
}