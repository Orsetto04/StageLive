import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScalettaLiveView extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String ruolo; 
  
  final bool isTestMode;
  final List<Map<String, dynamic>>? testData;

  const ScalettaLiveView({
    super.key, 
    required this.eventId, 
    required this.eventTitle, 
    required this.ruolo, 
    this.isTestMode = false, 
    this.testData,           
  });

  @override
  State<ScalettaLiveView> createState() => _ScalettaLiveViewState();
}

class _ScalettaLiveViewState extends State<ScalettaLiveView> {
  List<DocumentSnapshot> _localScaletta = [];
  bool _isOrderChanged = false;
  
  bool get _canModify => widget.ruolo == 'admin' || widget.ruolo == 'staff';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _canModify ? "BACKSTAGE MANAGEMENT" : "LIVE TIMELINE",
                    style: const TextStyle(color: Color(0xFFFF4B72), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Scaletta Live",
                    style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  // Pill Live Now
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD68BFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Live Now:", style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text(widget.eventTitle, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: widget.isTestMode && widget.testData != null
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: widget.testData!.length,
                      itemBuilder: (context, index) {
                        var data = widget.testData![index];
                        String docId = data['id'] ?? 'test_id_$index';
                        return _buildScalettaCard(docId, data, index, key: ValueKey(docId));
                      },
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('eventi')
                          .doc(widget.eventId)
                          .collection('scaletta')
                          .orderBy('ordine')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)));
                        
                        if (!_isOrderChanged || !_canModify) {
                          _localScaletta = snapshot.data!.docs;
                        }

                        if (_localScaletta.isEmpty) {
                          return const Center(child: Text("Nessuna performance in scaletta", style: TextStyle(color: Colors.grey)));
                        }

                        if (_canModify) {
                          return ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _localScaletta.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final item = _localScaletta.removeAt(oldIndex);
                                _localScaletta.insert(newIndex, item);
                                _isOrderChanged = true;
                              });
                            },
                            itemBuilder: (context, index) {
                              var doc = _localScaletta[index];
                              var data = doc.data() as Map<String, dynamic>;
                              return _buildScalettaCard(doc.id, data, index, key: ValueKey(doc.id));
                            },
                          );
                        } 
                        
                        else {
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _localScaletta.length,
                            itemBuilder: (context, index) {
                              var doc = _localScaletta[index];
                              var data = doc.data() as Map<String, dynamic>;
                              return _buildScalettaCard(doc.id, data, index, key: ValueKey(doc.id));
                            },
                          );
                        }
                      },
                    ),
            ),

            if (_canModify)
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    _bottomMenuButton(
                      label: "Aggiungi Performance",
                      icon: Icons.add_circle_outline,
                      iconColor: const Color(0xFFFF4B72),
                      onTap: () => _showAddPerformanceDialog(context),
                    ),
                    const SizedBox(height: 15),
                    
                  ],
                ),
              )
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScalettaCard(String id, Map<String, dynamic> data, int index, {required Key key}) {
    String nome = data['nomeArte'] ?? data['nome'] ?? 'Artista';
    String brano = data['brano'] ?? 'Traccia';
    String genere = data['genere'] ?? 'Pop';
    String durata = data['durata'] ?? '03:30';
    String status = (data['status'] ?? 'IN ATTESA').toString().toUpperCase();

    bool isLive = status == 'IN CORSO';
    bool isCompleted = status == 'COMPLETATO';

    Color statusColor = Colors.grey;
    Color statusBg = Colors.transparent;
    if (isLive) { statusColor = const Color(0xFFD68BFF); statusBg = const Color(0xFF2A1B3D); }
    else if (status == 'PROSSIMO') { statusColor = const Color(0xFFFF4B72); statusBg = const Color(0xFF3D1B24); }

    String indexStr = (index + 1) < 10 ? "0${index + 1}" : "${index + 1}";
    if (isCompleted) indexStr = "--";

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isLive ? const Color(0xFFD68BFF).withOpacity(0.4) : Colors.white10,
          width: isLive ? 2 : 1,
        ),
        boxShadow: isLive ? [BoxShadow(color: const Color(0xFFD68BFF).withOpacity(0.1), blurRadius: 20)] : null,
      ),
      child: Row(
        children: [
          // Maniglia di trascinamento (SOLO PER ADMIN E STAFF)
          Row(
            children: [
              if (_canModify) ...[
                const Icon(Icons.drag_indicator, color: Colors.white24, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                indexStr,
                style: TextStyle(
                  color: isLive ? const Color(0xFFD68BFF) : Colors.white30,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),

          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person, color: isLive ? const Color(0xFFD68BFF) : Colors.white),
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: TextStyle(
                    color: isCompleted ? Colors.white38 : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  "$brano ($genere)",
                  style: TextStyle(
                    color: isCompleted ? Colors.grey.withOpacity(0.5) : Colors.grey,
                    fontSize: 13,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text("DURATA ", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(durata, style: TextStyle(color: isCompleted ? Colors.white38 : Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // Badge di Stato + Menu Modifica (SOLO PER ADMIN E STAFF)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_canModify) 
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: const Color(0xFF16161E),
                  onSelected: (valore) => _gestisciModificaPerformance(id, valore, data),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'IN CORSO', child: Text('Imposta: In Corso', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'PROSSIMO', child: Text('Imposta: Prossimo', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'IN ATTESA', child: Text('Imposta: In Attesa', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'COMPLETATO', child: Text('Imposta: Completato', style: TextStyle(color: Colors.white))),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'ELIMINA', child: Text('Rimuovi Performance', style: TextStyle(color: Color(0xFFFF4B72)))),
                  ],
                )
              else
                const SizedBox(height: 10),
                
              statusBg == Colors.transparent 
                ? Text(status, style: TextStyle(color: isCompleted ? Colors.white12 : Colors.white30, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1))
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
            ],
          ),
        ],
      ),
    );
  }

void _showAddPerformanceDialog(BuildContext context) {
    if (!_canModify) return; // Sicurezza extra
    String? utenteSelezionatoUid;
    String? utenteSelezionatoNome;
    final TextEditingController branoController = TextEditingController();
    final TextEditingController genereController = TextEditingController(text: "Pop");
    final TextEditingController durataController = TextEditingController(text: "03:30");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nuova Performance", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text("Seleziona Concorrente del Cast", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('eventi')
                        .doc(widget.eventId)
                        .collection('concorrenti')
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const LinearProgressIndicator(color: Color(0xFFD68BFF));
                      var competitorDocs = snap.data!.docs;

                      if (competitorDocs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Nessun concorrente inserito nel cast di questo evento.", 
                            style: TextStyle(color: Color(0xFFFF4B72), fontSize: 13),
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0xFF22222B), borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: utenteSelezionatoUid, 
                            hint: const Text("Scegli un artista...", style: TextStyle(color: Colors.white30)),
                            dropdownColor: const Color(0xFF16161E),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white),
                            items: competitorDocs.map((d) {
                              var map = d.data() as Map<String, dynamic>;
                              String nomeCandidato = map['nomeArte'] ?? 'Artista';
                              return DropdownMenuItem<String>(
                                value: d.id, 
                                child: Text(nomeCandidato, style: const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (String? nuovoValore) {
                              setModalState(() {
                                utenteSelezionatoUid = nuovoValore; 
                                var docScelto = competitorDocs.firstWhere((d) => d.id == nuovoValore);
                                var mapScelto = docScelto.data() as Map<String, dynamic>;
                                utenteSelezionatoNome = mapScelto['nomeArte'] ?? 'Artista';
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildInputField("Titolo Canzone", branoController, Icons.music_note),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildInputField("Genere", genereController, Icons.style)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildInputField("Durata (MM:SS)", durataController, Icons.timer)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD68BFF), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () async {
                        if (utenteSelezionatoUid == null || branoController.text.isEmpty) return;
                        int nuovoOrdine = _localScaletta.length;

                        await FirebaseFirestore.instance
                            .collection('eventi')
                            .doc(widget.eventId)
                            .collection('scaletta')
                            .add({
                          'uid': utenteSelezionatoUid,
                          'nomeArte': utenteSelezionatoNome,
                          'brano': branoController.text.trim(),
                          'genere': genereController.text.trim(),
                          'durata': durataController.text.trim(),
                          'status': 'IN ATTESA',
                          'ordine': nuovoOrdine,
                        });

                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text("INSERISCI IN SCALETTA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }
  void _gestisciModificaPerformance(String docId, String azione, Map<String, dynamic> data) async {
    if (!_canModify) return;
    var ref = FirebaseFirestore.instance.collection('eventi').doc(widget.eventId).collection('scaletta').doc(docId);
    if (azione == 'ELIMINA') {
      await ref.delete();
      _riassestaOrdiniDatabase();
    } else {
      await ref.update({'status': azione});
    }
  }


  void _riassestaOrdiniDatabase() async {
    var snap = await FirebaseFirestore.instance.collection('eventi').doc(widget.eventId).collection('scaletta').orderBy('ordine').get();
    var batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < snap.docs.length; i++) {
      batch.update(snap.docs[i].reference, {'ordine': i});
    }
    await batch.commit();
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true, 
            fillColor: const Color(0xFF22222B),
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _bottomMenuButton({required String label, required IconData icon, required Color iconColor, Color backgroundColor = const Color(0xFF16161E), VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: Colors.white10))
        ),
        onPressed: onTap,
        icon: Icon(icon, color: iconColor),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}