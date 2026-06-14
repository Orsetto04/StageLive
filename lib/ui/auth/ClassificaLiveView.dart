import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Import per Clipboard se serve nel resto dell'app

class ClassificaLiveView extends StatelessWidget {
  final bool isTestMode;
  final List<Map<String, String>>? testData;
  final String eventId;
  final String userRole;
  final VoidCallback? onBackToVoting; 

  const ClassificaLiveView({
    super.key,
    required this.eventId,
    required this.userRole, 
    this.onBackToVoting, 
    required String eventTitle,
    this.isTestMode = false, 
    this.testData,
  });

  @override
  Widget build(BuildContext context) {

    if (isTestMode && testData != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1B28), // Metti il colore di sfondo del tuo layout
        body: ListView.builder(
          itemCount: testData!.length,
          itemBuilder: (context, index) {
            final item = testData![index];
            // Richiama il tuo metodo _buildListRow che abbiamo configurato prima!
            return _buildListRow(
              item['rank'] ?? '',
              item['name'] ?? '',
              item['category'] ?? '',
              item['vote'] ?? '',
              item['imageUrl'] ?? '',
            );
          },
        ),
      );
    }


    const Color localPurple = Color(0xFFBC53EE);
    const Color localPink = Color(0xFFFA6A7F);
    const Color localMutedText = Colors.white54;

    // 1. Ascoltiamo il documento principale dell'evento per sapere se la classifica è pubblica o nascosta
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('eventi').doc(eventId).snapshots(),
      builder: (context, eventSnapshot) {
        if (eventSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: localPurple));
        }

        var eventData = eventSnapshot.data?.data() as Map<String, dynamic>?;
        bool isClassificaPubblicata = eventData?['isRankingPublished'] ?? false;

        // 2. CONTROLLO ACCESSO: Se è nascosta E l'utente è un concorrente o uno spettatore...
        bool utenteDaBloccare = userRole == 'concorrente' || userRole == 'spettatore';
        
        if (!isClassificaPubblicata && utenteDaBloccare) {
          // Schermata di blocco con lo stesso stile grafico scuro/viola
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility_off_outlined, size: 80, color: localPink),
                  const SizedBox(height: 20),
                  const Text(
                    "Classifica Nascosta",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "L'organizzatore ha momentaneamente nascosto la classifica live. Tornerà visibile non appena verrà ripubblicata!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: localMutedText, fontSize: 14, height: 1.4),
                  ),
                  if (onBackToVoting != null) ...[
                    const SizedBox(height: 35),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: onBackToVoting,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: localPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        icon: const Icon(Icons.assignment_return_outlined, color: Colors.black),
                        label: const Text(
                          "TORNA ALLA VOTAZIONE", 
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        }

        // 3. Se la classifica è pubblica OPPURE l'utente è Admin/Staff, carica il tuo stream originale senza modifiche
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('eventi')
              .doc(eventId)
              .collection('concorrenti')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: localPurple));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("Nessun concorrente in gara.", style: TextStyle(color: Colors.white)),
              );
            }

            // Mappiamo i documenti di Firestore in una lista locale
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

            // ORDINA LA LISTA: Dal voto medio più alto al più basso
            listaConcorrenti.sort((a, b) => b['media'].compareTo(a['media']));

            var primo = listaConcorrenti.isNotEmpty ? listaConcorrenti[0] : null;
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
                              accentColor: localPurple,
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

                 
                ],
              ),
            );
          },
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
        Text(score, style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.w600)),
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
      key: Key('riga_classifica_$rank'),
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
              Text(vote, style: const TextStyle(color: Colors.purpleAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('VOTO', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}