import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stagelive/ui/auth/ClassificaLiveView.dart';
import 'package:stagelive/ui/auth/ScalettaLiveView.dart';
import 'EventsView.dart'; 

class EventCompetitorView extends StatefulWidget {
  final String eventId;

  const EventCompetitorView({super.key, required this.eventId});

  @override
  State<EventCompetitorView> createState() => _EventCompetitorViewState();
}

class _EventCompetitorViewState extends State<EventCompetitorView> {
  final TextEditingController _nomeArteController = TextEditingController();
  final TextEditingController _descrizioneController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cognomeController = TextEditingController();
  final TextEditingController _cfController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _luogoController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _branoController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();

  String? _selectedGenre;
  bool _isSending = false;

  final List<String> _generi = ['Pop', 'Rock', 'Trap', 'Indie', 'Rap', 'Electronic', 'Jazz', 'Blues', 'Metal'];

  Future<void> _inviaCandidatura() async {
    if (_nomeArteController.text.isEmpty || 
        _selectedGenre == null || 
        _nomeController.text.isEmpty || 
        _cognomeController.text.isEmpty ) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Compila tutti i campi obbligatori correttamente!"), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // SALVATAGGIO NEL DATABASE: Qui vengono salvati tutti i dati inseriti nel form
      await FirebaseFirestore.instance.collection('candidature').add({
        'eventId': widget.eventId, 
        'uid': FirebaseAuth.instance.currentUser?.uid,
        'nomeArte': _nomeArteController.text.trim(),
        'genere': _selectedGenre,
        'descrizione': _descrizioneController.text.trim(),
        'nome': _nomeController.text.trim(),
        'cognome': _cognomeController.text.trim(),
        'codiceFiscale': _cfController.text.toUpperCase().trim(),
        'telefono': _telefonoController.text.trim(),
        'email': _emailController.text.trim(),
        'dataNascita': _dateController.text,
        'luogoNascita': _luogoController.text.trim(),
        'brano': _branoController.text.trim(),
        // Social (possono essere vuoti)
        'instagram': _instagramController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'status': 'PENDENTE',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Candidatura inviata con successo!"), backgroundColor: Colors.green)
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WaitingScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isSending = false);
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
        title: const Text("StageLive", style: TextStyle(color: Color(0xFFD68BFF), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sali sul Palco", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            _buildCardContainer("Informazioni Artistiche *", Icons.mic, [
              _buildInput("NOME D'ARTE *", "Es. Luna Stark", _nomeArteController),
              _buildDropdown(),
              _buildInput("PARLACI UN PO' DI TE... *", "Parlaci del tuo sound...", _descrizioneController, lines: 3),
              _buildInput("CHE BRANO PORTERAI? * (Brano - Artista/Gruppo/Inedito)", "Es. \"Bohemian Rhapsody\" - Queen", _branoController, lines: 3),
            ]),

            _buildCardContainer("Dati Anagrafici *", Icons.badge, [
              _buildInput("NOME *", "", _nomeController),
              _buildInput("COGNOME *", "", _cognomeController),
              _buildInput("DATA DI NASCITA (GG/MM/AAAA)", "Es. 31/12/1999", _dateController),
              _buildInput("LUOGO DI NASCITA", "", _luogoController),
              _buildInput("EMAIL *", "es. tuo@email.com", _emailController),
              _buildInput("TELEFONO *", "Es. +39 123 456 7890", _telefonoController),
            ]),

            _buildCardContainer("Social (Opzionale)", Icons.share, [
              _buildInput("INSTAGRAM USERNAME", "@tuoutente", _instagramController),
              _buildInput("TIKTOK USERNAME", "@tuoutente", _tiktokController),
              _buildInput("FACEBOOK NAME", "Nome Profilo", _facebookController),
            ]),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD68BFF), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
                onPressed: _isSending ? null : _inviaCandidatura,
                child: _isSending 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("INVIA REGISTRAZIONE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPERS IDENTICI ---
  Widget _buildCardContainer(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(25)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: const Color(0xFFD68BFF), size: 18), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 20), ...children
      ]),
    );
  }

  Widget _buildInput(String label, String hint, TextEditingController ctrl, {int lines = 1, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl, maxLines: lines, onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true, fillColor: Colors.black,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
          ),
        ),
      ]),
    );
  }

  Widget _buildDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("GENERE MUSICALE *", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        dropdownColor: const Color(0xFF16161E), value: _selectedGenre,
        items: _generi.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: Colors.white)))).toList(),
        onChanged: (v) => setState(() => _selectedGenre = v),
        decoration: InputDecoration(filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
      ),
      const SizedBox(height: 15),
    ]);
  }
}

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
      ScalettaLiveView(eventId: widget.eventId, eventTitle: widget.eventTitle, ruolo: 'competitor'),
      _buildListaConcorrentiView(),
      ClassificaLiveView(eventId: widget.eventId, eventTitle: widget.eventTitle, userRole: 'competitor'),
      _buildProfiloView(context), 
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
            const Text("PANNELLO CONCORRENTE", style: TextStyle(color: Color(0xFFD68BFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Concorrenti"),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "Classifica"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profilo"),
        ],
      ),
    );
  }

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
            // Usiamo il nome d'arte se presente, altrimenti il nome o lo username
            String nome = data['nomeArte'] ?? data['nome'] ?? data['username'] ?? 'Concorrente';
            String brano = data['brano'] ?? 'Nessun brano specificato';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _mostraBranoConcorrente(context, nome, brano), // 🌟 Mostra solo il brano al click
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
                      const Icon(Icons.star, color: Color(0xFFD68BFF), size: 24),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          nome, 
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.music_note, color: Colors.white24, size: 20), // Icona nota musicale come indizio di click
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

  void _mostraBranoConcorrente(BuildContext context, String nome, String brano) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linea estetica superiore
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
              
              // Nome del concorrente cliccato
              Text(
                nome,
                style: const TextStyle(color: Color(0xFFD68BFF), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              const Text(
                "BRANO IN SCALETTA",
                style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              
              // Box contenente SOLO il brano
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0B0F),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audiotrack, color: Color(0xFFD68BFF), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        brano,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 15, 
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Pulsante Chiudi
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
                    "CHIUDI",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfiloView(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 25),
            decoration: BoxDecoration(
              color: const Color(0xFF16161E), 
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFD68BFF).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.stars_rounded, 
                  size: 80, 
                  color: Color(0xFFD68BFF),
                ),
                const SizedBox(height: 20),
                
                // Badge "CONCORRENTE"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD68BFF).withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "CONCORRENTE", 
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