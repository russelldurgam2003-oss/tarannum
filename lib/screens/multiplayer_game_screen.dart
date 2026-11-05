import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/audio_service.dart';
import '../models/verse.dart';
import '../widgets/parchment_dialog.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final String roomCode;
  final String playerId;
  final List<Verse> verses;

  const MultiplayerGameScreen({super.key, required this.roomCode, required this.playerId, required this.verses});

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final TransformationController _transformController = TransformationController();

  List<Verse?> _playerCards = List<Verse?>.filled(25, null);
  List<Verse?> _aiCards = List<Verse?>.filled(25, null);
  Verse? _currentVerse;
  int _playerScore = 0, _aiScore = 0, _wrongAttempts = 0;
  
  bool _isPlayerFrozen = false;
  bool _isOppFrozen = false;
  int _playerFreezeRounds = 0;
  int _oppFreezeRounds = 0;

  // متغيرات لتتبع الحالة السابقة ومنع تكرار الإشعارات
  bool _prevPlayerFrozen = false;
  bool _prevOppFrozen = false;
  int _prevPlayerFreezeRounds = 0;
  int _prevOppFreezeRounds = 0;

  bool _isFirstLoad = true, _isLocked = false;
  bool _isSubmitting = false, _isSkipping = false;
  List<Verse> _prevP1Won = [], _prevP2Won = [];
  int? _correctRevealedVerseId;
  final Set<int> _wrongTappedIds = {};

  bool _hasSetInitialZoom = false;
  Size _lastViewportSize = Size.zero;
  double _currentScale = 1.0, _fitScale = 1.0;
  int _lastSeenEventId = 0;

  final GlobalKey _playerWonKey = GlobalKey(), _aiWonKey = GlobalKey();
  final Map<int, GlobalKey> _cardKeys = {};
  final Map<int, Offset> _cardPositions = {};
  final Map<int, Size> _cardSizes = {};
  OverlayEntry? _currentNotification;

  @override
  void initState() {
    super.initState();
    AudioService.pauseBGM();
    _transformController.addListener(() {
      final newScale = _transformController.value.getMaxScaleOnAxis();
      if ((newScale - _currentScale).abs() > 0.01) setState(() => _currentScale = newScale);
    });
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    _firebaseService.startGame(widget.roomCode, widget.verses);
  }

  @override
  void dispose() {
    AudioService.playBGM();
    _sfxPlayer.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _fitToScreen(Size viewportSize) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;
    final scale = min(viewportSize.width / 1800, viewportSize.height / 1200) * 0.98;
    _fitScale = scale;
    _transformController.value = Matrix4.identity()..translate((viewportSize.width - 1800 * scale) / 2, (viewportSize.height - 1200 * scale) / 2)..scale(scale);
  }

  void _playSound(String path) async { try { await _sfxPlayer.stop(); await _sfxPlayer.play(AssetSource(path)); } catch (e) {} }

  void _showPauseMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ParchmentDialog(
        title: 'القائمة',
        content: const Text('هل تريد مغادرة اللعبة؟ (إذا غادرت ستعتبر خاسراً)', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Color(0xFF2C1810))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('استئناف', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _firebaseService.leaveGame(widget.roomCode, widget.playerId);
              Navigator.pop(context);
            },
            child: const Text('مغادرة اللعبة', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _checkAnswer(Verse tappedVerse) {
    if (_isLocked || _isPlayerFrozen || _isSubmitting) return;
    _isSubmitting = true;
    final isCorrect = _currentVerse?.id == tappedVerse.id;

    if (isCorrect) {
      _playSound('audio/correct.mp3');
      setState(() { _isLocked = true; _correctRevealedVerseId = tappedVerse.id; });
      _firebaseService.submitAnswer(widget.roomCode, widget.playerId, tappedVerse.id);
    } else {
      _playSound('audio/wrong.mp3');
      _firebaseService.submitAnswer(widget.roomCode, widget.playerId, tappedVerse.id);
      setState(() => _wrongTappedIds.add(tappedVerse.id));
      Future.delayed(const Duration(milliseconds: 800), () { if (mounted) setState(() => _wrongTappedIds.remove(tappedVerse.id)); });
    }
    Future.delayed(const Duration(milliseconds: 500), () { _isSubmitting = false; });
  }

  void _triggerFly(Verse verse, {required bool toPlayer}) {
    final sourcePos = _cardPositions[verse.id]; final sourceSize = _cardSizes[verse.id];
    if (sourcePos == null || sourceSize == null) return;
    final targetBox = (toPlayer ? _playerWonKey : _aiWonKey).currentContext?.findRenderObject() as RenderBox?;
    if (targetBox == null || !targetBox.hasSize) return;

    _playSound('audio/swipe.mp3');
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (context) => _FlyingCard(startPos: sourcePos, endPos: targetBox.localToGlobal(Offset.zero), startSize: sourceSize, endSize: targetBox.size, verse: verse, onComplete: () => entry.remove()));
    overlay.insert(entry);
  }

  void _showNotification(String message, Color color) {
    _currentNotification?.remove(); // إزالة الإشعار السابق إن وجد
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0, left: 0, right: 0,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: color.withOpacity(0.95),
              child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
            ),
          ),
        ),
      ),
    );
    _currentNotification = entry;
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentNotification == entry) {
        _currentNotification?.remove();
        _currentNotification = null;
      }
    });
  }

  void _handleEvent(String eventStr) {
    List<String> parts = eventStr.split('|');
    if (parts.length < 2) return;
    String type = parts[0];
    String pId = parts[1];

    if (!mounted) return;

    if (type == 'correct') {
      String poet = parts.length > 2 ? parts[2] : '';
      if (pId == widget.playerId) _showNotification('أحسنت! قال الشاعر: $poet', Colors.green);
      else _showNotification('الخصم أخذ البطاقة! قال الشاعر: $poet', Colors.teal);
    } else if (type == 'skip') {
      _showNotification('🚫 كلاكما مجمد! تم تخطي هذه البطاقة.', Colors.purple);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firebaseService.listenToRoom(widget.roomCode),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          int currentEventId = data['lastEventId'] ?? 0;
          if (_lastSeenEventId == 0) { _lastSeenEventId = currentEventId; } 
          else if (currentEventId > _lastSeenEventId) {
            String event = data['lastEvent'] ?? '';
            if (event.isNotEmpty) { WidgetsBinding.instance.addPostFrameCallback((_) => _handleEvent(event)); }
            _lastSeenEventId = currentEventId;
          }

          final status = data['status'];
          final p1WonList = (data['p1Won'] as List?)?.map((e) => Verse.fromJson(e)).toList() ?? [];
          final p2WonList = (data['p2Won'] as List?)?.map((e) => Verse.fromJson(e)).toList() ?? [];

          if (_isFirstLoad) { _prevP1Won = p1WonList; _prevP2Won = p2WonList; _isFirstLoad = false; } 
          else {
            if (p1WonList.length > _prevP1Won.length) { WidgetsBinding.instance.addPostFrameCallback((_) => _triggerFly(p1WonList.last, toPlayer: widget.playerId == 'p1')); } 
            else if (p2WonList.length > _prevP2Won.length) { WidgetsBinding.instance.addPostFrameCallback((_) => _triggerFly(p2WonList.last, toPlayer: widget.playerId == 'p2')); }
            _prevP1Won = p1WonList; _prevP2Won = p2WonList;
          }

          if (status == 'finished') return _buildEndScreen(data);

          final currentVerseMap = data['currentVerse'];
          if (currentVerseMap == null) return const Center(child: CircularProgressIndicator());

          _currentVerse = Verse.fromJson(currentVerseMap);
          _playerScore = widget.playerId == 'p1' ? (data['p1Score'] ?? 0) : (data['p2Score'] ?? 0);
          _aiScore = widget.playerId == 'p1' ? (data['p2Score'] ?? 0) : (data['p1Score'] ?? 0);
          
          final p1CardsList = (data['p1Cards'] as List?)?.map((e) => e != null ? Verse.fromJson(e) : null).toList() ?? List<Verse?>.filled(25, null);
          final p2CardsList = (data['p2Cards'] as List?)?.map((e) => e != null ? Verse.fromJson(e) : null).toList() ?? List<Verse?>.filled(25, null);
          
          _playerCards = widget.playerId == 'p1' ? p1CardsList : p2CardsList;
          _aiCards = widget.playerId == 'p1' ? p2CardsList : p1CardsList;
          
          _wrongAttempts = widget.playerId == 'p1' ? (data['p1Wrong'] ?? 0) : (data['p2Wrong'] ?? 0);
          _isPlayerFrozen = widget.playerId == 'p1' ? (data['p1FrozenThisRound'] ?? false) : (data['p2FrozenThisRound'] ?? false);
          _isOppFrozen = widget.playerId == 'p1' ? (data['p2FrozenThisRound'] ?? false) : (data['p1FrozenThisRound'] ?? false);
          
          _playerFreezeRounds = widget.playerId == 'p1' ? (data['p1Freeze'] ?? 0) : (data['p2Freeze'] ?? 0);
          _oppFreezeRounds = widget.playerId == 'p1' ? (data['p2Freeze'] ?? 0) : (data['p1Freeze'] ?? 0);

          // ==========================================
          // نظام الإشعارات الجديد المبني على الحالة (State)
          // ==========================================
          if (!_isFirstLoad) {
            // 1. إشعار التحذير الأصفر (عند الوصول لـ 3 أخطاء)
            if (_playerFreezeRounds > _prevPlayerFreezeRounds) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showNotification('⚠️ 3 أخطاء! ستُجمّد $_playerFreezeRounds ${_playerFreezeRounds == 1 ? "جولة" : "جولات"}', Colors.orange);
              });
            }
            if (_oppFreezeRounds > _prevOppFreezeRounds) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showNotification('⚠️ الخصم أخطأ 3 مرات! سيُجمّد $_oppFreezeRounds ${_oppFreezeRounds == 1 ? "جولة" : "جولات"}', Colors.orangeAccent);
              });
            }

            // 2. إشعار التجميد الفعلي (عند بدء الجولة المجمدة)
            if (_isPlayerFrozen && !_prevPlayerFrozen) {
              String freezeText = _playerFreezeRounds == 1 ? "لجولة واحدة" : (_playerFreezeRounds == 2 ? "لجولتين" : "لـ $_playerFreezeRounds جولات");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showNotification('🚫 لقد تجمدت $freezeText!', Colors.red);
              });
            }
            if (_isOppFrozen && !_prevOppFrozen) {
              String freezeText = _oppFreezeRounds == 1 ? "لجولة واحدة" : (_oppFreezeRounds == 2 ? "لجولتين" : "لـ $_oppFreezeRounds جولات");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showNotification('🚫 الخصم مجمّد $freezeText!', Colors.redAccent);
              });
            }

            // تحديث الحالات السابقة
            _prevPlayerFreezeRounds = _playerFreezeRounds;
            _prevOppFreezeRounds = _oppFreezeRounds;
            _prevPlayerFrozen = _isPlayerFrozen;
            _prevOppFrozen = _isOppFrozen;
          }
          // ==========================================

          if (_isPlayerFrozen && _isOppFrozen && data['isAnswered'] == false && !_isSkipping) {
            _isSkipping = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showNotification('🚫 كلاكما مجمد! جاري تخطي البطاقة...', Colors.purple);
              Future.delayed(const Duration(seconds: 3), () { _firebaseService.skipCard(widget.roomCode); _isSkipping = false; });
            });
          }

          if (data['isAnswered'] == false) { _isLocked = false; _correctRevealedVerseId = null; }

          return SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildSadrBar(),
                _buildWonPilesBar(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      _lastViewportSize = size;
                      if (!_hasSetInitialZoom && size.width > 0) {
                        _hasSetInitialZoom = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) => _fitToScreen(size));
                      }
                      return _buildWoodenFloor();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: const Color(0xFF1A0D08),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // عداد الأخطاء (أقصى اليسار)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _wrongAttempts > 0 ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _wrongAttempts > 0 ? Colors.redAccent : Colors.white30, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('الأخطاء: ', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Amiri')),
                    Text('$_wrongAttempts / 3', style: TextStyle(color: _wrongAttempts > 0 ? Colors.redAccent : Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
              // حالة التجميد + زر الإعدادات (أقصى اليمين)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isPlayerFrozen)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: const Text('مجمّد 🚫', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
                    ),
                  GestureDetector(
                    onTap: _showPauseMenu,
                    child: InteractiveSettingsIcon(
                    size: 30,
                    onPressed: _showPauseMenu,
                  ),
                  ),
                ],
              ),
            ],
          ),
          // اسم اللعبة (في المنتصف)
          const Text('ترنم', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
        ],
      ),
    );
  }

  Widget _buildSadrBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1810), borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Text(_currentVerse?.sadr ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.3, fontFamily: 'Amiri')),
    );
  }

  Widget _buildWonPilesBar() {
    final myWon = widget.playerId == 'p1' ? _prevP1Won : _prevP2Won;
    final oppWon = widget.playerId == 'p1' ? _prevP2Won : _prevP1Won;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF1A0D08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildWonPile(_playerWonKey, myWon, 'مكتسباتك', Colors.lightBlueAccent),
          _buildWonPile(_aiWonKey, oppWon, 'مكتسبات الخصم', Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildWonPile(GlobalKey key, List<Verse> cards, String label, Color color) {
    return Row(
      children: [
        Text('$label: ${cards.length}', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
        const SizedBox(width: 8),
        Container(
          key: key, width: 40, height: 50,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.7), width: 2)),
          child: Stack(
            children: [
              for (int i = 0; i < cards.length && i < 4; i++)
                Positioned(left: 2.0 + i * 1.0, top: 2.0 + i * 1.0, right: 2.0, bottom: 2.0 + (4 - i) * 1.8, child: Container(decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(2), border: Border.all(color: const Color(0xFFD4AF37), width: 1.0)))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWoodenFloor() {
    final isPanEnabled = _currentScale > _fitScale * 1.05;
    return Container(
      decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/wood_bg.jpg'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken)), color: Color(0xFF3E2723)),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformController, minScale: 0.2, maxScale: 5.0, constrained: false,
              boundaryMargin: const EdgeInsets.all(600), panEnabled: isPanEnabled, scaleEnabled: true,
              child: SizedBox(
                width: 1800, height: 1200,
                child: Container(
                  margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(image: const DecorationImage(image: AssetImage('assets/images/mat_red.png'), fit: BoxFit.fill), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.7), spreadRadius: 5, blurRadius: 25, offset: const Offset(0, 10))]),
                  child: Row(
                    children: [
                      Expanded(child: _buildCardZone(_playerCards)),
                      Container(width: 40, margin: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(20))),
                      Expanded(child: _buildCardZone(_aiCards)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(bottom: 12, left: 12, child: _buildZoomControls()),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.zoom_out, color: Colors.white), onPressed: () => setState(() => _transformController.value = _transformController.value.clone()..scale(0.8))),
          IconButton(icon: const Icon(Icons.center_focus_strong, color: Colors.white), onPressed: () => _fitToScreen(_lastViewportSize)),
          IconButton(icon: const Icon(Icons.zoom_in, color: Colors.white), onPressed: () => setState(() => _transformController.value = _transformController.value.clone()..scale(1.2))),
        ],
      ),
    );
  }

  Widget _buildCardZone(List<Verse?> cards) {
    final columns = <List<Verse?>>[[], [], [], [], []];
    for (int i = 0; i < cards.length; i++) { columns[i % 5].add(cards[i]); }
    return Row(
      children: [
        for (int colIdx = 0; colIdx < 5; colIdx++)
          Expanded(child: Column(children: [ for (final verse in columns[colIdx]) Expanded(child: Padding(padding: const EdgeInsets.all(3.0), child: verse == null ? const SizedBox.shrink() : _buildKarutaCard(verse)))]))
      ],
    );
  }

  Widget _buildKarutaCard(Verse verse) {
    final isCorrectRevealed = _correctRevealedVerseId == verse.id;
    final isWrongTapped = _wrongTappedIds.contains(verse.id);
    Color bgColor = const Color(0xFFFDFBF5); Color borderColor = const Color(0xFF2E7D32);
    if (isCorrectRevealed) { bgColor = const Color(0xFFC8E6C9); borderColor = Colors.green; } else if (isWrongTapped) { bgColor = const Color(0xFFFFCDD2); borderColor = Colors.red; }
    final key = _cardKeys.putIfAbsent(verse.id, () => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) { _cardPositions[verse.id] = box.localToGlobal(Offset.zero); _cardSizes[verse.id] = box.size; }
    });
    return GestureDetector(
      onTap: (_isLocked || _isPlayerFrozen) ? null : () => _checkAnswer(verse),
      child: Container(
        key: key, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: borderColor, width: 4.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6, offset: const Offset(2, 4))]),
        padding: const EdgeInsets.all(4),
        child: Center(child: Text(verse.ajz, textAlign: TextAlign.center, softWrap: true, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3, color: Color(0xFF1A1A1A), fontFamily: 'Amiri'))),
      ),
    );
  }

  Widget _buildEndScreen(Map<String, dynamic> data) {
    final p1Score = data['p1Score'] ?? 0;
    final p2Score = data['p2Score'] ?? 0;
    final myScore = widget.playerId == 'p1' ? p1Score : p2Score;
    final oppScore = widget.playerId == 'p1' ? p2Score : p1Score;
    final winnerId = data['winnerId'];
    final endReason = data['endReason'];

    String resultText;
    if (endReason == 'leave') {
      if (winnerId == widget.playerId) {
        resultText = '🎉 مبروك! لقد فزت!\n(الخصم غادر اللعبة)';
      } else {
        resultText = '😢 للأسف، خسرت.\n(لقد غادرت اللعبة)';
      }
    } else {
      resultText = myScore > oppScore ? '🎉 مبروك! لقد فزت!' : (myScore < oppScore ? '😢 للأسف، خسرت.' : '🤝 تعادل!');
    }

    return Center(
      child: ParchmentDialog(
        title: 'انتهت اللعبة',
        content: Column(
          children: [
            Text('مكتسباتك: $myScore بطاقة', style: const TextStyle(fontSize: 22, fontFamily: 'Amiri', color: Color(0xFF2C1810))),
            const SizedBox(height: 8),
            Text('مكتسبات الخصم: $oppScore بطاقة', style: const TextStyle(fontSize: 22, fontFamily: 'Amiri', color: Color(0xFF2C1810))),
            const SizedBox(height: 20),
            Text(resultText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Amiri', color: Colors.brown)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('العودة للقائمة', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: Colors.brown, fontWeight: FontWeight.bold)))],
      ),
    );
  }
}

class _FlyingCard extends StatefulWidget {
  final Offset startPos, endPos; final Size startSize, endSize; final Verse verse; final VoidCallback onComplete;
  const _FlyingCard({required this.startPos, required this.endPos, required this.startSize, required this.endSize, required this.verse, required this.onComplete});
  @override
  State<_FlyingCard> createState() => _FlyingCardState();
}
class _FlyingCardState extends State<_FlyingCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this); _controller.forward().whenComplete(widget.onComplete); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) {
      final t = Curves.easeInOut.transform(_controller.value);
      final left = widget.startPos.dx + (widget.endPos.dx - widget.startPos.dx) * t; final top = widget.startPos.dy + (widget.endPos.dy - widget.startPos.dy) * t;
      final width = widget.startSize.width + (widget.endSize.width - widget.startSize.width) * t; final height = widget.startSize.height + (widget.endSize.height - widget.startSize.height) * t;
      final angle = t * pi; final isFront = angle < (pi / 2);
      Widget cardContent = isFront
          ? Container(decoration: BoxDecoration(color: const Color(0xFFFDFBF5), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF2E7D32), width: 4.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12, offset: const Offset(3, 6))]), padding: const EdgeInsets.all(4), child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.verse.ajz, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2, color: Color(0xFF1A1A1A), fontFamily: 'Amiri')))))
          : Transform(transform: Matrix4.identity()..rotateY(pi), alignment: Alignment.center, child: Container(decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFD4AF37), width: 4.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12, offset: const Offset(3, 6))]), child: Center(child: Container(margin: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: Colors.white24, width: 1.5), borderRadius: BorderRadius.circular(2))))));
      return Positioned(left: left, top: top, width: width, height: height, child: Transform(transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle), alignment: Alignment.center, child: Material(color: Colors.transparent, child: cardContent)));
    });
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