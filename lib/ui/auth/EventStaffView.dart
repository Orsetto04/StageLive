import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stagelive/services/auth_service.dart';

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
    _controllaAccessoAutomatico(); // 🌟 Avvia il controllo appena si apre la pagina
    _isAccessGranted = widget.inizialmenteAutorizzato;
  }

  // 🌟 Nuova funzione per verificare se lo staff è già registrato ed autorizzato
  Future<void> _controllaAccessoAutomatico() async {
    try {
      final String? myUid = AuthService().currentUid; // Recupera l'UID (usa il tuo metodo o FirebaseAuth)
      
      if (myUid != null) {
        // Cerchiamo se esiste già il documento di questo utente per questo evento
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
      // In ogni caso (sia che abbia accesso o no), fermiamo il caricamento iniziale
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Funzione per verificare se il codice inserito corrisponde a quello impostato dall'admin
  void _verificaCodiceStaff() async {
    String codiceInserito = _codeController.text.trim();
    if (codiceInserito.isEmpty) return;

    // (Opzionale) Mostra un indicatore di caricamento se lo hai definito
    setState(() {
      _isLoading = true; 
    });

    try {
      // 1. Leggiamo il documento dell'evento per prendere il codice UNICO generato dall'admin
      var eventDoc = await FirebaseFirestore.instance
          .collection('eventi')
          .doc(widget.eventId) // ID dell'evento corrente
          .get();

      if (eventDoc.exists) {
        var eventData = eventDoc.data() as Map<String, dynamic>;
        
        // 🌟 NOTA: Controlla su Firestore come hai chiamato il campo del codice. 
        // Se nel database l'hai chiamato 'staffCode' o 'codice', modifica la riga qui sotto:
        String? codiceReale = eventData['staffCode']?.toString(); 

        // 2. Confrontiamo il codice inserito dall'utente con quello unico dell'evento
        if (codiceReale != null && codiceReale == codiceInserito) {
          
          // Il codice è corretto! Ora inseriamo l'utente corrente nella sottocollezione staff
          final String? myUid = AuthService().currentUid; // o FirebaseAuth.instance.currentUser?.uid
          
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

            // Sblocchiamo la visualizzazione della dashboard
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
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
              child: Row(
                children: [
                  const Icon(Icons.star_border, color: Color(0xFFD68BFF), size: 24),
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

  // 3. CLASSIFICA LIVE
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
        if (docs.isEmpty) return const Center(child: Text("Classifica non ancora disponibile", style: TextStyle(color: Colors.grey)));

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

  // 4. PROFILO STAFF (Grafica coordinata)
  Widget _buildProfiloView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xFF16161E), 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: const Color(0xFFD68BFF).withOpacity(0.3))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.badge_outlined, size: 80, color: Color(0xFFD68BFF)),
              const SizedBox(height: 15),
              const Text("Profilo Staff", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFD68BFF).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text("MEMBRO DELLO STAFF", style: TextStyle(color: Color(0xFFD68BFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const SizedBox(height: 25),
              const Text(
                "In questa sezione potrai vedere i tuoi dettagli di servizio e i permessi assegnati dall'amministratore per la gestione dell'evento.", 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)
              ),
            ],
          ),
        ),
      ),
    );
  }
}