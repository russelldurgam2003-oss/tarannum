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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward(); 
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover, 
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken), 
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20, vertical: 5),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_forward, color: Colors.white, size: isMobile ? 24 : 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        // إضافة الخلفية البنية للكلمة
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.brown.withOpacity(0.75), // اللون البني
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 1.5), // إطار خفيف
                          ),
                          child: Text(
                            'قوانين اللعبة',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 22 : 32,
                              color: Colors.white,
                              shadows: const [Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2))]
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 40 : 48), 
                  ],
                ),
              ),
              
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? MediaQuery.of(context).size.width * 0.88 : 750, 
                          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.80 : 1000, 
                        ), 
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/parchment_vertical.png'),
                            fit: BoxFit.fill, 
                          ),
                        ),
                        padding: EdgeInsets.only(
                          left: isMobile ? 40 : 130, 
                          right: isMobile ? 40 : 130, 
                          top: isMobile ? 90 : 120, 
                          bottom: isMobile ? 90 : 120
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center, 
                            children: [
                              Text(
                                'مرحباً بك في ترنم!', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: isMobile ? 15 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF4A2C11))
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'لعبة مستوحاة من الكاروتا اليابانية،\nلكن بأبيات الشعر العربي.', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: isMobile ? 12 : 18, color: const Color(0xFF2C1810), height: 1.3)
                              ),
                              const SizedBox(height: 15),
                              
                              Text(
                                'كيف تلعب؟', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: isMobile ? 14 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF4A2C11))
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '1. سيظهر لك "صدر" البيت في الأعلى.\n'
                                '2. اختر بطاقة "العجز" الصحيحة من اللوحة.\n'
                                '3. الإجابة الصحيحة تمنحك البطاقة.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: isMobile ? 12 : 18, color: const Color(0xFF2C1810), height: 1.4),
                              ),
                              const SizedBox(height: 15),
                              
                              Text(
                                'الفوز باللعبة:', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: isMobile ? 14 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF4A2C11))
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'من يجمع أكبر عدد من البطاقات هو الفائز!', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: isMobile ? 12 : 18, color: const Color(0xFF2C1810), height: 1.3)
                              ),
                              const SizedBox(height: 15),
                              
                              Text(
                                'العقوبات (التجميد):', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: isMobile ? 14 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF4A2C11))
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '3 أخطاء = تجميد جولة.\nالتكرار يضاعف الجولات.', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: isMobile ? 12 : 18, color: const Color(0xFF2C1810), height: 1.3)
                              ),
                              
                              const SizedBox(height: 5),
                              Center(
                                child: Text(
                                  'استعدوا للمنافسة!', 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Amiri', fontSize: isMobile ? 15 : 22, color: Colors.brown, fontWeight: FontWeight.bold)
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