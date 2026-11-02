import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/verse_service.dart'; // <--- مهم لتحميل الأبيات
import '../widgets/parchment_dialog.dart';
import 'multiplayer_game_screen.dart'; // <--- مهم للانتقال لشاشة اللعب

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final VerseService _verseService = VerseService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  void _createRoom() async {
    setState(() => _isLoading = true);
    String roomCode = await _firebaseService.createRoom();
    setState(() => _isLoading = false);

    if (mounted) {
      _showWaitingDialog(roomCode);
    }
  }

  void _joinRoom() async {
    if (_codeController.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    String code = _codeController.text.toUpperCase();
    bool success = await _firebaseService.joinRoom(code);
    
    if (mounted) {
      if (success) {
        // تحميل الأبيات (سنستخدم مستوى المحترفين لأنه يحتوي على 300 بيت للتنوع)
        final verses = await _verseService.loadVerses('expert');
        
        if (mounted) {
          // الانتقال لشاشة اللعب بصفتك اللاعب الثاني (p2)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MultiplayerGameScreen(
                roomCode: code,
                playerId: 'p2',
                verses: verses,
              ),
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('عذراً، الكود غير صحيح أو الغرفة ممتلئة!', style: TextStyle(fontFamily: 'Amiri')),
          ),
        );
      }
    }
  }

  void _showWaitingDialog(String roomCode) {
    bool isNavigating = false; // لمنع الانتقال المتكرر

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: _firebaseService.listenToRoom(roomCode),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              
              // التحقق مما إذا انضم اللاعب الثاني
              if (data['player2Joined'] == true && data['status'] == 'playing' && !isNavigating) {
                isNavigating = true;
                
                Future.delayed(Duration.zero, () async {
                  Navigator.pop(context); // إغلاق نافذة الانتظار
                  
                  // تحميل الأبيات
                  final verses = await _verseService.loadVerses('expert'); 
                  
                  if (context.mounted) {
                    // الانتقال لشاشة اللعب بصفتك اللاعب الأول (p1)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MultiplayerGameScreen(
                          roomCode: roomCode,
                          playerId: 'p1',
                          verses: verses,
                        ),
                      ),
                    );
                  }
                });
              }
            }
            
            return ParchmentDialog(
              title: 'غرفة الانتظار',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('شاركي هذا الكود مع صديقك:', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: Color(0xFF2C1810))),
                  const SizedBox(height: 10),
                  Text(
                    roomCode,
                    style: const TextStyle(fontFamily: 'Amiri', fontSize: 40, fontWeight: FontWeight.bold, color: Colors.brown, letterSpacing: 5),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.brown),
                  const SizedBox(height: 10),
                  const Text('في انتظار انضمام الصديق...', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Color(0xFF2C1810))),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اللعب الجماعي', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
        centerTitle: true, 
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
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
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر إنشاء غرفة
                    ElevatedButton.icon(
                      onPressed: _createRoom,
                      icon: const Icon(Icons.add, size: 30),
                      label: const Text('إنشاء غرفة جديدة', style: TextStyle(fontFamily: 'Amiri', fontSize: 24)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        backgroundColor: Colors.brown, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text('أو', style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Amiri')),
                    const SizedBox(height: 40),
                    // حقل إدخال كود الغرفة
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _codeController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontFamily: 'Amiri', letterSpacing: 5, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'أدخل كود الغرفة',
                          hintStyle: const TextStyle(color: Colors.white54, fontFamily: 'Amiri', letterSpacing: 1),
                          filled: true,
                          fillColor: Colors.black45,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // زر الانضمام
                    ElevatedButton(
                      onPressed: _joinRoom,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        backgroundColor: Colors.brown, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('انضمام', style: TextStyle(fontFamily: 'Amiri', fontSize: 24)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}