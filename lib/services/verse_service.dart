import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/verse.dart';

class VerseService {
  Future<List<Verse>> loadVerses(String level) async {
    String path = 'assets/data/verses_beginner.json'; // الافتراضي
    
    if (level == 'intermediate') {
      path = 'assets/data/verses_intermediate.json';
    } else if (level == 'expert') {
      path = 'assets/data/verses_expert.json';
    }

    try {
      final String response = await rootBundle.loadString(path);
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Verse.fromJson(json)).toList();
    } catch (e) {
      print('خطأ في تحميل الأبيات ($path): $e');
      return [];
    }
  }
}