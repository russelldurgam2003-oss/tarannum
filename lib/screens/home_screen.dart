import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/parchment_dialog.dart';
import 'rules_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioStarted = false;

  @override
  void initState() {
    super.initState();
    _setupAudio();
  }

  void _setupAudio() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setSource(AssetSource('audio/bgm.mp3'));
    } catch (e) {
      print('خطأ في تهيئة الموسيقى: $e');
    }
  }

  void _startMusic() async {
    if (_isAudioStarted) return;
    try {
      await _audioPlayer.resume();
      setState(() {
        _isAudioStarted = true;
      });
    } catch (e) {
      print('خطأ في تشغيل الموسيقى: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // دالة مساعدة لإنشاء أزرار اختيار المستوى
  Widget _buildLevelButton(BuildContext context, String text, String level) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown.withOpacity(0.85),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () {
          Navigator.pop(context); // إغلاق نافذة المستويات
          _audioPlayer.pause(); 
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GameScreen(level: level)),
          ).then((_) {
            if (_isAudioStarted) _audioPlayer.resume(); 
          });
        },
        child: Text(
          text,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, 
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startMusic,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black26,
                BlendMode.darken,
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 350, 
                            width: 350,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.menu_book, size: 200, color: Colors.white);
                            },
                          ),
                          
                          const Text(
                            'لعبة الشعر العربي',
                            style: TextStyle(
                              fontSize: 26, 
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 5.0,
                                  color: Colors.black,
                                  offset: Offset(1.0, 1.0),
                                ),
                              ],
                              fontFamily: 'Amiri',
                            ),
                          ),
                          const SizedBox(height: 40),

                          // زر اللعب الفردي
                          AnimatedCustomButton(
                            text: 'اللعب الفردي',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => ParchmentDialog(
                                  title: 'اختر مستوى الصعوبة',
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildLevelButton(context, 'مبتدئ (100 بيت)', 'beginner'),
                                      const SizedBox(height: 10),
                                      _buildLevelButton(context, 'متوسط (200 بيت)', 'intermediate'),
                                      const SizedBox(height: 10),
                                      _buildLevelButton(context, 'محترف (300 بيت)', 'expert'),
                                    ],
                                  ),
                                  actions: const [], 
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 15),

                          // زر اللعب مع الأصدقاء
                          AnimatedCustomButton(
                            text: 'اللعب مع الأصدقاء (أونلاين)',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => ParchmentDialog(
                                  title: 'قريباً',
                                  content: const Text(
                                    'خاصية اللعب مع الأصدقاء عبر الإنترنت قيد التطوير.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: 'Amiri', fontSize: 22, color: Color(0xFF2C1810), height: 1.5),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('حسناً', style: TextStyle(fontFamily: 'Amiri', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 25),

                          // زر القوانين
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RulesScreen()),
                              );
                            },
                            icon: const Icon(Icons.info_outline, color: Colors.white),
                            label: const Text(
                              'قوانين اللعبة',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ====== ودجت الزر التفاعلي مع الظل المطابق للشكل ======
class AnimatedCustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const AnimatedCustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<AnimatedCustomButton> createState() => _AnimatedCustomButtonState();
}

class _AnimatedCustomButtonState extends State<AnimatedCustomButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    if (_isPressed) {
      scale = 0.95; 
    } else if (_isHovered) {
      scale = 1.05; 
    }

    double shadowBlur = _isHovered ? 12.0 : 6.0; 
    double shadowOpacity = _isHovered ? 0.8 : 0.5;
    double shadowOffsetY = _isHovered ? 8.0 : 4.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed(); 
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: SizedBox(
            width: 450,
            height: 85,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // الظل المطابق
                Positioned(
                  top: shadowOffsetY,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(shadowOpacity),
                      BlendMode.srcIn, 
                    ),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: shadowBlur, sigmaY: shadowBlur),
                      child: Image.asset(
                        'assets/images/button_bg.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                // الزر
                Image.asset(
                  'assets/images/button_bg.png',
                  fit: BoxFit.fill,
                ),
                // النص
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Amiri',
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}