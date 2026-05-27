import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stagelive/services/auth_service.dart';
import 'package:stagelive/services/location_service.dart';

class CreateEventView extends StatefulWidget {
  const CreateEventView({super.key});

  @override
  State<CreateEventView> createState() => _CreateEventViewState();
}

class _CreateEventViewState extends State<CreateEventView> {
  final AuthService _auth = AuthService();
  final LocationService _locationService = LocationService();

  final TextEditingController _titoloController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _descrizioneController = TextEditingController();

  List<String> _province = [];
  List<String> _comuni = [];
  String? _provinciaSelezionata;
  String? _comuneSelezionato;
  bool _isCaricandoProvince = true;
  bool _isCaricandoComuni = false;

  @override
  void initState() {
    super.initState();
    _caricaProvince();
  }

  void _caricaProvince() async {
    var lista = await _locationService.getProvince();
    if (mounted) {
      setState(() {
        _province = lista;
        _isCaricandoProvince = false;
      });
    }
  }

  void _caricaComuni(String provincia) async {
    setState(() {
      _isCaricandoComuni = true;
      _comuneSelezionato = null;
      _comuni = []; 
    });
    var lista = await _locationService.getComuniPerProvincia(provincia);
    if (mounted) {
      setState(() {
        _comuni = lista;
        _isCaricandoComuni = false;
      });
    }
  }

  
  void _mostraSelettore({required String titolo, required List<String> items, required Function(String) onSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        List<String> filtrati = []; // Inizialmente vuoto per non appesantire
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(titolo, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Scrivi l'iniziale...",
                      hintStyle: const TextStyle(color: Colors.white24),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFD68BFF)),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        if (val.isEmpty) {
                          filtrati = [];
                        } else {
                          // Filtro dinamico per non bloccare l'interfaccia
                          filtrati = items
                              .where((element) => element.toLowerCase().startsWith(val.toLowerCase()))
                              .toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filtrati.isEmpty 
                      ? const Center(child: Text("Inizia a scrivere per cercare...", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: filtrati.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: Color(0xFFD68BFF), size: 18),
                              title: Text(filtrati[index], style: const TextStyle(color: Colors.white)),
                              onTap: () {
                                onSelected(filtrati[index]);
                                Navigator.pop(context);
                              },
                            );
                          },
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

  Future<void> _selezionaDataOra() async {
    DateTime? dataScelta = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFD68BFF), onPrimary: Colors.black, surface: Color(0xFF16161E)),
        ),
        child: child!,
      ),
    );
    if (dataScelta != null) {
      TimeOfDay? oraScelta = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFD68BFF), onPrimary: Colors.black, surface: Color(0xFF16161E)),
          ),
          child: child!,
        ),
      );
      if (oraScelta != null) {
        final DateTime dataCompleta = DateTime(dataScelta.year, dataScelta.month, dataScelta.day, oraScelta.hour, oraScelta.minute);
        setState(() {
          _dataController.text = DateFormat('dd/MM/yyyy HH:mm').format(dataCompleta);
        });
      }
    }
  }

  void _creaEvento() async {
    if (_titoloController.text.isEmpty || _comuneSelezionato == null || _dataController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Compila tutti i campi")));
      return;
    }
    try {
      await _auth.creaEvento(
        titolo: _titoloController.text,
        data: _dataController.text,
        luogo: _comuneSelezionato!,
        descrizione: _descrizioneController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Arena pubblicata!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("Crea Nuova Arena")),
      body: _isCaricandoProvince 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD68BFF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField("Titolo Evento", _titoloController, Icons.emoji_events_sharp),
                  const SizedBox(height: 20),

                  // SELETTORE PROVINCIA
                  _selectorTile(
                    label: "Provincia",
                    value: _provinciaSelezionata ?? "Seleziona Provincia",
                    icon: Icons.map,
                    onTap: () => _mostraSelettore(
                      titolo: "Scegli Provincia",
                      items: _province,
                      onSelected: (val) {
                        setState(() {
                          _provinciaSelezionata = val;
                          _comuneSelezionato = null;
                        });
                        _caricaComuni(val); 
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  
                  _isCaricandoComuni 
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: LinearProgressIndicator(color: Color(0xFFD68BFF)),
                      )
                    : _selectorTile(
                        label: "Comune",
                        value: _comuneSelezionato ?? "Seleziona Comune",
                        icon: Icons.location_city,
                        enabled: _provinciaSelezionata != null,
                        onTap: () => _mostraSelettore(
                          titolo: "Scegli Comune in $_provinciaSelezionata",
                          items: _comuni,
                          onSelected: (val) => setState(() => _comuneSelezionato = val),
                        ),
                      ),

                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _selezionaDataOra,
                    child: IgnorePointer(child: _buildTextField("Data e Ora", _dataController, Icons.calendar_month)),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Descrizione", _descrizioneController, Icons.description, lineeMassime: 3),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD68BFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: _creaEvento,
                      child: const Text("PUBBLICA ARENA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _selectorTile({required String label, required String value, required IconData icon, required VoidCallback onTap, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFF16161E) : Colors.white10,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFD68BFF)),
                const SizedBox(width: 15),
                Text(value, style: TextStyle(color: enabled ? Colors.white : Colors.white24)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int lineeMassime = 1}) {
    return TextField(
      controller: controller,
      maxLines: lineeMassime,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFFD68BFF)),
        filled: true,
        fillColor: const Color(0xFF16161E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}