import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterView extends StatefulWidget {
  final String role;
  const RegisterView({super.key, required this.role});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _mostraErrore(String messaggio) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        messaggio, 
        style: const TextStyle(color: Colors.white), 
      ),
      backgroundColor: const Color(0xFFD18BFF).withOpacity(0.8), // Stesso viola dell'Arena
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      duration: const Duration(seconds: 3),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Crea il tuo Account", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Unisciti alla community di StageLive come ${widget.role}.", style: const TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 40),
              
              _label("NOME COMPLETO"),
              _input(_nameController, "Mario Rossi", Icons.person_outline),
              const SizedBox(height: 20),
              _label("EMAIL"),
              _input(_emailController, "mario@esempio.it", Icons.email_outlined),
              const SizedBox(height: 20),
              _label("PASSWORD"),
              _input(_passwordController, "••••••••", Icons.lock_outline, isPass: true),
              
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD18BFF),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
  if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
    _mostraErrore("Riempi tutti i campi");
    return;
  }

  // Chiamata alla nuova funzione passandogli widget.role
  bool success = await _authService.registerUser(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
    name: _nameController.text.trim(),
    role: widget.role, // <--- Passa "Pubblico" o "Performer" automaticamente
  );

  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registrazione completata con successo!")),
    );
    Navigator.pop(context);
  } else {
    _mostraErrore("Errore nella registrazione");
  }
},
                child: const Text("Registrati", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1));
  
  Widget _input(TextEditingController controller, String hint, IconData icon, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white54),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD18BFF))),
      ),
    );
  }
}