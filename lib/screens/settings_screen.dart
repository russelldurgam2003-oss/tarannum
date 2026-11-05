import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _bgmVolume = 0.5;
  double _sfxVolume = 0.8;

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
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken), 
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // شريط علوي
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
                        // --- إضافة الخلفية البنية للعنوان ---
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.brown.withOpacity(0.75), 
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 1.5), 
                          ),
                          child: Text(
                            'الإعدادات',
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

              // محتوى الإعدادات
              Expanded(
                // --- استخدام Align لرفع النافذة قليلاً ---
                child: Align(
                  alignment: const Alignment(0, -0.30),
                  child: Container(
                    width: isMobile ? MediaQuery.of(context).size.width * 0.85 : 600,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C1810).withOpacity(0.9), // خلفية بنية
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2), // إطار ذهبي
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'إعدادات الصوت',
                          style: TextStyle(fontFamily: 'Amiri', fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        
                        // التحكم في موسيقى الخلفية
                        Row(
                          children: [
                            const Icon(Icons.music_note, color: Colors.amber),
                            const SizedBox(width: 10),
                            const Text('الموسيقى', style: TextStyle(fontFamily: 'Amiri', color: Colors.white, fontSize: 18)),
                            Expanded(
                              child: Slider(
                                value: _bgmVolume,
                                activeColor: Colors.amber,
                                inactiveColor: Colors.white24,
                                onChanged: (val) {
                                  setState(() => _bgmVolume = val);
                                  AudioService.setBgmVolume(val); 
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 10),

                        // التحكم في المؤثرات الصوتية
                        Row(
                          children: [
                            const Icon(Icons.volume_up, color: Colors.amber),
                            const SizedBox(width: 10),
                            const Text('المؤثرات', style: TextStyle(fontFamily: 'Amiri', color: Colors.white, fontSize: 18)),
                            Expanded(
                              child: Slider(
                                value: _sfxVolume,
                                activeColor: Colors.amber,
                                inactiveColor: Colors.white24,
                                onChanged: (val) {
                                  setState(() => _sfxVolume = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 20),

                        // زر تسجيل الدخول
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تسجيل الدخول بحساب Google سيتوفر قريباً!', style: TextStyle(fontFamily: 'Amiri'))),
                            );
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('تسجيل الدخول بحساب Google', style: TextStyle(fontFamily: 'Amiri', fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        )
                      ],
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