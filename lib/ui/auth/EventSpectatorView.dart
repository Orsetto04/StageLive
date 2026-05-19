import 'package:flutter/material.dart';

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
  int _selectedIndex = 1; // Default su Scaletta

  // --- SCHERMATA SCALETTA LIVE (AGGIORNATA: VUOTA SENZA DATI SIMULATI) ---
  Widget _buildScalettaLive() {
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
          const SizedBox(height: 60),

          // AGGIORNATO: Stato vuoto pulito senza elementi finti
          const Center(
            child: Text(
              "Nessun artista in scaletta", 
              style: TextStyle(color: Colors.grey, fontSize: 15)
            ),
          ),
        ],
      ),
    );
  }

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