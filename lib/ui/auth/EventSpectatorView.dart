import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // AGGIUNTO: Per identificare lo spettatore unico
import 'package:stagelive/ui/auth/ClassificaLiveView.dart';
import 'package:stagelive/ui/auth/ScalettaLiveView.dart';

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
  int _selectedIndex = 0; 
  int? _selectedVote;
  int _currentArtistIndex = 0; 

  // AGGIUNTI PER LA PERSISTENZA DIRETTA SU FIRESTORE
  bool _isLoadingVoti = true; // Evita il flash della lista prima del caricamento dei vecchi voti
  final List<String> _votedConcorrentiIds = [];

  @override
  void initState() {
    super.initState();
    _caricaVotiPrecedenti(); // AGGIUNTO: Carica i voti salvati nel DB appena si apre la schermata
  }

  // AGGIUNTO: Recupera la lista dei concorrenti già votati da Firestore
  Future<void> _caricaVotiPrecedenti() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonimo';
      
      final doc = await FirebaseFirestore.instance
          .collection('eventi')
          .doc(widget.eventId)
          .collection('voti_spettatori')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic>? votati = data['concorrentiVotati'];
        if (votati != null) {
          _votedConcorrentiIds.addAll(votati.map((e) => e.toString()));
        }
      }
    } catch (e) {
      print("Errore nel caricamento dei voti precedenti: $e");
    } finally {
      setState(() {
        _isLoadingVoti = false; // Fine caricamento iniziale
      });
    }
  }

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
  Widget _buildClassificaLive() {
    const Color localPurple = Color(0xFFBC53EE);
    const Color localPink = Color(0xFFFA6A7F);
    const Color localMutedText = Colors.white54;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('eventi')
          .doc(widget.eventId)
          .collection('concorrenti')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: localPurple));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Nessun concorrente in gara.", style: TextStyle(color: Colors.white)));
        }

        List<Map<String, dynamic>> listaConcorrenti = snapshot.data!.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          double totale = data['totaleSommaVoti']?.toDouble() ?? 0.0;
          int voti = data['numeroVoti']?.toInt() ?? 0;
          
          double media = voti > 0 ? (totale / voti) : 0.0;

          return {
            'id': doc.id,
            'nome': data['nomeArte'] ?? 'Sconosciuto',
            'categoria': data['genere'] ?? 'TALENTO',
            'foto': data['foto'] ?? 'https://via.placeholder.com/150',
            'media': media,
          };
        }).toList();

        listaConcorrenti.sort((a, b) => b['media'].compareTo(a['media']));

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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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

              Row(
                children: [
                  const Text('TOP PERFORMER', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                ],
              ),
              const SizedBox(height: 16),

              if (listaConcorrenti.length > 3)
                ...listaConcorrenti.sublist(3).asMap().entries.map((entry) {
                  int index = entry.key + 4; 
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
                          setState(() {
                            _selectedIndex = 0; 
                          });
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

  Widget _buildVotazioniLive() {
  // Se stiamo caricando i voti passati dal DB, mostra il caricamento per evitare sfarfallii
  if (_isLoadingVoti) {
    return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
  }

  // 1. ASCOLTIAMO LO STATO DEL TELEVOTO DALL'EVENTO PRINCIPALE
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('eventi')
        .doc(widget.eventId)
        .snapshots(),
    builder: (context, eventSnapshot) {
      if (eventSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
      }

      var eventData = eventSnapshot.data?.data() as Map<String, dynamic>?;
      // Leggiamo la stessa identica chiave usata lato Admin
      bool isTelevotoAperto = eventData?['isTelevotoAperto'] ?? false;

      // 🛑 SE IL TELEVOTO È CHIUSO: Mostriamo la schermata di blocco temporaneo
      if (!isTelevotoAperto) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(
                    Icons.how_to_vote_rounded,
                    size: 50,
                    color: Color(0xFFFF7B93), // Rosa acceso coerente con il tuo stile
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Televoto Chiuso",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Le votazioni non sono attualmente attive.\nAttendi che l'amministratore apra il televoto per poter esprimere il tuo giudizio.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // ✅ SE IL TELEVOTO È APERTO: Carica regolarmente i concorrenti (Il tuo codice originale intatto)
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('eventi')
            .doc(widget.eventId)
            .collection('concorrenti')
            .orderBy('timestamp', descending: true)
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

          final allDocs = snapshot.data!.docs;
          final docs = allDocs.where((doc) => !_votedConcorrentiIds.contains(doc.id)).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Hai già votato tutti i concorrenti disponibili!",
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            );
          }
          
          if (_currentArtistIndex >= docs.length) {
            _currentArtistIndex = 0;
          }

          final artistDoc = docs[_currentArtistIndex];
          final artistData = artistDoc.data() as Map<String, dynamic>;
          final String artistId = artistDoc.id;
          final String nomeArte = artistData['nomeArte'] ?? "Artista";
          final String category = artistData['genere'] ?? "Categoria";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "LIVE SHOW IN CORSO",
                  style: TextStyle(color: Color(0xFFFF7B93), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 5),
                
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
                              "Categoria: $category",
                              style: const TextStyle(color: Colors.white60, fontSize: 14),
                            ),
                          ],
                        ),
                      ),

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
                                    _selectedVote = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),

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
                                    _selectedVote = null;
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

                InkWell(
                  onTap: _selectedVote == null ? null : () async {
                    final String concorrenteId = artistId;
                    final double votoScelto = _selectedVote!.toDouble();
                    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonimo';

                    DocumentReference concorrenteRef = FirebaseFirestore.instance
                        .collection('eventi') 
                        .doc(widget.eventId)
                        .collection('concorrenti')
                        .doc(concorrenteId);

                    DocumentReference spettatoreVotiRef = FirebaseFirestore.instance
                        .collection('eventi')
                        .doc(widget.eventId)
                        .collection('voti_spettatori')
                        .doc(userId);

                    try {
                      await concorrenteRef.update({
                        'totaleSommaVoti': FieldValue.increment(votoScelto),
                        'numeroVoti': FieldValue.increment(1),
                      });
                      
                      await spettatoreVotiRef.set({
                        'concorrentiVotati': FieldValue.arrayUnion([concorrenteId])
                      }, SetOptions(merge: true));

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Voto inviato con successo! Classifica aggiornata.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }

                      setState(() {
                        _votedConcorrentiIds.add(artistId); 
                        _selectedIndex = 2; 
                        _selectedVote = null;
                      });

                    } catch (e) {
                      print("Errore immediato durante l'invio del voto: $e");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Errore di scrittura: ${e.toString()}'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
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
    },
  );
}

 



  



Widget _buildProfiloSpettatore(BuildContext context, {
  required String nome,
}) {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.all(30),
    child: Column(
      children: [
        // 🌟 Card Profilo dello Spettatore (Stile speculare a quello Admin)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 25),
          decoration: BoxDecoration(
            color: const Color(0xFF16161E), // Sfondo scuro come da foto
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFD68BFF).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // Icona del Profilo (Colore viola coordinato)
              const Icon(
                Icons.account_circle_rounded, 
                size: 80, 
                color: Color(0xFFD68BFF),
              ),
              const SizedBox(height: 20),
              
             
              
              // Badge "SPETTATORE" (Stile "PROPRIETARIO EVENTO" della foto)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD68BFF).withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "SPETTATORE", 
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



// Helper interno per generare le singole colonne delle statistiche


// Helper interno per generare i chip/tag grafici degli interessi
Widget _buildTag(String text, TextStyle baseStyle) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: baseStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    ),
  );
}

// =========================================================================
  // METODO PRINCIPALE BUILD (RISOLVE L'ERRORE DELLA MANCANZA DI BUILD)
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0C15), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.eventTitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("PANNELLO SPETTATORE", style: TextStyle(color: Color(0xFFD68BFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF16161E),
        selectedItemColor: const Color(0xFFD68BFF),
        unselectedItemColor: Colors.white38,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote),
            label: 'Vota',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: 'Scaletta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Classifica',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }  

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildVotazioniLive();
      case 1:
        return ScalettaLiveView(eventId: widget.eventId, eventTitle: widget.eventTitle, ruolo: 'spettatore');
      case 2:
        return ClassificaLiveView(eventId: widget.eventId, eventTitle: widget.eventTitle, userRole: 'spettatore');
      case 3:
        return _buildProfiloSpettatore(context, nome: '');
      default:
        return _buildVotazioniLive();
    }
  }

  
}