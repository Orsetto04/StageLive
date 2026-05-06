import 'package:flutter/material.dart';
import 'package:stagelive/services/auth_service.dart';

class CreateEventView extends StatefulWidget {
  @override
  State<CreateEventView> createState() => _CreateEventViewState();
}

class _CreateEventViewState extends State<CreateEventView> {
  final _titoloController = TextEditingController();
  final _dataController = TextEditingController();
  final _descController = TextEditingController();
  final AuthService _auth = AuthService();

  // Variabili per i nuovi input
  String? _selectedCity;
  final List<String> _cities = ["Roma", "Milano", "Napoli", "Torino", "Bologna", "Palermo", "Firenze", "Bari"];
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Funzione per selezionare la DATA e poi l'ORA
  Future<void> _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD68BFF),
              onPrimary: Colors.black,
              surface: Color(0xFF16161E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
          // Formattazione semplice per il controller
          _dataController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year} - ${pickedTime.format(context)}";
        });
      }
    }
  }

  void _submitEvento() async {
    if (_titoloController.text.isEmpty || _dataController.text.isEmpty || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Riempi i campi obbligatori")));
      return;
    }

    try {
      await _auth.creaEvento(
        titolo: _titoloController.text.trim(),
        data: _dataController.text.trim(),
        luogo: _selectedCity!, // Usa la città selezionata dal dropdown
        descrizione: _descController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evento creato con successo!")));
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("NUOVO EVENTO", style: TextStyle(color: Color(0xFFD68BFF), fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Crea la tua Arena", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            _buildLabel("TITOLO EVENTO"),
            _buildInput(_titoloController, "Esempio: Rock Battle 2024", Icons.event),
            
            const SizedBox(height: 20),
            
            // INPUT DATA E ORA (Ora con Picker)
            _buildLabel("DATA E ORA"),
            InkWell(
              onTap: _pickDateTime,
              child: IgnorePointer(
                child: _buildInput(_dataController, "Seleziona Data e Ora", Icons.access_time),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // INPUT LUOGO (Ora con Dropdown)
            _buildLabel("CITTÀ"),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF16161E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_city, color: Color(0xFFD68BFF), size: 20),
                filled: true,
                fillColor: const Color(0xFF16161E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              value: _selectedCity,
              hint: const Text("Seleziona città", style: TextStyle(color: Colors.white24, fontSize: 14)),
              items: _cities.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: (val) => setState(() => _selectedCity = val),
            ),
            
            const SizedBox(height: 20),
            _buildLabel("DESCRIZIONE"),
            _buildInput(_descController, "Racconta di cosa si tratta...", Icons.description, maxLines: 3),
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD68BFF),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _submitEvento,
              child: const Text("Pubblica Evento", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFD68BFF), size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white10),
        filled: true,
        fillColor: const Color(0xFF16161E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}