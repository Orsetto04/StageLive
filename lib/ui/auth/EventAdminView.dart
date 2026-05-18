import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventAdminView extends StatefulWidget {
  final String eventId;
  const EventAdminView({super.key, required this.eventId});

  @override
  State<EventAdminView> createState() => _EventAdminViewState();
}

class _EventAdminViewState extends State<EventAdminView> {
  int _selectedIndex = 1; // Impostato di default su 1 (Candidature) come prima

  // --- SCHERMATA 1: LISTA DELLE CANDIDATURE PENDENTI (ORIGINALE) ---
  Widget _buildCandidatureList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('candidature')
          .where('eventId', isEqualTo: widget.eventId)
          .where('status', isEqualTo: 'PENDENTE')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("Nessuna candidatura pendente", style: TextStyle(color: Colors.grey, fontSize: 15)),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (cardCtx, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(25)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF0B0B0F),
                      child: Icon(Icons.person, color: Color(0xFFD68BFF)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(data['nomeArte'] ?? "N/A", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(data['genere'] ?? "N/A", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ])),
                  ]),
                  const SizedBox(height: 15),
                  if (data['descrizione'] != null && data['descrizione'].toString().isNotEmpty) ...[
                    Text(data['descrizione'], style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 15),
                  ],
                  Row(
                    children: [
                      if (data['instagram'] != null && data['instagram'].toString().isNotEmpty) 
                        Padding(padding: const EdgeInsets.only(right: 10), child: Chip(label: Text("IG: ${data['instagram']}", style: const TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: Colors.black)),
                      if (data['tiktok'] != null && data['tiktok'].toString().isNotEmpty) 
                        Chip(label: Text("TT: ${data['tiktok']}", style: const TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: Colors.black),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 30),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        onPressed: () async {
                          final sm = ScaffoldMessenger.of(context);
                          await FirebaseFirestore.instance.collection('candidature').doc(docId).update({'status': 'RIFIUTATA'});
                          sm.showSnackBar(
                            const SnackBar(content: Text("Candidatura Rifiutata correttamente"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)
                          );
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text("Rifiuta", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD68BFF),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        onPressed: () async {
                          final sm = ScaffoldMessenger.of(context);
                          await FirebaseFirestore.instance.collection('candidature').doc(docId).update({'status': 'ACCETTATA'});
                          sm.showSnackBar(
                            const SnackBar(content: Text("Candidatura Accettata! Aggiunto al Cast"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating)
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text("Accetta", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- SCHERMATA 2: SCALETTA LIVE IDENTICA (DALLA FOTO DI BACKSTAGE CON ARTISTI ACCETTATI) ---
  Widget _buildScalettaLive() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('candidature')
          .where('eventId', isEqualTo: widget.eventId)
          .where('status', isEqualTo: 'ACCETTATA') // Stessa identica logica dello spettatore
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
        }

        final docs = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "BACKSTAGE MANAGEMENT", 
                style: TextStyle(color: Color(0xFFD68BFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)
              ),
              const SizedBox(height: 5),
              const Text(
                "Scaletta Live", 
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 30),

              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text("Nessun artista approvato in scaletta.", style: TextStyle(color: Colors.grey))),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String orderNum = (index + 1).toString().padLeft(2, '0');
                    
                    String statusText = "IN ATTESA";
                    Color statusColor = Colors.grey.withOpacity(0.4);
                    if (index == 0) {
                      statusText = "IN CORSO";
                      statusColor = const Color(0xFFD68BFF);
                    } else if (index == 1) {
                      statusText = "PROSSIMO";
                      statusColor = const Color(0xFFFF8BAB);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161E),
                        borderRadius: BorderRadius.circular(25),
                        border: index == 0 ? Border.all(color: const Color(0xFFD68BFF).withOpacity(0.3), width: 1) : null,
                      ),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.drag_indicator, color: Colors.white24, size: 16),
                              const SizedBox(height: 4),
                              Text(
                                orderNum, 
                                style: TextStyle(
                                  color: index == 0 ? const Color(0xFFD68BFF) : Colors.white38, 
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFF0B0B0F),
                            child: Icon(Icons.person, color: Color(0xFFD68BFF), size: 28),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['nomeArte'] ?? "Artista", 
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Sound (${data['genere'] ?? 'Genere'})", 
                                  style: const TextStyle(color: Colors.grey, fontSize: 13)
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "DURATA", 
                                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)
                                ),
                                const Text(
                                  "04:30", 
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusText == "IN ATTESA" ? Colors.transparent : statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusText == "IN ATTESA" ? Colors.white38 : statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // --- SELETTORE DELLE PAGINE DEL CORPO ---
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const Center(child: Text("Classifica\n(Schermata in arrivo)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)));
      case 1:
        return _buildCandidatureList();
      case 2:
        return _buildScalettaLive(); // MODIFICATO: Mostra la stessa vista grafica dello spettatore
      case 3:
        return const Center(child: Text("Profilo Admin\n(Schermata in arrivo)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)));
      default:
        return _buildCandidatureList();
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
        title: const Text("StageLive Admin", style: TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold))
      ),
      body: _buildBody(),
      
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF16161E),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFD68BFF),
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_outlined),
              activeIcon: Icon(Icons.leaderboard),
              label: "Classifica",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: "Candidature",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.queue_music_outlined),
              activeIcon: Icon(Icons.queue_music),
              label: "Scaletta",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Profilo",
            ),
          ],
        ),
      ),
    );
  }
}