import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
 
  static const String _apiProvince = "https://comuni-ita.herokuapp.com/api/province";
  static const String _apiComuni = "https://comuni-ita.herokuapp.com/api/comuni/provincia/";

  Future<List<String>> getProvince() async {
  try {
    final response = await http.get(Uri.parse(_apiProvince)).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => item['nome'].toString()).toList()..sort();
    }
  } catch (e) {
    print("Internet non risponde, carico province di emergenza...");
  }
  
  return ["Agrigento", "Bari", "Bologna", "Catania", "Firenze", "Genova", "Milano", "Napoli", "Palermo", "Roma", "Teramo", "Torino", "Venezia"];
}

 Future<List<String>> getComuniPerProvincia(String provincia) async {
  try {
    
    final String nomeProvincia = provincia.trim();
    final String urlString = "https://comuni-ita.herokuapp.com/api/comuni/provincia/${Uri.encodeComponent(nomeProvincia)}";
    
    print("Richiesta comuni per: $nomeProvincia");
    print("URL: $urlString");

    final response = await http.get(Uri.parse(urlString)).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<String> comuni = data.map((item) => item['nome'].toString()).toList();
      comuni.sort();
      print("Comuni caricati: ${comuni.length}");
      return comuni;
    } else {
      print("Errore API Comuni: ${response.statusCode}");
    }
  } catch (e) {
    print("Errore durante il caricamento dei comuni: $e");
  }
  
  if (provincia.contains("Teramo")) {
    return ["Teramo", "Giulianova", "Roseto degli Abruzzi", "Bellante", "Atri"];
  }
  
  return [];
}
}