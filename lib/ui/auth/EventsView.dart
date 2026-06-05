import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stagelive/services/auth_service.dart';
import 'EventAdminView.dart';
import 'EventCompetitorView.dart'; // 🌟 Leggerà EventCompetitorDashboard direttamente da qui!
import 'EventSpectatorView.dart';
import 'EventStaffView.dart'; 

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

  void _gestisciAccessoEvento(String eventId, String eventTitle, String adminId) async {
    final String? myUid = _auth.currentUid;
    if (myUid == null) return; 

    // 👑 CONTROLLO ADMIN: Se l'utente è il proprietario dell'evento, entra diretto!
    if (myUid == adminId) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventAdminView(
              eventId: eventId, 
              eventTitle: eventTitle,
            ),
          ),
        );
      }
      return; // Blocca l'esecuzione ed evita di mostrare il menu di selezione
    }

    try {
      final staffDoc = await FirebaseFirestore.instance
          .collection('eventi')
          .doc(eventId)        
          .collection('staff') 
          .doc(myUid)          
          .get();

      if (staffDoc.exists) {
        var data = staffDoc.data();
        if (data != null && data['autorizzato'] == true) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventStaffDashboard(
                  eventId: eventId, 
                  eventTitle: eventTitle,
                  inizialmenteAutorizzato: true, 
                ),
              ),
            );
          }
          return; 
        }
      }
    } catch (e) {
      print("Errore lettura Staff da Sottocollezione: $e");
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

  void _showParticipationDialog(BuildContext context, String eventId, String eventTitle, String adminId) {
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
              
              _roleButton(context, "Entra come Spettatore", Icons.visibility, Colors.white12, () => _checkCandidaturaEEntraSpettatore(eventId, eventTitle)),
              const SizedBox(height: 15),
              
              _roleButton(context, "Partecipa come Staff", Icons.badge, Colors.white12, () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventStaffDashboard(
                      eventId: eventId, 
                      eventTitle: eventTitle, 
                      inizialmenteAutorizzato: false, 
                    ),
                  ),
                );
              }),
              const SizedBox(height: 15),
              
              // 🔥 MODIFICATO: Controllo dinamico dello stato delle candidature prima dell'accesso
              _roleButton(context, "Candidati come Concorrente", Icons.mic, const Color(0xFFD68BFF), () async {
                try {
                  // Recuperiamo il documento dell'evento in tempo reale al clic
                  var eventDoc = await FirebaseFirestore.instance
                      .collection('eventi')
                      .doc(eventId)
                      .get();

                  bool candidatureAperte = eventDoc.data()?['isCandidatureAperte'] ?? false;

                  if (!context.mounted) return;

                  if (candidatureAperte) {
                    // SE APERTE: Entra normalmente nella schermata di candidatura
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EventCompetitorView(eventId: eventId)));
                  } else {
                    // SE CHIUSE: Chiude il foglio di scelta e mostra l'avviso di blocco
                    Navigator.pop(context);
                    _showCandidatureChiuseBottomSheet(context);
                  }
                } catch (e) {
                  print("Errore durante il controllo delle candidature: $e");
                }
              }, textColor: Colors.black),
            ],
          ),
        );
      },
    );
  }

  // 🛑 NUOVA SCHERMATA: Mostra l'avviso grafico quando le candidature sono bloccate
  void _showCandidatureChiuseBottomSheet(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7B93).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_outlined,
                  color: Color(0xFFFF7B93), // Rosso/Rosa acceso coerente
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Candidature Chiuse",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Siamo spiacenti, le iscrizioni come concorrente per questo evento sono state ufficialmente chiuse dall'organizzatore.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22222B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "HO CAPITO",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
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
                  await FirebaseFirestore.instance
                      .collection('candidature')
                      .doc(docId)
                      .update({'status': 'CONFERMATO'});
                } catch (e) {
                  print("Errore aggiornamento: $e");
                }

                if (context.mounted) {
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