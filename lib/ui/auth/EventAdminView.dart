import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- QUESTO RISOLVE L'ERRORE

class EventAdminView extends StatefulWidget {
  const EventAdminView({super.key});

  @override
  State<EventAdminView> createState() => _EventAdminViewState();
}

class _EventAdminViewState extends State<EventAdminView> {
  int _selectedIndex = 2; // "Talenti" selezionato come nell'immagine

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("StageLive", style: TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold)),
        actions: const [Icon(Icons.notifications_none, color: Colors.white), SizedBox(width: 10), CircleAvatar(radius: 15, backgroundImage: NetworkImage("https://via.placeholder.com/150")), SizedBox(width: 15)],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Questa riga ora funziona correttamente grazie all'import
        stream: FirebaseFirestore.instance.collection('candidature').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Errore Caricamento", style: TextStyle(color: Colors.white)));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));

          final candidature = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Revisione Candidati", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // Statistiche
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _buildStatCircle("In Attesa", "${candidature.length}"),
                  const SizedBox(width: 30),
                  _buildStatCircle("Oggi", "54"),
                ]),
                const SizedBox(height: 30),
                
                // Lista dinamica da Firebase
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: candidature.length,
                  itemBuilder: (context, index) {
                    var doc = candidature[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    return _buildCandidateCard(
                      data['nomeArte'] ?? "N/A",
                      data['genere'] ?? "N/A",
                      data['status'] ?? "PENDENTE",
                      docId: doc.id,
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCandidateCard(String name, String genre, String status, {required String docId}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Row(children: [
            const CircleAvatar(radius: 25, backgroundImage: NetworkImage("https://via.placeholder.com/150")),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(genre, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)), child: Text(status, style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Rifiuta", style: TextStyle(color: Colors.white)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD68BFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Approva", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
          ])
        ],
      ),
    );
  }

  Widget _buildStatCircle(String label, String value) {
    return Column(children: [
      Container(width: 60, height: 60, decoration: BoxDecoration(color: const Color(0xFF16161E), shape: BoxShape.circle, border: Border.all(color: Colors.white10)), child: Center(child: Text(value, style: const TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold, fontSize: 18)))),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
    ]);
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0B0B0F),
      selectedItemColor: const Color(0xFFD68BFF),
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (i) => setState(() => _selectedIndex = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: "LIVE"),
        BottomNavigationBarItem(icon: Icon(Icons.reorder), label: "SCALETTA"),
        BottomNavigationBarItem(icon: Icon(Icons.stars), label: "TALENTI"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "PROFILO"),
      ],
    );
  }
}