import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stagelive/services/auth_service.dart';
import 'EventAdminView.dart';
import 'EventCompetitorView.dart';
import 'EventSpectatorView.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});
  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  final AuthService _auth = AuthService();

  void _eliminaEvento(String eventId, bool isAdmin) async {
    final String? myUid = _auth.currentUid;
    if (myUid == null) return;

    try {
      if (isAdmin) {
        await FirebaseFirestore.instance.collection('eventi').doc(eventId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Evento eliminato definitivamente dall'amministratore"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('eventi').doc(eventId).update({
          'hiddenBy': FieldValue.arrayUnion([myUid])
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Evento rimosso dalla tua lista"), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore durante l'eliminazione: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // --- MODIFICATO: Gestione stato CONFERMATO per saltare la candidatura ---
  void _gestisciAccessoEvento(String eventId, String eventTitle, String adminId) async {
    final String? myUid = _auth.currentUid;

    if (myUid == adminId) {
      _showParticipationDialog(context, eventId, eventTitle, adminId);
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('candidature')
          .where('uid', isEqualTo: myUid)
          .where('eventId', isEqualTo: eventId)
          .get();

      if (query.docs.isNotEmpty) {
        var doc = query.docs.first;
        var data = doc.data();
        String status = (data['status'] ?? 'PENDENTE').toString().toUpperCase();
        String docId = doc.id;

        if (status == 'PENDENTE') {
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const WaitingScreen()));
          }
        } else if (status == 'APPROVATA' || status == 'ACCETTATA') {
          if (mounted) {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => AcceptedScreen(eventId: eventId, eventTitle: eventTitle, docId: docId)
              ),
            );
          }
        } else if (status == 'CONFERMATO') {
          // Se è già confermato entra direttamente nell'arena con il menu in basso
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventCompetitorDashboard(eventId: eventId, eventTitle: eventTitle),
              ),
            );
          }
        } else if (status == 'RIFIUTATA') {
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RejectedScreen()));
          }
        }
      } else {
        _showParticipationDialog(context, eventId, eventTitle, adminId);
      }
    } catch (e) {
      _showParticipationDialog(context, eventId, eventTitle, adminId);
    }
  }

  void _checkCandidaturaEEntraSpettatore(String eventId, String eventTitle) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('candidature')
          .where('uid', isEqualTo: _auth.currentUid)
          .where('eventId', isEqualTo: eventId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        String status = (data['status'] ?? 'PENDENTE').toString().toUpperCase();
        if (status == 'PENDENTE' || status == 'APPROVATA' || status == 'ACCETTATA' || status == 'CONFERMATO') {
          if (mounted) {
            Navigator.pop(context); 
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(backgroundColor: Colors.orange, content: Text("Accesso negato: hai una candidatura attiva o sei già nel cast di questo evento."), behavior: SnackBarBehavior.floating),
            );
          }
          return;
        }
      }
      _iscrivitiSpettatore(eventId, eventTitle);
    } catch (e) {
      _iscrivitiSpettatore(eventId, eventTitle);
    }
  }

  void _iscrivitiSpettatore(String eventId, String eventTitle) async {
    try {
      await _auth.partecipaEvento(eventId: eventId, ruolo: "Spettatore");
      if (mounted) {
        Navigator.pop(context); 
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventSpectatorView(eventId: eventId, eventTitle: eventTitle),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventSpectatorView(eventId: eventId, eventTitle: eventTitle),
          ),
        );
      }
    }
  }

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

  void _accessoGestionale(String ruolo, String eventId) {
    Navigator.pop(context); 
    if (ruolo == "Amministratore") {
      Navigator.push(context, MaterialPageRoute(builder: (context) => EventAdminView(eventId: eventId)));
    }
  }

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
              const SizedBox(height: 30),
              if (isAdmin) ...[
                _roleButton(context, "Gestisci Staff", Icons.badge, Colors.white12, () => _accessoGestionale("Staff", eventId)),
                const SizedBox(height: 15),
                _roleButton(context, "Pannello Amministratore", Icons.admin_panel_settings, const Color(0xFFD68BFF), () => _accessoGestionale("Amministratore", eventId), textColor: Colors.black),
              ] else ...[
                _roleButton(context, "Entra come Spettatore", Icons.visibility, Colors.white12, () => _checkCandidaturaEEntraSpettatore(eventId, eventTitle)),
                const SizedBox(height: 15),
                _roleButton(context, "Candidati come Concorrente", Icons.mic, const Color(0xFFD68BFF), () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EventCompetitorView(eventId: eventId)));
                }, textColor: Colors.black),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? myUid = _auth.currentUid;

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
        stream: FirebaseFirestore.instance.collection('eventi').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
          
          final docs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            List<dynamic> hiddenBy = data['hiddenBy'] ?? [];
            return !hiddenBy.contains(myUid);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 25, top: 10),
                  child: Text("Eventi", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                );
              }

              final itemIndex = index - 1;
              var data = docs[itemIndex].data() as Map<String, dynamic>;
              final String eventId = docs[itemIndex].id;
              final bool isAdmin = (myUid == data['adminId']);

              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: GestureDetector(
                  onTap: () => _gestisciAccessoEvento(eventId, data['titolo'], data['adminId']),
                  child: _buildEventCard(
                    title: data['titolo'], 
                    date: data['data'], 
                    location: data['luogo'], 
                    isAdmin: isAdmin,
                    onDelete: () => _eliminaEvento(eventId, isAdmin),
                  ),
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

  Widget _buildEventCard({required String title, required String date, required String location, bool isAdmin = false, required VoidCallback onDelete}) {
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
              Expanded(
                child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  if (isAdmin) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFD68BFF), borderRadius: BorderRadius.circular(5)),
                      child: const Text("ADMIN", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                  ],
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: onDelete,
                  ),
                ],
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

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(alignment: Alignment.center, children: [
              Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFD68BFF).withOpacity(0.15), blurRadius: 40, spreadRadius: 10)])),
              const Icon(Icons.hourglass_empty_rounded, color: Color(0xFFD68BFF), size: 75),
            ]),
            const SizedBox(height: 40),
            const Text("QUASI PRONTO...", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFD68BFF), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3)),
            const SizedBox(height: 15),
            const Text("Il tuo talento è in revisione", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("I direttori artistici stanno valutando i tuoi profili social. Riceverai un responso direttamente qui a breve. Scalda la voce!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5)),
            const SizedBox(height: 60),
            TextButton(onPressed: () => Navigator.pop(context), child: Text("TORNA ALLA LISTA EVENTI", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600, decoration: TextDecoration.underline))),
          ],
        ),
      ),
    );
  }
}

class RejectedScreen extends StatelessWidget {
  const RejectedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(alignment: Alignment.center, children: [
              Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.15), blurRadius: 40, spreadRadius: 10)])),
              const Icon(Icons.gpp_bad_outlined, color: Colors.redAccent, size: 75),
            ]),
            const SizedBox(height: 40),
            const Text("ESITO REVISIONE", textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3)),
            const SizedBox(height: 15),
            const Text("Candidatura non approvata", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("Purtroppo la tua candidatura non rispecchia i requisiti richiesti per questo evento dallo staff. Non fermarti, continua a fare musica!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5)),
            const SizedBox(height: 60),
            TextButton(onPressed: () => Navigator.pop(context), child: Text("TORNA ALLA LISTA EVENTI", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600, decoration: TextDecoration.underline))),
          ],
        ),
      ),
    );
  }
}

// --- MODIFICATO: ACCEPTED SCREEN CON AGGIORNAMENTO STATO FIRESTORE ---
class AcceptedScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  final String docId; 

  const AcceptedScreen({
    super.key, 
    required this.eventId, 
    required this.eventTitle,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(alignment: Alignment.center, children: [
              Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFD68BFF).withOpacity(0.20), blurRadius: 40, spreadRadius: 10)])),
              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFD68BFF), size: 75),
            ]),
            const SizedBox(height: 40),
            const Text("ESITO REVISIONE", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFD68BFF), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3)),
            const SizedBox(height: 15),
            const Text("Candidatura approvata!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("Congratulazioni! La tua candidatura ha superato le selezioni ed è stata ufficialmente accettata dallo staff. Sei pronto a salire sul palco?", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5)),
            const SizedBox(height: 60),
            TextButton(
              onPressed: () async {
                try {
                  // Cambia lo stato sul DB in CONFERMATO per salvare la scelta definitivamente
                  await FirebaseFirestore.instance
                      .collection('candidature')
                      .doc(docId)
                      .update({'status': 'CONFERMATO'});
                } catch (e) {
                  print("Errore aggiornamento: $e");
                }

                if (context.mounted) {
                  // Porta alla dashboard principale con il menu sotto
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventCompetitorDashboard(eventId: eventId, eventTitle: eventTitle),
                    ),
                  );
                }
              }, 
              child: const Text(
                "ENTRA NEL CAST", 
                style: TextStyle(color: Color(0xFFD68BFF), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- NUOVO: DASHBOARD DEL CONCORRENTE CON MENU IN BASSO ---
class EventCompetitorDashboard extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventCompetitorDashboard({super.key, required this.eventId, required this.eventTitle});

  @override
  State<EventCompetitorDashboard> createState() => _EventCompetitorDashboardState();
}

class _EventCompetitorDashboardState extends State<EventCompetitorDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _tabs = [
      _buildScalettaView(),
      _buildListaConcorrentiView(),
      _buildClassificaView(),
      _buildProfiloView(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.eventTitle, style: const TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF16161E),
        selectedItemColor: const Color(0xFFD68BFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: "Scaletta"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Concorrenti"),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "Classifica"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profilo"),
        ],
      ),
    );
  }

  // 1. SCALETTA (Stessa logica e grafica degli spettatori)
  Widget _buildScalettaView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('candidature')
          .where('eventId', isEqualTo: widget.eventId)
          .where('status', whereIn: ['APPROVATA', 'ACCETTATA', 'CONFERMATO'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Nessun artista in scaletta", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String nome = data['nome'] ?? data['username'] ?? 'Artista';
            String brano = data['brano'] ?? 'In attesa di scaletta';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: const Color(0xFFD68BFF).withOpacity(0.2), child: Text("${index + 1}", style: const TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold))),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nome, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(brano, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 2. LISTA CONCORRENTI (Mostra tutti i concorrenti approvati)
  Widget _buildListaConcorrentiView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('candidature')
          .where('eventId', isEqualTo: widget.eventId)
          .where('status', whereIn: ['APPROVATA', 'ACCETTATA', 'CONFERMATO'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Nessun concorrente nel cast", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String nome = data['nome'] ?? data['username'] ?? 'Concorrente';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFD68BFF), size: 24),
                  const SizedBox(width: 15),
                  Text(nome, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 3. CLASSIFICA (Stessa logica e grafica degli spettatori)
  Widget _buildClassificaView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('candidature')
          .where('eventId', isEqualTo: widget.eventId)
          .where('status', whereIn: ['APPROVATA', 'ACCETTATA', 'CONFERMATO'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Nessuna classifica disponibile", style: TextStyle(color: Colors.grey)));

        var sortedDocs = docs.toList()..sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          int votiA = dataA['voti'] ?? 0;
          int votiB = dataB['voti'] ?? 0;
          return votiB.compareTo(votiA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            var data = sortedDocs[index].data() as Map<String, dynamic>;
            String nome = data['nome'] ?? data['username'] ?? 'Artista';
            int voti = data['voti'] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text("#${index + 1}", style: TextStyle(color: index < 3 ? const Color(0xFFD68BFF) : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 15),
                      Text(nome, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text("$voti Punti", style: const TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 4. PROFILO (Placeholder grafico coordinato)
  Widget _buildProfiloView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD68BFF).withOpacity(0.3))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle, size: 80, color: Color(0xFFD68BFF)),
              const SizedBox(height: 15),
              const Text("Il Tuo Profilo", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFD68BFF).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text("CONCORRENTE NEL CAST", style: TextStyle(color: Color(0xFFD68BFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const SizedBox(height: 25),
              const Text("Sezione profilo in fase di sviluppo. Qui potrai gestire le tue tracce e i tuoi dettagli social!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}