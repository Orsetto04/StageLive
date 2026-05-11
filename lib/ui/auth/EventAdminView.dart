import 'package:flutter/material.dart';

class EventAdminView extends StatelessWidget {
  const EventAdminView({super.key});

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
        actions: const [CircleAvatar(radius: 15, backgroundImage: NetworkImage("https://via.placeholder.com/150")), SizedBox(width: 15)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Revisione Candidati", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatCircle("In Attesa", "12"),
                const SizedBox(width: 30),
                _buildStatCircle("Oggi", "54"),
              ],
            ),
            const SizedBox(height: 30),
            
            _buildCandidateCard("Luna Silver", "Pop & Synthwave", "IN REVISIONE", isSelected: true),
            
            Container(
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: const DecorationImage(image: NetworkImage("https://via.placeholder.com/400x200"), fit: BoxFit.cover)),
              child: Center(child: Icon(Icons.play_circle_fill, size: 60, color: Colors.white.withOpacity(0.8))),
            ),
            const SizedBox(height: 20),
            const Text("Luna Silver", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("VOCALIST & PRODUCER", style: TextStyle(color: Color(0xFFD68BFF), fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _buildActionButton("Rifiuta", Colors.white10, Colors.white)),
                const SizedBox(width: 15),
                Expanded(child: _buildActionButton("Approva Talento", const Color(0xFFD68BFF), Colors.black, icon: Icons.check_circle)),
              ],
            ),
            const SizedBox(height: 20),
            _buildCandidateCard("Marco Jazz", "Jazz & Blues Fusion", "PENDENTI"),
          ],
        ),
      ),
    );
  }

  // I metodi helper _buildStatCircle, _buildCandidateCard e _buildActionButton rimangono identici...
  Widget _buildStatCircle(String label, String value) {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: const Color(0xFF16161E), shape: BoxShape.circle, border: Border.all(color: Colors.white10)),
          child: Center(child: Text(value, style: const TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold, fontSize: 18))),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildCandidateCard(String name, String genre, String status, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(25),
        border: isSelected ? Border.all(color: const Color(0xFFD68BFF), width: 1) : null,
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 20, backgroundImage: NetworkImage("https://via.placeholder.com/100")),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(genre, style: const TextStyle(color: Colors.grey, fontSize: 11))])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
            child: Text(status, style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color bg, Color text, {IconData? icon}) {
    return Container(
      height: 55,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (icon != null) Icon(icon, size: 16, color: text), if (icon != null) const SizedBox(width: 8), Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold))])),
    );
  }
}