import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/verse.dart';

class VerseService {
  // دالة لتحميل الأبيات من ملف JSON
  Future<List<Verse>> loadVerses() async {
    try {
      // قراءة محتوى الملف من مجلد assets
      final String response = await rootBundle.loadString('assets/data/verses.json');
      
      // تحويل النص إلى قائمة JSON
      final List<dynamic> data = json.decode(response);
      
      // تحويل كل عنصر JSON إلى كائن Verse
      return data.map((json) => Verse.fromJson(json)).toList();
    } catch (e) {
      print('خطأ في تحميل الأبيات: $e');
      return [];
    }
  }
}