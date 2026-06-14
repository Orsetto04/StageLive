import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stagelive/services/auth_service.dart';
import 'package:stagelive/ui/auth/ClassificaLiveView.dart';
import 'package:stagelive/ui/auth/ScalettaLiveView.dart';
import 'EventsView.dart';


class EventStaffDashboard extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final bool inizialmenteAutorizzato;
  const EventStaffDashboard({super.key, required this.eventId, required this.eventTitle, required this.inizialmenteAutorizzato});

  @override
  State<EventStaffDashboard> createState() => _EventStaffDashboardState();
}

class _EventStaffDashboardState extends State<EventStaffDashboard> {
  int _currentIndex = 0;
  late bool _isAccessGranted;
  bool _isLoading = true; // Stato per verificare l'accesso dello staff
  final TextEditingController _codeController = TextEditingController(); // Controller per il campo di testo

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

    @override
  void initState() {
    super.initState();
    _controllaAccessoAutomatico(); 
    _isAccessGranted = widget.inizialmenteAutorizzato;
  }

  Future<void> _controllaAccessoAutomatico() async {
    try {
      final String? myUid = AuthService().currentUid; // Recupera l'UID (usa il tuo metodo o FirebaseAuth)
      
      if (myUid != null) {
        var doc = await FirebaseFirestore.instance
            .collection('staff')
            .doc('${myUid}_${widget.eventId}')
            .get();

        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          // Se esiste ed è impostato su true, diamo l'accesso direttamente
          if (data['autorizzato'] == true) {
            setState(() {
              _isAccessGranted = true;
            });
          }
        }
      }
    } catch (e) {
      print("Errore durante il controllo automatico dello staff: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _verificaCodiceStaff() async {
    String codiceInserito = _codeController.text.trim();
    if (codiceInserito.isEmpty) return;

    setState(() {
      _isLoading = true; 
    });

    try {
      var eventDoc = await FirebaseFirestore.instance
          .collection('eventi')
          .doc(widget.eventId) // ID dell'evento corrente
          .get();

      if (eventDoc.exists) {
        var eventData = eventDoc.data() as Map<String, dynamic>;
        
        // Se nel database l'hai chiamato 'staffCode' o 'codice', modifica la riga qui sotto:
        String? codiceReale = eventData['staffCode']?.toString(); 

        // 2. Confrontiamo il codice inserito dall'utente con quello unico dell'evento
        if (codiceReale != null && codiceReale == codiceInserito) {
          
          final String? myUid = AuthService().currentUid; 
          
          if (myUid != null) {
            await FirebaseFirestore.instance
                .collection('eventi')
                .doc(widget.eventId)
                .collection('staff')
                .doc(myUid) // Salviamo con l'UID dell'utente così il suo accesso diventa nominale e definitivo
                .set({
                  'uid': myUid,
                  'ruolo': 'Staff',
                  'autorizzato': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });

            setState(() {
              _isAccessGranted = true;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Accesso Staff autorizzato!"), backgroundColor: Colors.green),
              );
            }
          }
        } else {
          // 3. Se il codice non corrisponde
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Codice Staff errato o non valido!"), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Evento non trovato nel database"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print("Errore durante la verifica del codice staff: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // SE L'ACCESSO NON È STATO CONFERMATO: Mostra la schermata di inserimento codice
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0B0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD68BFF)), // Mostra la rotella viola
        ),
      );
    }
    
    if (!_isAccessGranted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0B0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF16161E),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 60, color: Color(0xFFD68BFF)),
                  const SizedBox(height: 15),
                  Text(
                    widget.eventTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "ACCESSO RISERVATO ALLO STAFF",
                    style: TextStyle(color: Color(0xFFD68BFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Inserisci il codice di sblocco a 6 caratteri generato dall'amministratore per accedere.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 25),
                  
                  // Campo di inserimento del codice
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "CODICE",
                      hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 0),
                      filled: true,
                      fillColor: const Color(0xFF0B0B0F),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFFD68BFF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // Pulsante di conferma
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD68BFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _verificaCodiceStaff,
                      child: const Text(
                        "CONFERMA",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // SE IL CODICE È CORRETTO: Sblocca la dashboard reale con le 4 tab in basso
    final List<Widget> _tabs = [
      ScalettaLiveView(eventId: widget.eventId, eventTitle: widget.eventTitle, ruolo: 'staff'),
      _buildListaConcorrentiView(),
      ClassificaLiveView(eventId: widget.eventId, eventTitle: widget.eventTitle, userRole: 'staff',),
      _buildProfiloStaff(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.eventTitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("PANNELLO STAFF", style: TextStyle(color: Color(0xFFD68BFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
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
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Concorrenti"),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "Classifica"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profilo"),

        ],
      ),
    );
  }

  // 1. VISTA SCALETTA (Recupera dal database i performer confermati)
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
            String brano = data['brano'] ?? 'In attesa di brano';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFD68BFF).withOpacity(0.15), 
                    child: Text("${index + 1}", style: const TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold))
                  ),
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

 // 2. LISTA CONCORRENTI  
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
        if (docs.isEmpty) return const Center(child: Text("Nessun concorrente presente", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String nome = data['nome'] ?? data['username'] ?? 'Concorrente';
            String brano = data['brano'] ?? 'Nessun brano specificato';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _mostraDettagliConcorrente(context, data), // 🌟 Apre il dettaglio al click
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161E), 
                    borderRadius: BorderRadius.circular(15), 
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_border, color: Color(0xFFD68BFF), size: 24),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nome, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(brano, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16), // Indicatore visivo di click
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostraDettagliConcorrente(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        String nome = data['nome'] ?? 'Non specificato';
        String brano = data['brano'] ?? 'Non specificato';
        String descrizione = data['descrizione'] ?? 'Nessuna descrizione o biografia fornita.';
        String email = data['email'] ?? 'Non specificata';
        String status = data['status'] ?? 'Nessuno';

        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 25,
            right: 25,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Linea centrale estetica del BottomSheet
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Intestazione
                const Row(
                  children: [
                    Icon(Icons.assignment_ind_outlined, color: Color(0xFFD68BFF)),
                    SizedBox(width: 10),
                    Text(
                      "SCHEDA DETTAGLIATA CONCORRENTE",
                      style: TextStyle(
                        color: Color(0xFFD68BFF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Lista delle info organizzata
                _buildDetailRow("Nome Completo:", nome),
                _buildDetailRow("Brano:", brano),
                _buildDetailRow("Email:", email),
                _buildDetailRow("Stato Attuale:", status),
                
                const SizedBox(height: 15),
                const Text(
                  "Descrizione / Presentazione:",
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // Box dedicato alla descrizione estesa
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0B0F),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    descrizione,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 25),

                // Pulsante di chiusura
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B0B0F),
                      side: const BorderSide(color: Colors.white10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "CHIUDI SCHEDA",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfiloStaff() {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.all(30),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 25),
          decoration: BoxDecoration(
            color: const Color(0xFF16161E), // Stesso sfondo scuro
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFD68BFF).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.badge_rounded, 
                size: 80, 
                color: Color(0xFFD68BFF),
              ),
              const SizedBox(height: 20),
             
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD68BFF).withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "STAFF", 
                  style: TextStyle(
                    color: Color(0xFFD68BFF), 
                    fontSize: 11, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


 
}