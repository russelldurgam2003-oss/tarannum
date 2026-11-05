import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/verse.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _generateRoomCode() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(
        4, (_) => letters.codeUnitAt(random.nextInt(letters.length))));
  }

  Future<String> createRoom() async {
    String roomCode = _generateRoomCode();
    await _db.collection('rooms').doc(roomCode).set({
      'roomCode': roomCode, 'player1Joined': true, 'player2Joined': false, 'status': 'waiting',
      'p1Score': 0, 'p2Score': 0, 'p1Won': [], 'p2Won': [],
      'p1Wrong': 0, 'p2Wrong': 0, 'p1Freeze': 0, 'p2Freeze': 0,
      'p1FrozenThisRound': false, 'p2FrozenThisRound': false,
      'lastEventId': 0, 'lastEvent': '',
    });
    return roomCode;
  }

  Future<bool> joinRoom(String roomCode) async {
    final docRef = _db.collection('rooms').doc(roomCode.toUpperCase());
    final doc = await docRef.get();
    if (doc.exists) {
      final data = doc.data()!;
      if (data['player2Joined'] == false) {
        await docRef.update({'player2Joined': true, 'status': 'playing'});
        return true;
      }
    }
    return false;
  }

  Stream<DocumentSnapshot> listenToRoom(String roomCode) {
    return _db.collection('rooms').doc(roomCode.toUpperCase()).snapshots();
  }

  Future<void> startGame(String roomCode, List<Verse> verses) async {
    final shuffled = [...verses]..shuffle();
    final selected = shuffled.take(50).toList();
    
    final p1Cards = List<Map<String, dynamic>?>.filled(25, null);
    final p2Cards = List<Map<String, dynamic>?>.filled(25, null);
    
    for (int i = 0; i < 25; i++) {
      p1Cards[i] = {'id': selected[i].id, 'sadr': selected[i].sadr, 'ajz': selected[i].ajz, 'poet': selected[i].poet, 'sea': selected[i].sea};
      p2Cards[i] = {'id': selected[i+25].id, 'sadr': selected[i+25].sadr, 'ajz': selected[i+25].ajz, 'poet': selected[i+25].poet, 'sea': selected[i+25].sea};
    }

    final currentVerse = selected[Random().nextInt(50)];

    await _db.collection('rooms').doc(roomCode).update({
      'p1Cards': p1Cards, 'p2Cards': p2Cards,
      'currentVerse': {'id': currentVerse.id, 'sadr': currentVerse.sadr, 'ajz': currentVerse.ajz, 'poet': currentVerse.poet, 'sea': currentVerse.sea},
      'isAnswered': false,
      'p1Wrong': 0, 'p2Wrong': 0, 'p1Freeze': 0, 'p2Freeze': 0,
      'p1FrozenThisRound': false, 'p2FrozenThisRound': false,
      'lastEventId': 0, 'lastEvent': '',
    });
  }

  Future<void> submitAnswer(String roomCode, String playerId, int tappedVerseId) async {
    final roomRef = _db.collection('rooms').doc(roomCode);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      if (data['isAnswered'] == true) return;

      bool myFrozen = playerId == 'p1' ? (data['p1FrozenThisRound'] ?? false) : (data['p2FrozenThisRound'] ?? false);
      if (myFrozen) return; 

      final currentVerse = data['currentVerse'];
      if (currentVerse == null) return;
      
      final isCorrect = currentVerse['id'] == tappedVerseId;

      if (isCorrect) {
        List<dynamic> p1Cards = List.from(data['p1Cards'] ?? []);
        List<dynamic> p2Cards = List.from(data['p2Cards'] ?? []);
        List<dynamic> p1Won = List.from(data['p1Won'] ?? []);
        List<dynamic> p2Won = List.from(data['p2Won'] ?? []);
        
        for (int i = 0; i < p1Cards.length; i++) { if (p1Cards[i] != null && p1Cards[i]['id'] == currentVerse['id']) p1Cards[i] = null; }
        for (int i = 0; i < p2Cards.length; i++) { if (p2Cards[i] != null && p2Cards[i]['id'] == currentVerse['id']) p2Cards[i] = null; }

        if (playerId == 'p1') { p1Won.add(currentVerse); } else { p2Won.add(currentVerse); }

        bool isP1Empty = p1Cards.every((element) => element == null);
        bool isP2Empty = p2Cards.every((element) => element == null);

        int nextP1Freeze = data['p1Freeze'] ?? 0;
        int nextP2Freeze = data['p2Freeze'] ?? 0;
        if (data['p1FrozenThisRound'] == true) nextP1Freeze = max(0, nextP1Freeze - 1);
        if (data['p2FrozenThisRound'] == true) nextP2Freeze = max(0, nextP2Freeze - 1);

        bool nextP1Frozen = nextP1Freeze > 0;
        bool nextP2Frozen = nextP2Freeze > 0;

        String eventStr = "correct|$playerId|${currentVerse['poet']}";
        int newEventId = (data['lastEventId'] ?? 0) + 1;

        if (isP1Empty && isP2Empty) {
          transaction.update(roomRef, {
            'isAnswered': true, 'status': 'finished',
            'p1Cards': p1Cards, 'p2Cards': p2Cards, 'p1Won': p1Won, 'p2Won': p2Won,
            'p1Score': (data['p1Score'] ?? 0) + (playerId == 'p1' ? 1 : 0),
            'p2Score': (data['p2Score'] ?? 0) + (playerId == 'p2' ? 1 : 0),
            'lastEventId': newEventId, 'lastEvent': eventStr,
          });
        } else {
          List<dynamic> remaining = [];
          remaining.addAll(p1Cards.where((c) => c != null));
          remaining.addAll(p2Cards.where((c) => c != null));
          final nextVerse = remaining[Random().nextInt(remaining.length)];

          transaction.update(roomRef, {
            'isAnswered': false, 'p1Cards': p1Cards, 'p2Cards': p2Cards, 'p1Won': p1Won, 'p2Won': p2Won,
            'currentVerse': nextVerse,
            'p1Score': (data['p1Score'] ?? 0) + (playerId == 'p1' ? 1 : 0),
            'p2Score': (data['p2Score'] ?? 0) + (playerId == 'p2' ? 1 : 0),
            'p1Wrong': playerId == 'p1' ? 0 : data['p1Wrong'],
            'p2Wrong': playerId == 'p2' ? 0 : data['p2Wrong'],
            'p1Freeze': nextP1Freeze, 'p2Freeze': nextP2Freeze,
            'p1FrozenThisRound': nextP1Frozen, 'p2FrozenThisRound': nextP2Frozen,
            'lastEventId': newEventId, 'lastEvent': eventStr,
          });
        }
      } else {
        final wrongField = playerId == 'p1' ? 'p1Wrong' : 'p2Wrong';
        final freezeField = playerId == 'p1' ? 'p1Freeze' : 'p2Freeze';
        
        int currentWrong = (data[wrongField] ?? 0) + 1;
        int currentFreeze = data[freezeField] ?? 0;
        
        if (currentWrong >= 3) {
          currentWrong = 0;
          currentFreeze += 1; 
          int newEventId = (data['lastEventId'] ?? 0) + 1;
          transaction.update(roomRef, { 
            wrongField: currentWrong, 
            freezeField: currentFreeze,
            'lastEventId': newEventId, 
            'lastEvent': "warning_freeze|$playerId|$currentFreeze", 
          });
        } else {
          transaction.update(roomRef, { 
            wrongField: currentWrong, 
          });
        }
      }
    });
  }
    // دالة تخطي البطاقة في حال تجمد اللاعبين
  Future<void> skipCard(String roomCode) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      if (data['isAnswered'] == true) return;

      final currentVerse = data['currentVerse'];
      if (currentVerse == null) return;

      List<dynamic> p1Cards = List.from(data['p1Cards'] ?? []);
      List<dynamic> p2Cards = List.from(data['p2Cards'] ?? []);

      // إزالة البطاقة من اللوحة (تذهب هباءً)
      for (int i = 0; i < p1Cards.length; i++) { if (p1Cards[i] != null && p1Cards[i]['id'] == currentVerse['id']) p1Cards[i] = null; }
      for (int i = 0; i < p2Cards.length; i++) { if (p2Cards[i] != null && p2Cards[i]['id'] == currentVerse['id']) p2Cards[i] = null; }

      bool isP1Empty = p1Cards.every((element) => element == null);
      bool isP2Empty = p2Cards.every((element) => element == null);

      if (isP1Empty && isP2Empty) {
        transaction.update(roomRef, {'isAnswered': true, 'status': 'finished', 'p1Cards': p1Cards, 'p2Cards': p2Cards});
      } else {
        List<dynamic> remaining = [];
        remaining.addAll(p1Cards.where((c) => c != null));
        remaining.addAll(p2Cards.where((c) => c != null));
        final nextVerse = remaining[Random().nextInt(remaining.length)];

        // تصفير التجميد واختيار بطاقة جديدة
        transaction.update(roomRef, {
          'isAnswered': false, 'p1Cards': p1Cards, 'p2Cards': p2Cards, 'currentVerse': nextVerse,
          'p1Wrong': 0, 'p2Wrong': 0, 'p1Freeze': 0, 'p2Freeze': 0,
          'p1FrozenThisRound': false, 'p2FrozenThisRound': false,
          'lastEventId': (data['lastEventId'] ?? 0) + 1, 
          'lastEvent': 'skip|system|0', // حدث تخطي
        });
      }
    });
  }
    // دالة مغادرة اللعبة في اللعب الجماعي
  Future<void> leaveGame(String roomCode, String leavingPlayerId) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    await roomRef.update({
      'status': 'finished',
      'winnerId': leavingPlayerId == 'p1' ? 'p2' : 'p1', // الطرف الآخر يفوز
      'endReason': 'leave',
    });
  }
}