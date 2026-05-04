import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String selectedRole = "Pubblico"; 

  // Questo metodo crea il messaggio di errore che appare in basso
void _mostraErrore(String messaggio) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        messaggio, 
        style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white), // Mantengo il tuo stile
      ),
      backgroundColor: const Color(0xFFD18BFF).withOpacity(0.8), // Uso il tuo viola per coerenza
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      duration: const Duration(seconds: 3),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E), // Sfondo scuro come da foto
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("JOIN THE EVOLUTION", style: TextStyle(color: Color(0xFFD18BFF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              const Text("Bentornato!", style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text("Scegli il tuo ruolo per entrare nell'arena e vivere l'esperienza StageLive.", style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 40),

              // GRID DELLE CARD RUOLI
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _roleCard("Pubblico", Icons.confirmation_number_outlined, "Vivi lo spettacolo"),
                  _roleCard("Performer", Icons.star_border_rounded, "Sali sul palco"),
                  _roleCard("Staff", Icons.group_outlined, "Gestisci l'evento"),
                  _roleCard("Admin", Icons.security_outlined, "Controllo totale"),
                ],
              ),

              const SizedBox(height: 40),
              _inputLabel("EMAIL ACCREDITATA"),
              _textField(_emailController, "nome@esempio.it", Icons.alternate_email),
              const SizedBox(height: 20),
              _inputLabel("PASSWORD"),
              _textField(_passwordController, "••••••••", Icons.lock_outline, isPassword: true),

              const SizedBox(height: 40),
              // BOTTONE VIOLA "ACCEDI"
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD18BFF),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              onPressed: () async {
  String email = _emailController.text.trim();
  String password = _passwordController.text.trim();

  // 1. Controlli base
  if (email.isEmpty || password.isEmpty) {
    _mostraErrore("Per favore, inserisci email e password");
    return;
  }

  try {
    // 2. Tentativo di login
    String? roleRecuperato = await _authService.login(email, password);

    // 3. Gestione dei risultati
    if (roleRecuperato == null) {
      _mostraErrore("Credenziali errate o utente non registrato");
    } 
    else if (roleRecuperato.toLowerCase() != selectedRole.toLowerCase()) {
      _mostraErrore("Accesso negato: non sei registrato come $selectedRole");
    } 
    else {
      // SUCCESSO! 
      debugPrint("Benvenuto nell'Arena!");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Accesso effettuato come $selectedRole!"),
          backgroundColor: const Color.fromARGB(255, 151, 25, 234),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );

      // Qui navigheremo verso la Home tra un attimo
    }
  } catch (e) {
    _mostraErrore("Errore di connessione: riprova più tardi");
  }
},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Accedi all'Arena", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, color: Colors.black),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              // LOGICA DI SICUREZZA: Scompare per Admin e Staff
              if (selectedRole != "Admin" && selectedRole != "Staff")
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterView(role: selectedRole))),
                    child: RichText(
                      text: TextSpan(
                        text: "Non hai ancora un profilo? ",
                        style: const TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(text: "Crea un account", style: TextStyle(color: const Color(0xFFD18BFF), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String title, IconData icon, String sub) {
    bool isSelected = selectedRole == title;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = title),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1635) : const Color(0xFF161225),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFD18BFF) : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFD18BFF) : Colors.white54, size: 30),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _inputLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0, left: 5),
    child: Text(label, style: const TextStyle(color: Color(0xFFD18BFF), fontSize: 12, fontWeight: FontWeight.bold)),
  );

  Widget _textField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.black,
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFD18BFF))),
      ),
    );
  }
}