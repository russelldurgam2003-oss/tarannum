import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';

void main() async {
  // ضروري جداً لتهيئة النظام قبل استخدام Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase باستخدام بياناتك
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDbp1z3E3bttyvooSFIHzHh55pLQ6xAfIs",
      authDomain: "tarannum-290a6.firebaseapp.com",
      projectId: "tarannum-290a6",
      storageBucket: "tarannum-290a6.firebasestorage.app",
      messagingSenderId: "707292820172",
      appId: "1:707292820172:web:803442acb09c355b250869",
    ),
  );

  runApp(const TarannumApp());
}

class TarannumApp extends StatelessWidget {
  const TarannumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ترنم',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF8F5F0),
        fontFamily: 'Amiri', 
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}