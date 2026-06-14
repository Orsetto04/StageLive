import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stagelive/ui/auth/ClassificaLiveView.dart';
import 'package:stagelive/ui/auth/ScalettaLiveView.dart';


class EventAdminView extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  const EventAdminView({super.key, required this.eventId, required this.eventTitle});

  @override
  State<EventAdminView> createState() => _EventAdminViewState();
}

class _EventAdminViewState extends State<EventAdminView> {
  int _selectedIndex = 1; // Default su Candidature

  
  
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

            return _CandidaturaItemCard(
              data: data,
              docId: docId,
              eventId: widget.eventId,
            );
          },
        );
      },
    );
  }

 Widget _buildProfiloAdmin() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('eventi').doc(widget.eventId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
        }

        var data = snapshot.data?.data() as Map<String, dynamic>?;
        String codiceStaff = data?['staffCode'] ?? "------";
        
        // Sincronizzazione dello stato della classifica dal DB
        bool isClassificaPubblicata = data?['isRankingPublished'] ?? false;
        
        // Sincronizzazione dello stato del televoto dal DB
        bool isTelevotoAperto = data?['isTelevotoAperto'] ?? false;

        // Sincronizzazione dello stato delle candidature dal DB
        bool isCandidatureAperte = data?['isCandidatureAperte'] ?? false;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
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
                            const SizedBox(width: 40), 
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
              const SizedBox(height: 25),

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
                        Icon(Icons.leaderboard_outlined, color: Color(0xFFD68BFF), size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Classifica Evento",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      isClassificaPubblicata 
                          ? "La classifica è attualmente VISIBILE a tutti i partecipanti dell'evento."
                          : "La classifica è NASCOSTA. Clicca il pulsante qui sotto per pubblicarla e renderla visibile a tutti.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 25),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isClassificaPubblicata ? const Color(0xFF221526) : const Color(0xFFD68BFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: isClassificaPubblicata 
                                ? const BorderSide(color: Colors.redAccent, width: 1) 
                                : BorderSide.none,
                          ),
                        ),
                        onPressed: () => _gestisciPubblicazioneClassifica(isClassificaPubblicata),
                        icon: Icon(
                          isClassificaPubblicata ? Icons.visibility_off : Icons.emoji_events, 
                          color: isClassificaPubblicata ? Colors.redAccent : Colors.black,
                        ),
                        label: Text(
                          isClassificaPubblicata ? "NASCONDI CLASSIFICA" : "PUBBLICA CLASSIFICA",
                          style: TextStyle(
                            color: isClassificaPubblicata ? Colors.redAccent : Colors.black, 
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

           
        
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
                        Icon(Icons.how_to_vote_outlined, color: Color(0xFFD68BFF), size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Televoto Evento",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      isTelevotoAperto 
                          ? "Il televoto è attualmente APERTO a tutti i partecipanti dell'evento."
                          : "Il televoto è CHIUSO. Clicca il pulsante qui sotto per aprirlo e consentire le votazioni.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 25),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          // Se è aperto diventa scuro, se è chiuso diventa viola pieno
                          backgroundColor: isTelevotoAperto ? const Color(0xFF221526) : const Color(0xFFD68BFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: isTelevotoAperto 
                                ? const BorderSide(color: Colors.redAccent, width: 1) 
                                : BorderSide.none,
                          ),
                        ),
                        onPressed: () => _gestisciTelevoto(isTelevotoAperto),
                        icon: Icon(
                          isTelevotoAperto ? Icons.gavel_outlined : Icons.how_to_vote, 
                          color: isTelevotoAperto ? Colors.redAccent : Colors.black,
                        ),
                        label: Text(
                          isTelevotoAperto ? "STOP AL TELEVOTO" : "APRI IL TELEVOTO",
                          style: TextStyle(
                            color: isTelevotoAperto ? Colors.redAccent : Colors.black, 
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),


           
           
           
           
           
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
          Icon(Icons.assignment_ind_outlined, color: Color(0xFFD68BFF), size: 20),
          SizedBox(width: 10),
          Text(
            "Candidature Evento",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      const SizedBox(height: 15),
      Text(
        isCandidatureAperte 
            ? "Le candidature sono attualmente APERTE. I concorrenti possono inviare la loro iscrizione all'evento."
            : "Le candidature sono CHIUSE. Clicca il pulsante qui sotto per aprirle e consentire le iscrizioni.",
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
      ),
      const SizedBox(height: 25),
      
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            // Specchia le stesse identiche sfumature e comportamenti del televoto
            backgroundColor: isCandidatureAperte ? const Color(0xFF221526) : const Color(0xFFD68BFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: isCandidatureAperte 
                  ? const BorderSide(color: Colors.redAccent, width: 1) 
                  : BorderSide.none,
            ),
          ),
          onPressed: () => _gestisciCandidature(isCandidatureAperte),
          icon: Icon(
            isCandidatureAperte ? Icons.block_outlined : Icons.assignment_turned_in_rounded, 
            color: isCandidatureAperte ? Colors.redAccent : Colors.black,
          ),
          label: Text(
            isCandidatureAperte ? "CHIUDI CANDIDATURE" : "APRI CANDIDATURE",
            style: TextStyle(
              color: isCandidatureAperte ? Colors.redAccent : Colors.black, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    ],
  ),
)




            ],
          ),
        );
      },
    );
  }

void _gestisciCandidature(bool statoAttuale) async {
  try {
    await FirebaseFirestore.instance
        .collection('eventi')
        .doc(widget.eventId)
        .update({
          'isCandidatureAperte': !statoAttuale, // Inverte lo stato sul DB
        });
  } catch (e) {
    print("Errore durante l'aggiornamento dello stato candidature: $e");
  }
}

Future<void> _gestisciPubblicazioneClassifica(bool statoAttuale) async {
  try {
    bool nuovoStato = !statoAttuale;

    await FirebaseFirestore.instance
        .collection('eventi')
        .doc(widget.eventId)
        .update({
      'isRankingPublished': nuovoStato,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuovoStato 
                ? "Classifica PUBBLICATA con successo!" 
                : "Classifica NASCOSTA con successo!",
          ),
          backgroundColor: nuovoStato ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore durante l'aggiornamento della classifica: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

 
 
 
  
 

Future<void> _gestisciTelevoto(bool statoAttuale) async {
  try {
    // Invertiamo lo stato attuale: se è true diventa false, se è false diventa true
    bool nuovoStato = !statoAttuale;

    await FirebaseFirestore.instance
        .collection('eventi')
        .doc(widget.eventId)
        .update({
      'isTelevotoAperto': nuovoStato,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuovoStato 
                ? "Televoto APERTO con successo!" 
                : "Televoto CHIUSO con successo!",
          ),
          backgroundColor: nuovoStato ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore durante l'aggiornamento del televoto: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}



  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return ClassificaLiveView(eventId: widget.eventId, eventTitle: widget.eventTitle, onBackToVoting: () => setState(() => _selectedIndex = 1), userRole: 'admin');
      case 1:
        return _buildCandidatureList();
      case 2:
        return ScalettaLiveView(eventId: widget.eventId, eventTitle: widget.eventTitle, ruolo: 'admin'); 
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

class _CandidaturaItemCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String eventId;

  const _CandidaturaItemCard({
    required this.data,
    required this.docId,
    required this.eventId,
  });

  @override
  State<_CandidaturaItemCard> createState() => _CandidaturaItemCardState();
}

class _CandidaturaItemCardState extends State<_CandidaturaItemCard> {
  bool _isExpanded = false; // Gestisce lo stato locale di apertura/chiusura della card

  @override
  Widget build(BuildContext context) {
    var data = widget.data;
    String docId = widget.docId;

    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded; // Cambia stato al clic sulla card
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16161E), 
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _isExpanded ? const Color(0xFFD68BFF).withOpacity(0.4) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Riga Principale Intestazione (Sempre visibile)
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF0B0B0F),
                  child: Icon(Icons.person, color: Color(0xFFD68BFF)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(data['nomeArte'] ?? "N/A", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(data['genere'] ?? "N/A", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ]
                  ),
                ),
                // Freccetta animata indicatrice dello stato di espansione
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFFD68BFF),
                ),
              ],
            ),



            if (_isExpanded) ...[
              const Divider(color: Colors.white10, height: 25),
              
              // 📝 Descrizione / Bio dell'Artista
              if (data['descrizione'] != null && data['descrizione'].toString().isNotEmpty) ...[
                const Text(
                  "PRESENTAZIONE ARTISTA",
                  style: TextStyle(color: Color(0xFFD68BFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(data['descrizione'], style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                const SizedBox(height: 15),
              ],

              const Row(
                children: [
                  Icon(Icons.badge_outlined, color: Color(0xFFD68BFF), size: 16),
                  SizedBox(width: 8),
                  Text(
                    "DATI ANAGRAFICI CONCORRENTE", 
                    style: TextStyle(color: Color(0xFFD68BFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildAnagraficaRow("Nome Reale:", "${data['nome'] ?? 'N/A'} ${data['cognome'] ?? ''}"),
              _buildAnagraficaRow("Data di Nascita:", data['dataNascita'] ?? "Non fornita"),
              _buildAnagraficaRow("Luogo di Nascita:", data['luogoNascita'] ?? "Non fornito"),
              _buildAnagraficaRow("Email:", data['email'] ?? "Non fornita"),
              _buildAnagraficaRow("Telefono:", data['telefono'] ?? "Non fornito"),
              if (data['eta'] != null)
                _buildAnagraficaRow("Età:", "${data['eta']} anni"),
              _buildAnagraficaRow("Brano Scelto:", data['brano'] ?? "Non specificato"),

              if ((data['instagram'] != null && data['instagram'].toString().isNotEmpty) || 
                  (data['tiktok'] != null && data['tiktok'].toString().isNotEmpty)) ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    if (data['instagram'] != null && data['instagram'].toString().isNotEmpty) 
                      Padding(
                        padding: const EdgeInsets.only(right: 10), 
                        child: Chip(
                          label: Text("IG: ${data['instagram']}", style: const TextStyle(color: Colors.white, fontSize: 11)), 
                          backgroundColor: Colors.black
                        ),
                      ),
                    if (data['tiktok'] != null && data['tiktok'].toString().isNotEmpty) 
                      Chip(
                        label: Text("TT: ${data['tiktok']}", style: const TextStyle(color: Colors.white, fontSize: 11)), 
                        backgroundColor: Colors.black
                      ),
                  ],
                ),
              ],
            ],

            const Divider(color: Colors.white10, height: 30),
            
            // Pulsanti di Azione (Rifiuta / Accetta) - Logica originale intatta
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
      ),
    );
  }

  // Renderizza ordinatamente i campi anagrafici riga per riga
  Widget _buildAnagraficaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}