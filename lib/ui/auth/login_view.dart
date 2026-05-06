import 'package:flutter/material.dart';

class LoginView extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B0B0F), // Sfondo scuro foto
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 80),
              // Badge "Join the evolution"
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF2D1B4D),
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text("JOIN THE EVOLUTION", style: TextStyle(color: Color(0xFFD68BFF), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 15),
              Text("Bentornato!", style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1)),
              SizedBox(height: 10),
              Text("Accedi per entrare nell'arena e vivere l'esperienza StageLive.", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              
              SizedBox(height: 50),
              
              // Box Login (Stile Foto 1)
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
                    _buildLabel("EMAIL ACCREDITATA"),
                    _buildInputField(controller: _emailController, hint: "nome@esempio.it", icon: Icons.alternate_email),
                    SizedBox(height: 20),
                    _buildLabel("PASSWORD"),
                    _buildInputField(controller: _passController, hint: "••••••••", icon: Icons.lock_outline, isPass: true),
                    
                    SizedBox(height: 30),
                    
                    // Bottone Accedi (Viola Brillante)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD68BFF),
                        minimumSize: Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 10,
                        shadowColor: Color(0xFFD68BFF).withOpacity(0.4),
                      ),
                      onPressed: () { /* Logica Login */ },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Accedi all'Arena", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward, color: Colors.black),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: RichText(
                    text: TextSpan(
                      text: "Non hai ancora un profilo? ",
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(text: "Crea un account", style: TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold)),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: TextStyle(color: Color(0xFFD68BFF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hint, required IconData icon, bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}