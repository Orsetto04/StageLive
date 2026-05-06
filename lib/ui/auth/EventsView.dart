import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stagelive/services/auth_service.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  final AuthService _auth = AuthService();

  // Funzione per gestire il Logout
  void _handleLogout(BuildContext context) async {
    try {
      await _auth.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore logout: $e")),
      );
    }
  }

  // DIALOG PER LA PARTECIPAZIONE (SPETTATORE / CONCORRENTE)
  void _showParticipationDialog(BuildContext context, String eventTitle) {
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
              Text(eventTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Come vuoi partecipare?", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              
              _roleButton(context, "Spettatore", Icons.visibility, Colors.white12, () {
                // Qui in futuro aggiungeremo l'UID alla lista spettatori su Firestore
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ti sei iscritto come Spettatore")));
              }),
              
              const SizedBox(height: 15),
              
              _roleButton(context, "Concorrente", Icons.star_border, const Color(0xFFD68BFF), () {
                // Qui in futuro aggiungeremo l'UID alla lista concorrenti su Firestore
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ti sei iscritto come Concorrente!")));
              }, textColor: Colors.black),
            ],
          ),
        );
      },
    );
  }

  Widget _roleButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap, {Color textColor = Colors.white}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: textColor),
        label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "StageLive",
          style: TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}), 
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF16161E),
            onSelected: (value) {
              if (value == 'logout') _handleLogout(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text("Esci", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text("DASHBOARD", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                const Text("Eventi Live", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildCreateButton(context),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // LISTA EVENTI REALI
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Nessun evento disponibile", style: TextStyle(color: Colors.white54)),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    // AVVOLGO LA CARD IN UN GESTURE DETECTOR
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: GestureDetector(
                        onTap: () => _showParticipationDialog(context, data['titolo'] ?? 'Evento'),
                        child: _buildEventCard(
                          title: data['titolo'] ?? 'Senza Titolo',
                          date: data['data'] ?? 'Data non definita',
                          location: data['luogo'] ?? 'Luogo non definito',
                          description: data['descrizione'] ?? '',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFD68BFF), Color(0xFF9D50BB)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        onPressed: () => Navigator.pushNamed(context, '/create-event'),
        child: const Text("Crea Nuovo Evento", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEventCard({required String title, required String date, required String location, required String description}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const Icon(Icons.star_outline, color: Color(0xFFD68BFF)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 15),
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(location, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 15),
              Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}