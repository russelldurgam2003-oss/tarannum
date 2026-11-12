import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- هنا المكان الصحيح للاستيراد

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance; // <--- تم نقل هذا المتغير هنا
  bool _isGoogleSignInInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!kIsWeb && !_isGoogleSignInInitialized) {
      await GoogleSignIn.instance.initialize();
      _isGoogleSignInInitialized = true;
    }
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } else {
        await _ensureInitialized();
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate(
          scopeHint: ['email', 'profile'],
        );
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final String? idToken = googleAuth.idToken;
        if (idToken == null) {
          print('خطأ: لم يتم الحصول على idToken');
          return null;
        }
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: null, 
        );
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      print('خطأ في تسجيل الدخول: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  // دوال حفظ واسترجاع بروفايل اللاعب
  Future<void> saveUserProfile(String uid, String name, String avatarPath) async {
    await _db.collection('users').doc(uid).set({
      'displayName': name,
      'avatarPath': avatarPath,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
    // دالة لتحديث الإحصائيات
  Future<void> updateStats(String uid, {
    bool? spWin, bool? spLoss, 
    bool? mpWin, bool? mpLoss, 
    String? opponentName
  }) async {
    Map<String, dynamic> updates = {};
    
    if (spWin == true) updates['spWins'] = FieldValue.increment(1);
    if (spLoss == true) updates['spLosses'] = FieldValue.increment(1);
    
    if (mpWin == true) {
      updates['mpWins'] = FieldValue.increment(1);
      updates['mpHistory'] = FieldValue.arrayUnion(['فوز ضد $opponentName']);
    }
    if (mpLoss == true) {
      updates['mpLosses'] = FieldValue.increment(1);
      updates['mpHistory'] = FieldValue.arrayUnion(['خسارة ضد $opponentName']);
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).set(updates, SetOptions(merge: true));
    }
  }
}