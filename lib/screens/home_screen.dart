import 'dart:ui'; 
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../widgets/parchment_dialog.dart';
import 'rules_screen.dart';
import 'game_screen.dart';
import 'lobby_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.playBGM(); 
  }

  Widget _buildLevelButton(BuildContext context, String text, String level, bool isMobile) {
    return InteractiveButton(
      text: text,
      isMobile: isMobile,
      color: Colors.brown.withOpacity(0.85),
      onPressed: () {
        Navigator.pop(context); 
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GameScreen(level: level)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          // --- الخلفية والمحتوى الأصلي ---
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => AudioService.playBGM(), 
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.jpg'),
                  fit: BoxFit.cover, 
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Align(
                        alignment: const Alignment(0, -0.15),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 5, horizontal: isMobile ? 40 : 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min, 
                            children: [
                              Transform.translate(
                                offset: const Offset(0, 15), 
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/images/logo.png',
                                      height: isMobile ? 110 : 300, 
                                      width: isMobile ? 110 : 300,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.menu_book, size: 100, color: Colors.white);
                                      },
                                    ),
                                    SizedBox(height: isMobile ? 5 : 15),
                                    Text(
                                      'لعبة الشعر العربي',
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 26, 
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        shadows: const [Shadow(blurRadius: 5.0, color: Colors.black, offset: Offset(1.0, 1.0))],
                                        fontFamily: 'Amiri',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: isMobile ? 15 : 30), 

                              AnimatedCustomButton(
                                text: 'اللعب الفردي',
                                isMobile: isMobile,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ParchmentDialog(
                                      title: 'اختر مستوى الصعوبة',
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildLevelButton(context, 'مبتدأ 🌱', 'beginner', isMobile),
                                          const SizedBox(height: 8),
                                          _buildLevelButton(context, 'متوسط 📜', 'intermediate', isMobile),
                                          const SizedBox(height: 8),
                                          _buildLevelButton(context, 'محترف 👑', 'expert', isMobile),
                                        ],
                                      ),
                                      actions: const [], 
                                    ),
                                  );
                                },
                              ),
                              
                              SizedBox(height: isMobile ? 8 : 12),

                              AnimatedCustomButton(
                                text: 'اللعب مع الأصدقاء',
                                isMobile: isMobile,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LobbyScreen()),
                                  );
                                },
                              ),
                              
                              SizedBox(height: isMobile ? 5 : 10), 

                          // إزاحة الزر قليلاً لليمين ليكون في المنتصف بصرياً
                          Transform.translate(
                            offset: const Offset(13, 0), 
                            child: InteractiveTextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RulesScreen()),
                                );
                              },
                              isMobile: isMobile,
                              text: 'قوانين اللعبة',
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

          // --- زر الإعدادات في الزاوية العلوية اليسرى ---
                    // --- زر الإعدادات في الزاوية العلوية اليسرى ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 105, 
            left: 5,
            child: InteractiveSettingsIcon(
              size: 45,
              onPressed: () { // <--- لاحظي onPressed وليس onTap
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====== الأزرار التفاعلية ======
class AnimatedCustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isMobile;

  const AnimatedCustomButton({super.key, required this.text, required this.onPressed, required this.isMobile});

  @override
  State<AnimatedCustomButton> createState() => _AnimatedCustomButtonState();
}

class _AnimatedCustomButtonState extends State<AnimatedCustomButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    if (_isPressed) { scale = 0.88; } else if (_isHovered) { scale = 1.08; }

    double shadowBlur = _isHovered ? 20.0 : 8.0; 
    double shadowOpacity = _isHovered ? 1.0 : 0.6;
    double shadowOffsetY = _isHovered ? 12.0 : 5.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) { setState(() => _isPressed = false); widget.onPressed(); },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: SizedBox(
            width: widget.isMobile ? 210 : 400, 
            height: widget.isMobile ? 50 : 85,   
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: shadowOffsetY, left: 0, right: 0, bottom: 0,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(shadowOpacity), BlendMode.srcIn),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: shadowBlur, sigmaY: shadowBlur),
                      child: Image.asset('assets/images/button_bg.png', fit: BoxFit.fill),
                    ),
                  ),
                ),
                Image.asset('assets/images/button_bg.png', fit: BoxFit.fill),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.isMobile ? 15 : 22, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white, 
                        fontFamily: 'Amiri', 
                        shadows: const [Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(1.0, 1.0))]
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

class InteractiveButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final bool isMobile;

  const InteractiveButton({super.key, required this.text, required this.onPressed, required this.color, required this.isMobile});

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    if (_isPressed) { scale = 0.92; } else if (_isHovered) { scale = 1.05; }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) { setState(() => _isPressed = false); widget.onPressed(); },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: widget.isMobile ? 10 : 14),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1.5),
              boxShadow: _isHovered ? [BoxShadow(color: Colors.black45, blurRadius: 10, offset: const Offset(0, 4))] : [],
            ),
            child: Center(
              child: Text(
                widget.text,
                style: TextStyle(fontFamily: 'Amiri', fontSize: widget.isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class InteractiveTextButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isMobile;

  const InteractiveTextButton({super.key, required this.text, required this.onPressed, required this.isMobile});

  @override
  State<InteractiveTextButton> createState() => _InteractiveTextButtonState();
}
class _InteractiveTextButtonState extends State<InteractiveTextButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    if (_isPressed) { scale = 0.90; } else if (_isHovered) { scale = 1.05; }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) { setState(() => _isPressed = false); widget.onPressed(); },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: widget.isMobile ? 16 : 24),
              const SizedBox(width: 5),
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: widget.isMobile ? 14 : 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } 
}
class InteractiveSettingsIcon extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;

  const InteractiveSettingsIcon({super.key, required this.onPressed, this.size = 35});

  @override
  State<InteractiveSettingsIcon> createState() => _InteractiveSettingsIconState();
}

class _InteractiveSettingsIconState extends State<InteractiveSettingsIcon> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    if (_isPressed) {
      scale = 0.85; // يصغر عند الضغط
    } else if (_isHovered) {
      scale = 1.15; // يكبر عند التأشير
    }

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
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Image.asset(
            'assets/images/settings_icon.png',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}