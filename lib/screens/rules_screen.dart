import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قوانين اللعبة'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مرحباً بك في ترنم!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text(
                'ترنم هي لعبة مستوحاة من لعبة الكاروتا اليابانية، لكن بأبيات الشعر العربي.',
                style: TextStyle(fontSize: 18, height: 1.5),
              ),
              SizedBox(height: 24),
              Text('كيف تلعب؟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                '1. سيظهر لك "صدر" البيت (الشطر الأول) في أعلى الشاشة.\n'
                '2. أسفل الشاشة، ستجد عدة بطاقات تحتوي على "أعجاز" (أشطر ثانية) مختلفة.\n'
                '3. عليك اختيار البطاقة التي تحتوي على العجز الصحيح في أسرع وقت ممكن.\n'
                '4. الإجابة الصحيحة تمنحك نقطة، والخطأ يخصم منك.',
                style: TextStyle(fontSize: 18, height: 1.5),
              ),
              SizedBox(height: 24),
              Text('الفوز باللعبة:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                'من يجمع أكبر عدد من النقاط بعد انتهاء الجولات هو الفائز!',
                style: TextStyle(fontSize: 18, height: 1.5),
              ),
              SizedBox(height: 40),
              Center(
                child: Text('استعدوا للتحدي!', style: TextStyle(fontSize: 20, color: Colors.indigo, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}