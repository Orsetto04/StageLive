import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importante!
import 'ui/auth/login_view.dart';

void main() async {
  // 1. Assicura che i widget siano pronti
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inizializza Firebase prima di far partire l'app
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StageLive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFBC00DD),
      ),
      home: const LoginView(),
    );
  }
}