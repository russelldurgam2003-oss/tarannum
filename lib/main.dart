import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
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
        fontFamily: 'Arial',
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