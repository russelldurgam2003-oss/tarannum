import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/verse.dart';
import '../services/verse_service.dart';
import '../widgets/parchment_dialog.dart';

class GameScreen extends StatefulWidget {
  final String level; // <--- إضافة هذا السطر
  const GameScreen({super.key, required this.level}); // <--- تعديل الـ constructor

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final VerseService _verseService = VerseService();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  List<Verse?> _playerCards = List<Verse?>.filled(25, null);
  List<Verse?> _aiCards = List<Verse?>.filled(25, null);

  List<Verse> _allRemainingCards = [];
  List<Verse> _playerWonCards = [];
  List<Verse> _aiWonCards = [];
  Verse? _currentVerse;

  bool _isLoading = true;
  bool _isAnswered = false;

  int _wrongAttempts = 0;
  final Set<int> _wrongTappedIds = {};
  int _freezeCycleCount = 0;
  int _freezeRoundsRemaining = 0;
  bool _isPlayerFrozen = false;

  int? _correctRevealedVerseId;

  Timer? _aiTimer;

  final GlobalKey _playerWonKey = GlobalKey();
  final GlobalKey _aiWonKey = GlobalKey();
  final Map<int, GlobalKey> _cardKeys = {};

  final TransformationController _transformController =
      TransformationController();

  bool _hasSetInitialZoom = false;
  Size _lastViewportSize = Size.zero;
  double _currentScale = 1.0;
  double _fitScale = 1.0;

  static const double _boardWidth = 1800;
  static const double _boardHeight = 1200;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    _loadVerses();
  }

  void _onTransformChanged() {
    final newScale = _transformController.value.getMaxScaleOnAxis();
    if ((newScale - _currentScale).abs() > 0.01) {
      setState(() => _currentScale = newScale);
    }
  }

  void _playSound(String assetPath) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print('خطأ في تشغيل الصوت: $e');
    }
  }

  Future<void> _loadVerses() async {
     final verses = await _verseService.loadVerses(widget.level); 
    setState(() => _isLoading = false);
    _startGame(verses);
  }

  void _startGame(List<Verse> verses) {
    if (verses.isEmpty) return;
    final shuffled = [...verses]..shuffle();
    final selected = shuffled.take(50).toList();

    setState(() {
      _playerWonCards = [];
      _aiWonCards = [];
      _cardKeys.clear();
      _wrongTappedIds.clear();
      _wrongAttempts = 0;
      _freezeCycleCount = 0;
      _freezeRoundsRemaining = 0;
      _isPlayerFrozen = false;
      _correctRevealedVerseId = null;
      _allRemainingCards = List.from(selected);

      _playerCards = List<Verse?>.filled(25, null);
      _aiCards = List<Verse?>.filled(25, null);
      for (int i = 0; i < 25; i++) {
        _playerCards[i] = selected[i];
        _aiCards[i] = selected[i + 25];
      }
      _hasSetInitialZoom = false;
    });

    _nextRound();
  }

  void _fitToScreen(Size viewportSize) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;
    final scaleX = viewportSize.width / _boardWidth;
    final scaleY = viewportSize.height / _boardHeight;
    final scale = min(scaleX, scaleY) * 0.98;
    final dx = (viewportSize.width - _boardWidth * scale) / 2;
    final dy = (viewportSize.height - _boardHeight * scale) / 2;
    _fitScale = scale;
    _transformController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  void _resetZoom() => _fitToScreen(_lastViewportSize);

  void _zoomIn() {
    final current = _transformController.value.getMaxScaleOnAxis();
    final newScale = (current * 1.3).clamp(0.2, 5.0);
    final viewportCenter = Offset(_lastViewportSize.width / 2, _lastViewportSize.height / 2);
    final scenePoint = _transformController.toScene(viewportCenter);
    _transformController.value = Matrix4.identity()
      ..translate(viewportCenter.dx - scenePoint.dx * newScale, viewportCenter.dy - scenePoint.dy * newScale)
      ..scale(newScale);
  }

  void _zoomOut() {
    final current = _transformController.value.getMaxScaleOnAxis();
    final newScale = (current / 1.3).clamp(0.2, 5.0);
    final viewportCenter = Offset(_lastViewportSize.width / 2, _lastViewportSize.height / 2);
    final scenePoint = _transformController.toScene(viewportCenter);
    _transformController.value = Matrix4.identity()
      ..translate(viewportCenter.dx - scenePoint.dx * newScale, viewportCenter.dy - scenePoint.dy * newScale)
      ..scale(newScale);
  }

  void _nextRound() {
    if (_allRemainingCards.isEmpty) {
      _endGame();
      return;
    }

    final isFrozenThisRound = _freezeRoundsRemaining > 0;
    if (isFrozenThisRound) _freezeRoundsRemaining--;
    if (_freezeRoundsRemaining == 0) _freezeCycleCount = 0;

    setState(() {
      _isAnswered = false;
      _wrongTappedIds.clear();
      _correctRevealedVerseId = null;
      _isPlayerFrozen = isFrozenThisRound;
    });

    final random = Random();
    _currentVerse = _allRemainingCards[random.nextInt(_allRemainingCards.length)];

    if (_isPlayerFrozen) {
      final remainingAfterThis = _freezeRoundsRemaining;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final msg = remainingAfterThis > 0
              ? '🚫 مجمّد! يتبقى $remainingAfterThis ${remainingAfterThis == 1 ? "جولة" : "جولات"} بعد هذه'
              : '🚫 مجمّد لهذه الجولة بسبب 3 أخطاء!';
          _showNotification(msg, Colors.red);
        }
      });
      _aiTimer?.cancel();
      _aiTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isAnswered) _handleAiAnswer();
      });
    } else {
      _scheduleAiAnswer();
    }
  }

  void _scheduleAiAnswer() {
    _aiTimer?.cancel();
    final delay = Duration(seconds: 20 + Random().nextInt(11));
    _aiTimer = Timer(delay, () {
      if (!mounted || _isAnswered) return;
      _handleAiAnswer();
    });
  }

  void _handleAiAnswer() {
    if (_isAnswered) return;
    _aiTimer?.cancel();
    _playSound('audio/correct.mp3');

    setState(() {
      _isAnswered = true;
      _correctRevealedVerseId = _currentVerse!.id;
    });

    _showNotification('قال الشاعر: ${_currentVerse!.poet}', Colors.teal);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _flyCard(_currentVerse!, toPlayer: false);
    });
  }

  void _checkAnswer(Verse tappedVerse) {
    if (_isAnswered || _isPlayerFrozen) return;

    final isCorrect = tappedVerse.id == _currentVerse!.id;

    if (isCorrect) {
      _aiTimer?.cancel();
      _playSound('audio/correct.mp3');
      setState(() {
        _isAnswered = true;
        _correctRevealedVerseId = tappedVerse.id;
      });

      _showNotification('أحسنت! قال الشاعر: ${_currentVerse!.poet}', Colors.green);

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _flyCard(tappedVerse, toPlayer: true);
      });
    } else {
      _playSound('audio/wrong.mp3');
      setState(() {
        _wrongAttempts++;
        _wrongTappedIds.add(tappedVerse.id);
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _wrongTappedIds.remove(tappedVerse.id));
        }
      });

      if (_wrongAttempts >= 3) {
        setState(() {
          _wrongAttempts = 0;
          _freezeCycleCount++;
          _freezeRoundsRemaining = _freezeCycleCount;
        });
        final rounds = _freezeCycleCount;
        if (mounted) {
          _showNotification('⚠️ 3 أخطاء! ستُجمّد $rounds ${rounds == 1 ? "جولة" : "جولات"}', Colors.orange);
        }
      }
    }
  }

  void _showNotification(String message, Color color) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 40,
        left: 20,
        right: 20,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  void _nullifyCard(int verseId) {
    for (int i = 0; i < _playerCards.length; i++) {
      if (_playerCards[i]?.id == verseId) _playerCards[i] = null;
    }
    for (int i = 0; i < _aiCards.length; i++) {
      if (_aiCards[i]?.id == verseId) _aiCards[i] = null;
    }
  }

  void _flyCard(Verse verse, {required bool toPlayer}) {
    _playSound('audio/swipe.mp3');

    final sourceKey = _cardKeys[verse.id];
    final sourceBox = sourceKey?.currentContext?.findRenderObject() as RenderBox?;
    final targetKey = toPlayer ? _playerWonKey : _aiWonKey;
    final targetBox = targetKey.currentContext?.findRenderObject() as RenderBox?;

    Offset? sourcePos = sourceBox?.localToGlobal(Offset.zero);
    Size? sourceSize = sourceBox?.size;
    Offset? targetPos = targetBox?.localToGlobal(Offset.zero);
    Size? targetSize = targetBox?.size;

    setState(() {
      _allRemainingCards.removeWhere((v) => v.id == verse.id);
      _nullifyCard(verse.id);
      _correctRevealedVerseId = null;
    });

    if (sourcePos == null || sourceSize == null || targetPos == null || targetSize == null) {
      setState(() {
        if (toPlayer) { _playerWonCards.add(verse); } else { _aiWonCards.add(verse); }
      });
      _scheduleNextRound();
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyingCard(
        startPos: sourcePos!,
        endPos: targetPos!,
        startSize: sourceSize!,
        endSize: targetSize!,
        verse: verse,
        onComplete: () {
          entry.remove();
          if (mounted) {
            setState(() {
              if (toPlayer) { _playerWonCards.add(verse); } else { _aiWonCards.add(verse); }
            });
            _scheduleNextRound();
          }
        },
      ),
    );
    overlay.insert(entry);
  }

  void _scheduleNextRound() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _nextRound();
    });
  }

    void _endGame() {
    _aiTimer?.cancel();
    final playerCount = _playerWonCards.length;
    final aiCount = _aiWonCards.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ParchmentDialog(
        title: 'انتهت اللعبة',
        content: Column(
          children: [
            Text('مكتسباتك: $playerCount بطاقة', style: const TextStyle(fontSize: 22, fontFamily: 'Amiri', color: Color(0xFF2C1810))),
            const SizedBox(height: 8),
            Text('مكتسبات الخصم: $aiCount بطاقة', style: const TextStyle(fontSize: 22, fontFamily: 'Amiri', color: Color(0xFF2C1810))),
            const SizedBox(height: 20),
            Text(
              playerCount > aiCount ? '🎉 مبروك! لقد فزت!' : playerCount < aiCount ? '😢 للأسف، خسرت.' : '🤝 تعادل!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Amiri', color: Colors.brown),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('العودة للقائمة', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: Colors.brown, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () { Navigator.pop(context); _loadVerses(); },
            child: const Text('العب مرة أخرى', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: Colors.brown, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    _sfxPlayer.dispose();
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
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
                  if (!_hasSetInitialZoom && size.width > 0 && size.height > 0) {
                    _hasSetInitialZoom = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _fitToScreen(size);
                    });
                  }
                  return _buildWoodenFloor();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: const Color(0xFF1A0D08),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _wrongAttempts > 0 ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _wrongAttempts > 0 ? Colors.redAccent : Colors.white30, width: 1.5),
            ),
            child: Row(
              children: [
                const Text('الأخطاء: ', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Amiri')),
                Text('$_wrongAttempts / 3', style: TextStyle(color: _wrongAttempts > 0 ? Colors.redAccent : Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'ترنم',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isPlayerFrozen ? Colors.red.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _isPlayerFrozen ? Colors.redAccent : Colors.transparent, width: 1.5),
            ),
            child: Text(
              _isPlayerFrozen ? 'مجمّد 🚫' : '',
              style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSadrBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1810),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Text(
        _currentVerse?.sadr ?? '',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          height: 1.3,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }

  Widget _buildWonPilesBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF1A0D08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildWonPile(_playerWonKey, _playerWonCards, 'مكتسباتك', Colors.lightBlueAccent),
          _buildWonPile(_aiWonKey, _aiWonCards, 'مكتسبات الخصم', Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildWonPile(GlobalKey key, List<Verse> cards, String label, Color color) {
    return Row(
      children: [
        Text(
          '$label: ${cards.length}',
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
        ),
        const SizedBox(width: 8),
        Container(
          key: key,
          width: 40,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.7), width: 2),
          ),
          child: Stack(
            children: [
              for (int i = 0; i < cards.length && i < 4; i++)
                Positioned(
                  left: 2.0 + i * 1.0,
                  top: 2.0 + i * 1.0,
                  right: 2.0,
                  bottom: 2.0 + (4 - i) * 1.8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32), // Green back
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1.0), // Gold border
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWoodenFloor() {
    final isPanEnabled = _currentScale > _fitScale * 1.05;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/wood_bg.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black38,
            BlendMode.darken,
          ),
        ),
        color: Color(0xFF3E2723), 
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.2,
              maxScale: 5.0,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(600),
              panEnabled: isPanEnabled,
              scaleEnabled: true,
              child: SizedBox(
                width: _boardWidth,
                height: _boardHeight,
                child: Container(
                  margin: const EdgeInsets.all(30),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0D47A1), width: 8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        spreadRadius: 5,
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildCardZone(_playerCards)),
                      Container(
                        width: 40,
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Expanded(child: _buildCardZone(_aiCards)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(bottom: 12, left: 12, child: _buildZoomControls()),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(isPanEnabled ? Icons.pan_tool : Icons.pinch, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    isPanEnabled ? 'اسحب للتنقل' : 'اسحب بإصبعين للتكبير',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Amiri'),
                  ),
                ],
              ),
            ),
          ),
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
          _zoomButton(Icons.zoom_out, _zoomOut),
          Container(width: 1, height: 24, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 4)),
          _zoomButton(Icons.zoom_in, _zoomIn),
          Container(width: 1, height: 24, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 4)),
          _zoomButton(Icons.center_focus_strong, _resetZoom),
        ],
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: Colors.white, size: 22)),
    );
  }

  Widget _buildCardZone(List<Verse?> cards) {
    final columns = <List<Verse?>>[[], [], [], [], []];
    for (int i = 0; i < cards.length; i++) {
      columns[i % 5].add(cards[i]);
    }

    return Row(
      children: [
        for (int colIdx = 0; colIdx < 5; colIdx++)
          Expanded(
            child: Column(
              children: [
                for (final verse in columns[colIdx])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: verse == null ? const SizedBox.shrink() : _buildKarutaCard(verse),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildKarutaCard(Verse verse) {
    final isCorrectRevealed = _correctRevealedVerseId == verse.id;
    final isWrongTapped = _wrongTappedIds.contains(verse.id);

    Color bgColor = const Color(0xFFFDFBF5);
    Color borderColor = const Color(0xFF2E7D32);

    if (isCorrectRevealed) {
      bgColor = const Color(0xFFC8E6C9);
      borderColor = Colors.green;
    } else if (isWrongTapped) {
      bgColor = const Color(0xFFFFCDD2);
      borderColor = Colors.red;
    }

    final key = _cardKeys.putIfAbsent(verse.id, () => GlobalKey());

    return GestureDetector(
      onTap: (_isAnswered || _isPlayerFrozen) ? null : () => _checkAnswer(verse),
      child: Container(
        key: key,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 4.0), // إطار أخضر أثخن
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4), // ظل أقوى وأوضح
              blurRadius: 6,                      // تنعيم الظل
              offset: const Offset(2, 4),         // إزاحة الظل للأسفل
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Center(
          child: Text(
            verse.ajz,
            textAlign: TextAlign.center,
            softWrap: true,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Amiri',
            ),
          ),
        ),
      ),
    );
  }
}

// ====== ودجت البطاقة الطائرة (مع حركة القلب) ======
class _FlyingCard extends StatefulWidget {
  final Offset startPos;
  final Offset endPos;
  final Size startSize;
  final Size endSize;
  final Verse verse;
  final VoidCallback onComplete;

  const _FlyingCard({
    required this.startPos,
    required this.endPos,
    required this.startSize,
    required this.endSize,
    required this.verse,
    required this.onComplete,
  });

  @override
  State<_FlyingCard> createState() => _FlyingCardState();
}

class _FlyingCardState extends State<_FlyingCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _controller.forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final left = widget.startPos.dx + (widget.endPos.dx - widget.startPos.dx) * t;
        final top = widget.startPos.dy + (widget.endPos.dy - widget.startPos.dy) * t;
        final width = widget.startSize.width + (widget.endSize.width - widget.startSize.width) * t;
        final height = widget.startSize.height + (widget.endSize.height - widget.startSize.height) * t;

        // زاوية الدوران (من 0 إلى 180 درجة)
        final angle = t * pi; 
        // هل نحن في النصف الأول (الوجه) أم الثاني (الظهر)؟
        final isFront = angle < (pi / 2);

        // محتوى البطاقة (وجه أو ظهر)
        Widget cardContent = isFront
            ? Container(
                // وجه البطاقة (أبيض بالنص)
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2E7D32), width: 4.0),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12, offset: const Offset(3, 6)),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        widget.verse.ajz,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: Color(0xFF1A1A1A),
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : Transform(
                // ظهر البطاقة (أخضر)
                // نعكسها أفقياً حتى لا تظهر معكوسة أثناء الدوران
                transform: Matrix4.identity()..rotateY(pi),
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32), // لون أخضر
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 4.0), // إطار ذهبي
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12, offset: const Offset(3, 6)),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24, width: 1.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              );

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          // تطبيق منظور ثلاثي الأبعاد (Perspective) لتبدو الحركة واقعية
          child: Transform(
            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
            alignment: Alignment.center,
            child: Material(
              color: Colors.transparent,
              child: cardContent,
            ),
          ),
        );
      },
    );
  }
}