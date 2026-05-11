import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stagelive/ui/auth/EventsView.dart';
import 'package:stagelive/ui/auth/login_view.dart'; 
import 'package:stagelive/ui/auth/CreateEventView.dart';
import 'package:stagelive/ui/auth/register_view.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const StageLiveApp());
}

class StageLiveApp extends StatelessWidget {
  const StageLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StageLive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        // Colore viola neon dei tuoi mockup
        primaryColor: const Color(0xFFD68BFF),
        scaffoldBackgroundColor: const Color(0xFF0B0B0F),
      ),
      
      home: LoginView(),

    routes: {
      '/login': (context) => LoginView(),
      '/register': (context) => RegisterView(),
      '/events': (context) => EventsView(), 
     '/create-event': (context) => CreateEventView(),
    },
    );
  }
}
