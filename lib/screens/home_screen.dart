import 'package:flutter/material.dart';
import 'rules_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار اللعبة أو العنوان
              const Icon(Icons.menu_book, size: 80, color: Colors.indigo),
              const SizedBox(height: 16),
              const Text(
                'ترنم',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Text(
                'لعبة الشعر العربي',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 60),

              // زر اللعب الفردي
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GameScreen()),
                    );
                  },
                  icon: const Icon(Icons.computer, size: 28),
                  label: const Text('اللعب الفردي (ضد الذكاء الاصطناعي)', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // زر اللعب مع الأصدقاء
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // سنقوم ببرمجة الأونلاين لاحقاً
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('قريباً'),
                        content: const Text('خاصية اللعب مع الأصدقاء عبر الإنترنت قيد التطوير.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('حسناً'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.people, size: 28),
                  label: const Text('اللعب مع الأصدقاء (أونلاين)', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // زر القوانين
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RulesScreen()),
                  );
                },
                icon: const Icon(Icons.info_outline, color: Colors.grey),
                label: const Text('قوانين اللعبة', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}