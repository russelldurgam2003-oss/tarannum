import 'package:flutter/material.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), 
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward(); 
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // شريط علوي مخصص
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'قوانين اللعبة',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2))
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), 
                  ],
                ),
              ),
              
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        // زيادة الارتفاع الأقصى لتصبح المخطوطة أطول
                        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 1000), 
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/parchment_vertical.png'),
                            fit: BoxFit.fill, // ستمدد الصورة لتغطي الطول الجديد
                          ),
                        ),
                        // زيادة الحواف السفلية والعلوية قليلاً لتناسب الطول الجديد
                        padding: const EdgeInsets.only(left: 130, right: 130, top: 130, bottom: 150),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center, 
                            children: [
                              const Text(
                                'مرحباً بك في ترنم!', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A2C11))
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'لعبة مستوحاة من الكاروتا اليابانية، لكن بأبيات الشعر العربي.', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Color(0xFF2C1810), height: 1.5)
                              ),
                              const SizedBox(height: 20),
                              
                              const Text(
                                'كيف تلعب؟', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A2C11))
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '1. سيظهر لك "صدر" البيت في أعلى الشاشة.\n'
                                '2. أسفل الشاشة، ستجد بطاقات مبعثرة.\n'
                                '3. اختر البطاقة التي تحتوي على "العجز" الصحيح بأسرع وقت.\n'
                                '4. الإجابة الصحيحة تمنحك البطاقة.', // تم حذف "والخطأ يخصم منك"
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Color(0xFF2C1810), height: 1.6),
                              ),
                              const SizedBox(height: 20),
                              
                              const Text(
                                'الفوز باللعبة:', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A2C11))
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'من يجمع أكبر عدد من البطاقات هو الفائز!', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Color(0xFF2C1810), height: 1.5)
                              ),
                              const SizedBox(height: 20),
                              
                              const Text(
                                'العقوبات (التجميد):', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A2C11))
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                // تقسيم النص إلى سطرين
                                'من يرتكب 3 أخطاء يتم تجميده لجولة.\nوإذا تكرر الخطأ، تتراكم جولات التجميد.', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Color(0xFF2C1810), height: 1.5)
                              ),
                              
                              const SizedBox(height: 30),
                              const Center(
                                child: Text(
                                  'استعدوا للتحدي!', 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Amiri', fontSize: 22, color: Colors.brown, fontWeight: FontWeight.bold)
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}