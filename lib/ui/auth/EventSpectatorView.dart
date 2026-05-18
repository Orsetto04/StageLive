import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventSpectatorView extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventSpectatorView({
    super.key, 
    required this.eventId, 
    required this.eventTitle
  });

  @override
  State<EventSpectatorView> createState() => _EventSpectatorViewState();
}

class _EventSpectatorViewState extends State<EventSpectatorView> {
  // Impostato di default su 1 (Scaletta) come richiesto per vedere subito il layout
  int _selectedIndex = 1;

  // --- SCHERMATA SCALETTA LIVE (DALLA FOTO) ---
  Widget _buildScalettaLive() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('candidature')
          .where('eventId', isEqualTo: widget.eventId)
          .where('status', isEqualTo: 'ACCETTATA') // Prende automaticamente i candidati approvati
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
                "LIVE PERFORMANCE", 
                style: TextStyle(color: Color(0xFFD68BFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)
              ),
              const SizedBox(height: 5),
              const Text(
                "Scaletta Live", 
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 15),
              
              // Badge viola "Live Now" dinamico
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD68BFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Live Now: ${widget.eventTitle}", 
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)
                ),
              ),
              const SizedBox(height: 30),

              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text("Nessun artista in scaletta al momento.", style: TextStyle(color: Colors.grey))),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    
                    // Formattazione numero d'ordine (01, 02, etc.)
                    String orderNum = (index + 1).toString().padLeft(2, '0');
                    
                    // Simulazione degli stati della scaletta per riflettere il form grafico
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
                          // Numero d'ordine e icona trascinamento simulata
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
                          
                          // Avatar Artista
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFF0B0B0F),
                            child: Icon(Icons.person, color: Color(0xFFD68BFF), size: 28),
                          ),
                          const SizedBox(width: 20),
                          
                          // Dettagli Artista (Nome d'arte, brano/genere, durata)
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
                                  "04:30", // Placeholder durata standard
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)
                                ),
                              ],
                            ),
                          ),
                          
                          // Stato della Performance
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

  // --- SELETTORE DELLE PAGINE DEL BOTTOM MENU ---
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Benvenuto nell'Arena di\n${widget.eventTitle}", 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.4)
                ),
                const SizedBox(height: 20),
                const Text("Votazioni aperte non appena l'artista salirà sul palco!", style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        );
      case 1:
        return _buildScalettaLive();
      case 2:
        return const Center(child: Text("Classifica Generale\n(Schermata in arrivo)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)));
      case 3:
        return const Center(child: Text("Profilo Spettatore\n(Schermata in arrivo)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)));
      default:
        return _buildScalettaLive();
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
        title: const Text("StageLive Spettatore", style: TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
      
      // --- BOTTOM NAVIGATION BAR SPETTATORE ---
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: const Color(0xFF16161E)),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFD68BFF),
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.how_to_vote_outlined), activeIcon: Icon(Icons.how_to_vote), label: "Votazioni"),
            BottomNavigationBarItem(icon: Icon(Icons.queue_music_outlined), activeIcon: Icon(Icons.queue_music), label: "Scaletta"),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), activeIcon: Icon(Icons.leaderboard), label: "Classifica"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profilo"),
          ],
        ),
      ),
    );
  }
}