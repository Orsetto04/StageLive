import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stagelive/services/auth_service.dart';
// AGGIUNTE LE IMPORTAZIONI DELLE DUE NUOVE PAGINE
import 'EventAdminView.dart';
import 'EventCompetitorView.dart';
class EventsView extends StatefulWidget {
  const EventsView({super.key});
  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  final AuthService _auth = AuthService();

  // 1. FUNZIONE LOGOUT
  void _handleLogout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      print(e);
    }
  }

  // 2. FUNZIONE PER ISCRIVERSI (MODIFICATA PER NAVIGAZIONE CONCORRENTE)
  void _iscriviti(String eventId, String ruolo) async {
    try {
      await _auth.partecipaEvento(eventId: eventId, ruolo: ruolo);
      
      if (mounted) {
        // CHIUDE IL POPUP IN CASO DI SUCCESSO
        Navigator.pop(context); 

        // SE IL RUOLO È CONCORRENTE, NAVIGA ALLA FOTO 1
        if (ruolo == "Concorrente") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventCompetitorView()),
          );
        }

        String messaggioBenvenuto = (ruolo == "Concorrente") 
            ? "Benvenuto, compila la tua candidatura." 
            : "Benvenuto, sei entrato come spettatore.";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(messaggioBenvenuto, style: const TextStyle(fontWeight: FontWeight.bold)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); 
        String errorePulito = e.toString().replaceAll("Exception: ", "");
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red, 
            content: Text(errorePulito, style: const TextStyle(fontWeight: FontWeight.bold)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // 3. FUNZIONE PER ACCESSO GESTIONALE (MODIFICATA PER NAVIGAZIONE ADMIN)
  void _accessoGestionale(String ruolo) {
    Navigator.pop(context); 

    // SE IL RUOLO È AMMINISTRATORE, NAVIGA ALLA FOTO 2
    if (ruolo == "Amministratore") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EventAdminView()),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFD68BFF),
        content: Text("Accesso autorizzato come $ruolo dell'evento"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 4. POPUP PARTECIPAZIONE
  void _showParticipationDialog(BuildContext context, String eventId, String eventTitle, String adminId) {
    final String? myUid = _auth.currentUid;
    final bool isAdmin = (myUid == adminId);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(eventTitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                isAdmin ? "SEI L'ORGANIZZATORE" : "PARTECIPA ALL'ARENA",
                style: TextStyle(color: isAdmin ? const Color(0xFFD68BFF) : Colors.grey[400], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              if (isAdmin) ...[
                _roleButton(context, "Gestisci come Staff", Icons.badge, Colors.white12, () => _accessoGestionale("Staff")),
                const SizedBox(height: 15),
                _roleButton(context, "Pannello Amministratore", Icons.admin_panel_settings, const Color(0xFFD68BFF), () => _accessoGestionale("Amministratore"), textColor: Colors.black),
              ] else ...[
                _roleButton(context, "Entra come Spettatore", Icons.visibility, Colors.white12, () => _iscriviti(eventId, "Spettatore")),
                const SizedBox(height: 15),
                _roleButton(context, "Candidati come Concorrente", Icons.mic, const Color(0xFFD68BFF), () => _iscriviti(eventId, "Concorrente"), textColor: Colors.black),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("StageLive", style: TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => setState(() {})),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _handleLogout),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String eventId = docs[index].id;
              bool isAdmin = _auth.currentUid == data['adminId'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: GestureDetector(
                  onTap: () => _showParticipationDialog(context, eventId, data['titolo'], data['adminId']),
                  child: _buildEventCard(title: data['titolo'], date: data['data'], location: data['luogo'], isAdmin: isAdmin),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD68BFF),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => Navigator.pushNamed(context, '/create-event'),
      ),
    );
  }

  Widget _buildEventCard({required String title, required String date, required String location, bool isAdmin = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAdmin ? const Color(0xFFD68BFF).withOpacity(0.5) : Colors.white10, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (isAdmin) 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFD68BFF), borderRadius: BorderRadius.circular(5)),
                  child: const Text("ADMIN", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text("$date • $location", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _roleButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap, {Color textColor = Colors.white}) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: onTap,
        icon: Icon(icon, color: textColor),
        label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }
}