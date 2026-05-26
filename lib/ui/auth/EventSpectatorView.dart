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
  // 🟢 MODIFICATO: Default su 0 (Votazioni) così si apre direttamente sulla schermata di voto!
  int _selectedIndex = 0; 
  int? _selectedVote;
  // 🟢 AGGIUNTO: Tiene traccia di quale artista della lista stiamo guardando/votando
  int _currentArtistIndex = 0; 

  // --- SCHERMATA SCALETTA LIVE ---
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


// =========================================================================
  // SCHERMATA CLASSIFICA LIVE COLLEGATA A FIREBASE FIRESTORE (In tempo reale)
  // =========================================================================

 // =========================================================================
  // SCHERMATA CLASSIFICA LIVE COLLEGATA A FIREBASE FIRESTORE (In tempo reale)
  // =========================================================================

  Widget _buildClassificaLive() {
    const Color localPurple = Color(0xFFBC53EE);
    const Color localPink = Color(0xFFFA6A7F);
    const Color localMutedText = Colors.white54;

    // Utilizziamo lo StreamBuilder per ascoltare i cambiamenti della collezione 'concorrenti'
    // 🟢 MODIFICATO SOLO QUESTO: Ora punta correttamente alla sotto-collezione dell'evento corrente
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('concorrenti')
          .snapshots(),
      builder: (context, snapshot) {
        // Schermata di caricamento mentre Firebase si connette
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: localPurple));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Nessun concorrente in gara.", style: TextStyle(color: Colors.white)));
        }

        // 1. Mappiamo i documenti di Firestore in una lista locale
        List<Map<String, dynamic>> listaConcorrenti = snapshot.data!.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          double totale = data['totaleSommaVoti']?.toDouble() ?? 0.0;
          int voti = data['numeroVoti']?.toInt() ?? 0;
          
          // Calcoliamo la media matematica al volo (Evita divisioni per zero)
          double media = voti > 0 ? (totale / voti) : 0.0;

          // 🟢 MODIFICATO SOLO QUESTO: Usiamo 'nomeArte' e 'genere' coerentemente con la collezione dell'evento
          return {
            'id': doc.id,
            'nome': data['nomeArte'] ?? 'Sconosciuto',
            'categoria': data['genere'] ?? 'TALENTO',
            'foto': data['foto'] ?? 'https://via.placeholder.com/150',
            'media': media,
          };
        }).toList();

        // 2. ORDINA LA LISTA: Dal voto medio più alto al più basso
        listaConcorrenti.sort((a, b) => b['media'].compareTo(a['media']));

        // Assegniamo i primi tre posti del podio in base dei dati reali (se presenti)
        var primo = listaConcorrenti.length > 0 ? listaConcorrenti[0] : null;
        var secondo = listaConcorrenti.length > 1 ? listaConcorrenti[1] : null;
        var terzo = listaConcorrenti.length > 2 ? listaConcorrenti[2] : null;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLASSIFICA LIVE',
                style: TextStyle(color: localPink.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ecco i talenti più votati!',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
              ),
              const SizedBox(height: 12),
              const Text(
                'La community ha parlato. Questi sono gli artisti che stanno dominando lo stage stasera.',
                style: TextStyle(color: localMutedText, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 35),

              // --- IL PODIO DINAMICO (#2, #1, #3) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // SECONDO POSTO
                  Expanded(
                    child: secondo != null 
                      ? _buildPodiumItem(
                          name: secondo['nome'],
                          score: '${secondo['media'].toStringAsFixed(1)}/10',
                          rank: '2',
                          avatarRadius: 32,
                          pedestalHeight: 65,
                          accentColor: localPurple,
                          imageUrl: secondo['foto'],
                        )
                      : const SizedBox(),
                  ),
                  const SizedBox(width: 8),
                  // PRIMO POSTO
                  Expanded(
                    child: primo != null 
                      ? _buildPodiumItem(
                          name: primo['nome'],
                          score: '${primo['media'].toStringAsFixed(1)}/10',
                          rank: '1',
                          avatarRadius: 44,
                          pedestalHeight: 95,
                          accentColor: localPurple,
                          isFirst: true,
                          imageUrl: primo['foto'],
                        )
                      : const SizedBox(),
                  ),
                  const SizedBox(width: 8),
                  // TERZO POSTO
                  Expanded(
                    child: terzo != null 
                      ? _buildPodiumItem(
                          name: terzo['nome'],
                          score: '${terzo['media'].toStringAsFixed(1)}/10',
                          rank: '3',
                          avatarRadius: 28,
                          pedestalHeight: 50,
                          accentColor: const Color(0xFFD32F2F),
                          imageUrl: terzo['foto'],
                        )
                      : const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // --- SEZIONE TOP PERFORMER (#4 in poi) ---
              Row(
                children: [
                  const Text('TOP PERFORMER', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                ],
              ),
              const SizedBox(height: 16),

              // Generazione dinamica dal 4° posto in giù usando un ciclo For
              if (listaConcorrenti.length > 3)
                ...listaConcorrenti.sublist(3).asMap().entries.map((entry) {
                  int index = entry.key + 4; // Parte dalla posizione 4
                  var concorrente = entry.value;
                  return _buildListRow(
                    index.toString(),
                    concorrente['nome'],
                    concorrente['categoria'].toString().toUpperCase(),
                    concorrente['media'].toStringAsFixed(1),
                    concorrente['foto'],
                  );
                }).toList()
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("Nessun altro concorrente in lista", style: TextStyle(color: Colors.white38, fontSize: 13))),
                ),

              const SizedBox(height: 40),

              // --- SEZIONE CALL TO ACTION FINALE ---
              Center(
                child: Column(
                  children: [
                    const Text('Non hai ancora votato?', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Ogni voto conta per la classifica finale!', style: TextStyle(color: localMutedText, fontSize: 13, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(colors: [localPurple, localPink], begin: Alignment.centerLeft, end: Alignment.centerRight),
                        boxShadow: [BoxShadow(color: localPurple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Logica gestita da te per tornare alla votazione
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.assignment_return_outlined, color: Colors.black, size: 20),
                            SizedBox(width: 10),
                            Text('TORNA ALLA VOTAZIONE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }
  // AGGIORNAMENTO HELPER: Accetta l'URL dell'immagine reale da Firebase
  Widget _buildPodiumItem({
    required String name,
    required String score,
    required String rank,
    required double avatarRadius,
    required double pedestalHeight,
    required Color accentColor,
    required String imageUrl,
    bool isFirst = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: isFirst ? 2.5 : 1.5),
                boxShadow: isFirst ? [BoxShadow(color: accentColor.withOpacity(0.35), blurRadius: 18, spreadRadius: 2)] : null,
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: const Color(0xFF1E1B28),
                backgroundImage: NetworkImage(imageUrl),
              ),
            ),
            Positioned(
              top: 0,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: accentColor,
                child: isFirst
                    ? const Icon(Icons.star, size: 11, color: Colors.white)
                    : Text('#$rank', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1),
        const SizedBox(height: 3),
        Text(score, style: const TextStyle(color: Color(0xFFFA6A7F), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: pedestalHeight,
          decoration: const BoxDecoration(
            color: Color(0xFF14121F),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Center(
            child: Text(
              rank,
              style: TextStyle(color: Colors.white.withOpacity(0.04), fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // AGGIORNAMENTO HELPER: Accetta l'URL dell'immagine reale da Firebase
  Widget _buildListRow(String rank, String name, String category, String vote, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11.0),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(rank, style: const TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFF1E1B28),
            backgroundImage: NetworkImage(imageUrl),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(category, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(vote, style: const TextStyle(color: Color(0xFFBC53EE), fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('VOTO', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  


  // --- SCHERMATA VOTAZIONI LIVE (OTTIMIZZATA MULTI-CONCORRENTE) ---
  Widget _buildVotazioniLive() {
    return StreamBuilder<QuerySnapshot>(
      // Ascolta in tempo reale tutti i concorrenti inseriti nell'evento
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('concorrenti')
          .orderBy('timestamp', descending: true) // I più recenti appaiono per primi
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Nessun concorrente disponibile per la votazione",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          );
        }

        // Lista di tutti i documenti dei concorrenti approvati
        final docs = snapshot.data!.docs;
        
        // Controllo di sicurezza: se la lista si accorcia, resetta l'indice a 0 per evitare crash
        if (_currentArtistIndex >= docs.length) {
          _currentArtistIndex = 0;
        }

        // Estrazione del concorrente attualmente selezionato dalle frecce
        final artistDoc = docs[_currentArtistIndex];
        final artistData = artistDoc.data() as Map<String, dynamic>;
        final String artistId = artistDoc.id;
        final String nomeArte = artistData['nomeArte'] ?? "Artista";
        final String categoria = artistData['genere'] ?? "Categoria";

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- INTESTAZIONE SCHERMATA ---
              const Text(
                "LIVE SHOW IN CORSO",
                style: TextStyle(
                  color: Color(0xFFFF7B93),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 5),
              
              // Riga intestazione con contatore artisti attivo se sono più di uno
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Vota Ora!",
                    style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  if (docs.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        "${_currentArtistIndex + 1} di ${docs.length}",
                        style: const TextStyle(color: Color(0xFFD68BFF), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 25),

              // --- CARD CON FONDO GRAFICO ED ELEMENTI DI NAVIGAZIONE ---
              Container(
                width: double.infinity,
                height: 340,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: const Color(0xFF16161E),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=1000'),
                    fit: BoxFit.cover,
                    opacity: 0.35,
                  ),
                ),
                child: Stack(
                  children: [
                    // Sfumatura scura inferiore per garantire leggibilità
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                        ),
                      ),
                    ),
                    
                    // Contenuto testuale dell'artista
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8C1D40).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFF7B93), width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(color: Color(0xFFFF7B93), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  "IN SCENA",
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            nomeArte,
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Categoria: $categoria",
                            style: const TextStyle(color: Colors.white60, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    // 🟢 FRECCIA SINISTRA (Mostrata solo se non è il primo artista)
                    if (_currentArtistIndex > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _currentArtistIndex--;
                                  _selectedVote = null; // Resetta il voto per il nuovo artista scelto
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                    // 🟢 FRECCIA DESTRA (Mostrata solo se ci sono altri artisti successivi)
                    if (_currentArtistIndex < docs.length - 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _currentArtistIndex++;
                                  _selectedVote = null; // Resetta il voto per il nuovo artista scelto
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              // --- TESTI GUIDA VALUTAZIONE ---
              const Center(
                child: Text(
                  "Come valuti questa performance?",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  "Esprimi il tuo giudizio da 1 a 10.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 25),

              // --- GRIGLIA DI VOTO 1-10 ---
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(10, (index) {
                  int voteValue = index + 1;
                  bool isSelected = _selectedVote == voteValue;

                  return InkWell(
                    onTap: () => setState(() => _selectedVote = voteValue),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 96) / 5,
                      height: 55,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFD68BFF) : const Color(0xFF16161E),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: isSelected ? [
                          BoxShadow(color: const Color(0xFFD68BFF).withOpacity(0.4), blurRadius: 12, spreadRadius: 2)
                        ] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "$voteValue",
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 35),

              // --- BOTTONE GRADIENTE DI INVIO VOTO ---
              InkWell(
                onTap: _selectedVote == null ? null : () async {
                  // Questo codice va dentro l'onPressed del pulsante "INVIA VOTO"
void inviaVotoSpettatore(String concorrenteId, double votoScelto) async {
  // Riferimento al documento del concorrente votato
  DocumentReference concorrenteRef = FirebaseFirestore.instance
      .collection('concorrenti')
      .doc(concorrenteId);

  try {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // 1. Leggi i dati attuali del concorrente dal database
      DocumentSnapshot snapshot = await transaction.get(concorrenteRef);

      if (!snapshot.exists) {
        throw Exception("Il concorrente non esiste!");
      }

      // 2. Recupera i valori attuali (se non esistono nel db, partono da 0)
      double totaleAttuale = (snapshot.data() as Map<String, dynamic>)['totaleSommaVoti']?.toDouble() ?? 0.0;
      int numeroVotiAttuale = (snapshot.data() as Map<String, dynamic>)['numeroVoti']?.toInt() ?? 0;

      // 3. Calcola i nuovi valori aggiungendo il voto di questo spettatore
      double nuovoTotale = totaleAttuale + votoScelto;
      int nuovoNumeroVoti = numeroVotiAttuale + 1;

      // 4. Salva i dati aggiornati nel database
      transaction.update(concorrenteRef, {
        'totaleSommaVoti': nuovoTotale,
        'numeroVoti': nuovoNumeroVoti,
      });
    });

    // Mostra un feedback di successo (es. uno SnackBar) senza alterare la UI grafica
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voto inviato con successo! Classifica aggiornata.')),    );
  } catch (e) {
    print("Errore durante l'invio del voto: $e");
  }
   setState() {
      _selectedIndex = 1; // Supponendo che la classifica sia all'indice 1 del tuo Tab o PageView
    }
}
                },
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: _selectedVote == null 
                        ? null 
                        : const LinearGradient(
                            colors: [Color(0xFFD68BFF), Color(0xFFFF7B93)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: _selectedVote == null ? Colors.white10 : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Invia il tuo Voto",
                        style: TextStyle(
                          color: _selectedVote == null ? Colors.white38 : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.send,
                        size: 18,
                        color: _selectedVote == null ? Colors.white38 : Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: const LinearProgressIndicator(
                  value: 0.84,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E2C60)),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildVotazioniLive();
      case 1:
        return _buildScalettaLive();
      case 2:
        return _buildClassificaLive();
      case 3:
        return const Center(child: Text("Profilo Spettatore\n(Schermata in arrivo)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)));
      default:
        return _buildVotazioniLive();
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