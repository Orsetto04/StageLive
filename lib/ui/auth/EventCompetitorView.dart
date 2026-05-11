import 'package:flutter/material.dart';

class EventCompetitorView extends StatelessWidget {
  const EventCompetitorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // TASTO TORNA INDIETRO
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("StageLive", style: TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold)),
        actions: const [Icon(Icons.notifications_none, color: Colors.white), SizedBox(width: 15)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("DIVENTA UN PROTAGONISTA", style: TextStyle(color: Color(0xFFD68BFF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const Text("Sali sul Palco", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Unisciti alla rivoluzione di StageLive. Mostra il tuo talento.", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),
            
            _buildCardContainer("Informazioni Artistiche", Icons.brush, [
              _buildModernInput("NOME D'ARTE *", "Es. Luna Stark"),
              _buildModernInput("GENERE MUSICALE", "Pop", suffix: Icons.keyboard_arrow_down),
              _buildModernInput("DESCRIZIONE DEL TUO STILE", "Parlaci del tuo sound...", lines: 3),
            ]),

            _buildCardContainer("Dati Anagrafici", Icons.badge, [
              _buildModernInput("NOME", ""),
              _buildModernInput("COGNOME", ""),
            ]),

            _buildCardContainer("Video Performance", Icons.videocam, [
              Container(
                height: 120,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.videocam, color: Colors.grey), Text("CARICA VIDEO", style: TextStyle(color: Colors.grey, fontSize: 10))])),
              ),
            ]),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD68BFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                onPressed: () {
                  // Logica invio
                },
                child: const Text("COMPLETA REGISTRAZIONE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // I metodi _buildCardContainer e _buildModernInput rimangono identici a prima...
  Widget _buildCardContainer(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: const Color(0xFFD68BFF), size: 18), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernInput(String label, String hint, {IconData? suffix, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            maxLines: lines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              filled: true, fillColor: Colors.black, suffixIcon: Icon(suffix, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}