import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Store {
  static late SharedPreferences _p;
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  static void _bump() => changes.value++;

  static bool get dark => _p.getBool('dark') ?? false;
  static set dark(bool v) {
    _p.setBool('dark', v);
    _bump();
  }

  static double get fontSize => _p.getDouble('fs') ?? 28;
  static set fontSize(double v) {
    _p.setDouble('fs', v);
  }

  static double get lineHeight => _p.getDouble('lh') ?? 2.0;
  static set lineHeight(double v) {
    _p.setDouble('lh', v);
  }

  static bool get showTr => _p.getBool('tr') ?? false;
  static set showTr(bool v) {
    _p.setBool('tr', v);
  }

  static String get reciter => _p.getString('rec') ?? 'ar.alafasy';
  static set reciter(String v) {
    _p.setString('rec', v);
  }

  static List<String> get bookmarks => _p.getStringList('bm') ?? [];
  static bool isBookmarked(String k) => bookmarks.contains(k);
  static void toggleBookmark(String k) {
    final l = List<String>.of(bookmarks);
    l.contains(k) ? l.remove(k) : l.add(k);
    _p.setStringList('bm', l);
  }

  static List<int> get lastRead =>
      (_p.getStringList('last') ?? ['1', '1']).map(int.parse).toList();
  static void setLastRead(int surah, int ayah) {
    _p.setStringList('last', ['$surah', '$ayah']);
  }

  static int get tasbeeh => _p.getInt('tasbeeh') ?? 0;
  static set tasbeeh(int v) {
    _p.setInt('tasbeeh', v);
  }

  static List<String> get history => _p.getStringList('hist') ?? [];
  static void addHistory(String q) {
    final l = List<String>.of(history)..remove(q);
    l.insert(0, q);
    _p.setStringList('hist', l.take(10).toList());
  }

  static void clearHistory() => _p.remove('hist');

  static int get cityIndex => _p.getInt('city') ?? 0;
  static set cityIndex(int v) {
    _p.setInt('city', v);
  }

  static List<Map<String, dynamic>> get presets {
    final s = _p.getString('presets');
    if (s == null) return [];
    return (jsonDecode(s) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static set presets(List<Map<String, dynamic>> v) {
    _p.setString('presets', jsonEncode(v));
  }

  static Future<void> clearUserData() async {
    await _p.clear();
    _bump();
  }
}
