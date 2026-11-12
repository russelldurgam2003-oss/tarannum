import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../widgets/parchment_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _bgmVolume = 0.5;
  double _sfxVolume = 0.8;
  final AuthService _authService = AuthService();
  User? _currentUser;

  String _customName = '';
  String _customAvatar = '';
  bool _isLoadingProfile = true;

  // متغيرات الإحصائيات
  int _spWins = 0, _spLosses = 0, _mpWins = 0, _mpLosses = 0;
  List<String> _mpHistory = [];

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_currentUser != null) {
      final profile = await _authService.getUserProfile(_currentUser!.uid);
      if (profile != null) {
        setState(() {
          _customName = profile['displayName'] ?? _currentUser!.displayName ?? 'لاعب';
          _customAvatar = profile['avatarPath'] ?? '';
          // جلب الإحصائيات
          _spWins = profile['spWins'] ?? 0;
          _spLosses = profile['spLosses'] ?? 0;
          _mpWins = profile['mpWins'] ?? 0;
          _mpLosses = profile['mpLosses'] ?? 0;
          _mpHistory = List<String>.from(profile['mpHistory'] ?? []);
        });
      } else {
        setState(() {
          _customName = _currentUser!.displayName ?? 'لاعب';
        });
      }
    }
    setState(() => _isLoadingProfile = false);
  }

  void _handleSignIn() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      setState(() => _currentUser = user);
      _loadProfile();
    }
  }

  void _handleSignOut() async {
    await _authService.signOut();
    setState(() {
      _currentUser = null;
      _customName = '';
      _customAvatar = '';
      _spWins = 0; _spLosses = 0; _mpWins = 0; _mpLosses = 0; _mpHistory = [];
    });
  }

  void _editName() {
    TextEditingController controller = TextEditingController(text: _customName);
    showDialog(
      context: context,
      builder: (context) => ParchmentDialog(
        title: 'تغيير الاسم',
        content: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 20, color: Color(0xFF2C1810)),
          decoration: const InputDecoration(hintText: 'أدخل اسمك الجديد', hintStyle: TextStyle(fontFamily: 'Amiri', color: Colors.brown)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _authService.saveUserProfile(_currentUser!.uid, controller.text, _customAvatar);
                setState(() => _customName = controller.text);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _chooseAvatar() {
    final List<String> avatars = List.generate(9, (index) => 'assets/images/avatars/${index + 1}.png');
    showDialog(
      context: context,
      builder: (context) => ParchmentDialog(
        title: 'اختر صورة الشاعر',
        content: SizedBox(
          width: 400,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  await _authService.saveUserProfile(_currentUser!.uid, _customName, avatars[index]);
                  setState(() => _customAvatar = avatars[index]);
                  if (mounted) Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _customAvatar == avatars[index] ? Colors.green : Colors.transparent, width: 3),
                    image: DecorationImage(image: AssetImage(avatars[index]), fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
        actions: const [],
      ),
    );
  }

  // دالة عرض الإنجازات
  void _showAchievements() {
    showDialog(
      context: context,
      builder: (context) => ParchmentDialog(
        title: 'إنجازاتك',
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اللعب الفردي:', style: TextStyle(fontFamily: 'Amiri', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A2C11))),
              const SizedBox(height: 5),
              Text('فوز: $_spWins  |  خسارة: $_spLosses', style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Color(0xFF2C1810))),
              const Divider(color: Colors.brown, height: 30),
              
              const Text('اللعب الجماعي:', style: TextStyle(fontFamily: 'Amiri', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A2C11))),
              const SizedBox(height: 5),
              Text('فوز: $_mpWins  |  خسارة: $_mpLosses', style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Color(0xFF2C1810))),
              const SizedBox(height: 10),
              
              // سجل المباريات
              if (_mpHistory.isNotEmpty) ...[
                const Text('سجل المباريات الأخيرة:', style: TextStyle(fontFamily: 'Amiri', fontSize: 16, color: Colors.brown)),
                const SizedBox(height: 5),
                ..._mpHistory.reversed.take(5).map((h) => Text('• $h', style: const TextStyle(fontFamily: 'Amiri', fontSize: 16, color: Color(0xFF2C1810)))),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: Colors.brown, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
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
                child: Align(
                  alignment: const Alignment(0, -0.15),
                  child: Container(
                    width: isMobile ? MediaQuery.of(context).size.width * 0.85 : 600,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C1810).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15)],
                    ),
                    child: _isLoadingProfile 
                        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // قسم الحساب
                              if (_currentUser != null) ...[
                                GestureDetector(
                                  onTap: _chooseAvatar,
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.purple[100], 
                                      border: Border.all(color: Colors.amber, width: 3),
                                      image: _customAvatar.isNotEmpty 
                                          ? DecorationImage(image: AssetImage(_customAvatar), fit: BoxFit.cover)
                                          : (_currentUser!.photoURL != null ? DecorationImage(image: NetworkImage(_currentUser!.photoURL!), fit: BoxFit.cover) : null),
                                    ),
                                    child: _customAvatar.isEmpty && _currentUser!.photoURL == null
                                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_customName, style: const TextStyle(fontFamily: 'Amiri', fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                                    IconButton(icon: const Icon(Icons.edit, color: Colors.amber, size: 20), onPressed: _editName),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: _handleSignOut,
                                  icon: const Icon(Icons.logout, color: Colors.red),
                                  label: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Colors.red)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                // زر الإنجازات
                                ElevatedButton.icon(
                                  onPressed: _showAchievements,
                                  icon: const Icon(Icons.emoji_events, color: Colors.amber),
                                  label: const Text('الإنجازات', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Colors.brown, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade100,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                  ),
                                ),
                              ] else ...[
                                ElevatedButton.icon(
                                  onPressed: _handleSignIn,
                                  icon: const Icon(Icons.login),
                                  label: const Text('تسجيل الدخول بحساب Google', style: TextStyle(fontFamily: 'Amiri', fontSize: 18)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                                ),
                              ],
                              
                              const SizedBox(height: 30),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 20),

                              const Text('إعدادات الصوت', style: TextStyle(fontFamily: 'Amiri', fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              
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
                                      onChanged: (val) => setState(() => _sfxVolume = val),
                                    ),
                                  ),
                                ],
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
    );
  }
}