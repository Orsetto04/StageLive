import 'package:flutter/material.dart'; // Importa il pacchetto base di Flutter per le UI e ChangeNotifier

// Definisce la classe LoginViewModel che estende ChangeNotifier.
// ChangeNotifier permette alla classe di "notificare" alla UI quando i dati cambiano.
class LoginViewModel extends ChangeNotifier {
 
  // Definisce una funzione chiamata 'login' che accetta due parametri: email e password.
  // Al momento è una funzione "void", cioè non restituisce alcun valore.
  void login(String email, String password) {
    
    // Stampa un messaggio nella console di debug di Visual Studio Code.
    // Serve a te sviluppatore per verificare che i dati arrivino correttamente dal form.
    print("Tentativo di login con: $email"); 
    
  } // Fine della funzione login
  
} // Fine della classe