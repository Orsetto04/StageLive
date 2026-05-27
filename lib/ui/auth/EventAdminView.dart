import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Aggiunto per abilitare l'uso della Clipboard (Appunti)
import 'package:cloud_firestore/cloud_firestore.dart';

class EventAdminView extends StatefulWidget {
  final String eventId;
  const EventAdminView({super.key, required this.eventId});

  @override
  State<EventAdminView> createState() => _EventAdminViewState();
}

class _EventAdminViewState extends State<EventAdminView> {
  int _selectedIndex = 1; // Default su Candidature

  // --- FUNZIONI PER IL CODICE STAFF ---
  
  // Genera un codice casuale alfanumerico di 6 caratteri
  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Salva il codice direttamente su Firestore nel documento dell'evento corrente
  Future<void> _creaESalvaCodiceStaff() async {
    final String nuovoCodice = _generateRandomCode();
    try {
      await FirebaseFirestore.instance
          .collection('eventi')
          .doc(widget.eventId)
          .update({'staffCode': nuovoCodice});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nuovo codice Staff generato con successo!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Errore durante la generazione del codice: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // --- SCHERMATA 1: LISTA DELLE CANDIDATURE PENDENTI (INALTERATA) ---
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
                          try {
                            await FirebaseFirestore.instance
                                .collection('candidature')
                                .doc(docId)
                                .update({'status': 'ACCETTATA'});

                            await FirebaseFirestore.instance
                                .collection('eventi') 
                                .doc(widget.eventId) 
                                .collection('concorrenti') 
                                .add({
                              'nomeArte': data['nomeArte'] ?? "N/A",
                              'genere': data['genere'] ?? "N/A",
                              'descrizione': data['descrizione'] ?? "",
                              'timestamp': FieldValue.serverTimestamp(), 
                            });

                            sm.showSnackBar(
                              const SnackBar(
                                content: Text("Candidatura Accettata! Aggiunto ai concorrenti live"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            sm.showSnackBar(
                              SnackBar(
                                content: Text("Errore durante l'approvazione: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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

  // --- SCHERMATA 2: SCALETTA LIVE ADMIN (INALTERATA) ---
  Widget _buildScalettaLive() {
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
          const SizedBox(height: 60),

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

  // --- SCHERMATA 4: PROFILO ADMIN CON GENERAZIONE E COPIA CODICE (MODIFICATA) ---
  Widget _buildProfiloAdmin() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('eventi').doc(widget.eventId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
        }

        var data = snapshot.data?.data() as Map<String, dynamic>?;
        String codiceStaff = data?['staffCode'] ?? "------";

        return SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              // Card Profilo principale dell'Admin
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161E),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFFD68BFF).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 80, color: Color(0xFFD68BFF)),
                    const SizedBox(height: 15),
                    const Text("Profilo Creatore", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFD68BFF).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Text("PROPRIETARIO EVENTO", style: TextStyle(color: Color(0xFFD68BFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Sezione per la generazione automatica del codice Staff
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161E),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, color: Color(0xFFD68BFF), size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Codice Accesso Staff",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Genera un codice casuale da condividere con il tuo staff. Tocca il codice per copiarlo rapidamente.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 25),
                    
                    // 🔥 AGGIORNATO: Box grafico del codice cliccabile che copia negli appunti
                    GestureDetector(
                      onTap: () {
                        if (codiceStaff != "------") {
                          Clipboard.setData(ClipboardData(text: codiceStaff));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Codice Staff copiato negli appunti!"),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0B0F),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFFD68BFF).withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 40), // Bilancia lo spazio dell'icona a destra per centrare il testo
                            Expanded(
                              child: Text(
                                codiceStaff,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFD68BFF),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6,
                                ),
                              ),
                            ),
                            const Icon(Icons.copy, color: Color(0xFFD68BFF), size: 20),
                            const SizedBox(width: 15),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Pulsante che richiama la generazione casuale
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD68BFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: _creaESalvaCodiceStaff,
                        icon: const Icon(Icons.refresh, color: Colors.black),
                        label: const Text(
                          "GENERA NUOVO CODICE",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ],
                ),
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
        return _buildScalettaLive(); 
      case 3:
        return _buildProfiloAdmin();
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
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), activeIcon: Icon(Icons.leaderboard), label: "Classifica"),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: "Candidature"),
            BottomNavigationBarItem(icon: Icon(Icons.queue_music_outlined), activeIcon: Icon(Icons.queue_music), label: "Scaletta"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profilo"),
          ],
        ),
      ),
    );
  }
}