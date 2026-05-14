import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class EventCompetitorView extends StatefulWidget {
  const EventCompetitorView({super.key});

  @override
  State<EventCompetitorView> createState() => _EventCompetitorViewState();
}

class _EventCompetitorViewState extends State<EventCompetitorView> {
  // --- CONTROLLER ---
  final TextEditingController _nomeArteController = TextEditingController();
  final TextEditingController _descrizioneController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cognomeController = TextEditingController();
  final TextEditingController _cfController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _luogoController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // Controller Social (Facoltativi)
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();

  String? _selectedGenre;
  String? _cfError;
  bool _isSending = false;

  final List<String> _generi = ['Pop', 'Rock', 'Trap', 'Indie', 'Rap', 'Electronic', 'Jazz', 'Blues', 'Metal'];

  // --- LOGICA INVIO ---
  Future<void> _inviaCandidatura() async {
    // Controllo campi obbligatori
    if (_nomeArteController.text.isEmpty || 
        _selectedGenre == null || 
        _nomeController.text.isEmpty || 
        _cognomeController.text.isEmpty || 
        _cfController.text.isEmpty || 
        _cfError != null) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Compila tutti i campi obbligatori correttamente!"), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance.collection('candidature').add({
        'uid': FirebaseAuth.instance.currentUser?.uid,
        'nomeArte': _nomeArteController.text.trim(),
        'genere': _selectedGenre,
        'descrizione': _descrizioneController.text.trim(),
        'nome': _nomeController.text.trim(),
        'cognome': _cognomeController.text.trim(),
        'codiceFiscale': _cfController.text.toUpperCase().trim(),
        'telefono': _telefonoController.text.trim(),
        'email': _emailController.text.trim(),
        'dataNascita': _dateController.text,
        'luogoNascita': _luogoController.text.trim(),
        // Social (possono essere vuoti)
        'instagram': _instagramController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'status': 'PENDENTE',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Candidatura inviata con successo!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("StageLive", style: TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sali sul Palco", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            _buildCardContainer("Informazioni Artistiche *", Icons.mic, [
              _buildInput("NOME D'ARTE *", "Es. Luna Stark", _nomeArteController),
              _buildDropdown(),
              _buildInput("DESCRIZIONE STILE", "Parlaci del tuo sound...", _descrizioneController, lines: 3),
            ]),

            _buildCardContainer("Dati Anagrafici *", Icons.badge, [
              _buildInput("NOME *", "", _nomeController),
              _buildInput("COGNOME *", "", _cognomeController),
              _buildInput("CODICE FISCALE *", "", _cfController, onChanged: (v) {
                RegExp regExp = RegExp(r'^[A-Z]{6}[0-9]{2}[A-Z][0-9]{2}[A-Z][0-9]{3}[A-Z]$');
                setState(() => _cfError = (v.isEmpty || regExp.hasMatch(v.toUpperCase())) ? null : "Codice Fiscale non valido");
              }),
              if (_cfError != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_cfError!, style: const TextStyle(color: Colors.red, fontSize: 11))),
              _buildInput("LUOGO DI NASCITA", "", _luogoController),
            ]),

            // --- NUOVA SEZIONE SOCIAL (FACOLTATIVA) ---
            _buildCardContainer("Social (Opzionale)", Icons.share, [
              _buildInput("INSTAGRAM USERNAME", "@tuoutente", _instagramController),
              _buildInput("TIKTOK USERNAME", "@tuoutente", _tiktokController),
              _buildInput("FACEBOOK NAME", "Nome Profilo", _facebookController),
            ]),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD68BFF), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
                onPressed: _isSending ? null : _inviaCandidatura,
                child: _isSending 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("INVIA REGISTRAZIONE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPERS IDENTICI ---
  Widget _buildCardContainer(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(25)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: const Color(0xFFD68BFF), size: 18), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 20), ...children
      ]),
    );
  }

  Widget _buildInput(String label, String hint, TextEditingController ctrl, {int lines = 1, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl, maxLines: lines, onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true, fillColor: Colors.black,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
          ),
        ),
      ]),
    );
  }

  Widget _buildDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("GENERE MUSICALE *", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        dropdownColor: const Color(0xFF16161E), value: _selectedGenre,
        items: _generi.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: Colors.white)))).toList(),
        onChanged: (v) => setState(() => _selectedGenre = v),
        decoration: InputDecoration(filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
      ),
      const SizedBox(height: 15),
    ]);
  }
}