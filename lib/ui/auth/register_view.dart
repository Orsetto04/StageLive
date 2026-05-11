import 'package:flutter/material.dart';
import 'package:stagelive/services/auth_service.dart';

class RegisterView extends StatefulWidget {
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  
  final AuthService _auth = AuthService();

  void _handleRegister() async {
    String nome = _nomeController.text.trim();
    String email = _emailController.text.trim();
    String password = _passController.text.trim();
    String confirm = _confirmController.text.trim();

    // Validazione base
    if (nome.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compila tutti i campi")),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le password non coincidono")),
      );
      return;
    }

    try {
      
      await _auth.registraUtente(
        email: email, 
        password: password, 
        nome: nome
      );

      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account creato con successo!")),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        title: Text("STAGELIVE", style: TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold, fontSize: 14))
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Il tuo posto in prima fila è qui.", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, height: 1.1)),
              SizedBox(height: 40),
              
              Container(
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Color(0xFF16161E),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white10)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Crea il tuo Account", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    
                    _buildSmallLabel("NOME COMPLETO"),
                    _buildInput(_nomeController, "Mario Rossi", Icons.person_outline),
                    
                    SizedBox(height: 15),
                    _buildSmallLabel("EMAIL"),
                    _buildInput(_emailController, "mario@esempio.it", Icons.email_outlined),
                    
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSmallLabel("PASSWORD"),
                            _buildInput(_passController, "•••••", Icons.lock_outline, isPass: true),
                          ],
                        )),
                        SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSmallLabel("CONFERMA"),
                            _buildInput(_confirmController, "•••••", Icons.history, isPass: true),
                          ],
                        )),
                      ],
                    ),
                    
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD68BFF),
                        minimumSize: Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: _handleRegister, 
                      child: Text("Registrati", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5, left: 4),
      child: Text(text, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey, size: 18),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white10),
        filled: true,
        fillColor: Colors.black,
        contentPadding: EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}