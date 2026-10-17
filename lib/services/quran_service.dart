import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/surah.dart';
import 'net.dart';

/// Quran text: AlQuran Cloud API, edition "quran-uthmani".
/// Translation: edition "en.sahih" (Saheeh International).
/// Downloaded once, then cached in the app documents directory.
class QuranService {
  static const _base = 'https://api.alquran.cloud/v1/quran/';
  static List<Surah>? _surahs;
  static Map<int, String>? _tr;
  static Future<List<Surah>>? _inflight;

  static List<dynamic> _decode(String body) => (jsonDecode(body)['data']['surahs'] as List);

  static Future<List<dynamic>> _raw(String edition, bool refresh) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/$edition.json');
    if (!refresh && await f.exists()) {
      try {
        return _decode(await f.readAsString());
      } catch (_) {
        // corrupt cache: fall through and download again
      }
    }
    final body = await Net.get(Uri.parse('$_base$edition'));
    final list = _decode(body);
    await f.writeAsString(body);
    return list;
  }

  static Future<List<Surah>> load({bool refresh = false}) {
    if (_surahs != null && !refresh) return Future.value(_surahs!);
    return _inflight ??= _loadReal(refresh).whenComplete(() => _inflight = null);
  }

  static Future<List<Surah>> _loadReal(bool refresh) async {
    final raw = await _raw('quran-uthmani', refresh);
    _surahs = raw.map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
    return _surahs!;
  }

  static Future<Map<int, String>> translation({bool refresh = false}) async {
    if (_tr != null && !refresh) return _tr!;
    final raw = await _raw('en.sahih', refresh);
    final m = <int, String>{};
    for (final s in raw) {
      for (final a in (s['ayahs'] as List)) {
        m[a['number'] as int] = a['text'] as String;
      }
    }
    return _tr = m;
  }

  static String norm(String s) => s
      .replaceAll(RegExp('[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '')
      .replaceAll(RegExp('[إأآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .toLowerCase();

  static List<Hit> searchVerses(List<Surah> all, String q, {int limit = 50}) {
    final nq = norm(q.trim());
    if (nq.length < 2) return [];
    final out = <Hit>[];
    for (final s in all) {
      for (final a in s.ayahs) {
        if (norm(a.text).contains(nq)) {
          out.add(Hit(s, a));
          if (out.length >= limit) return out;
        }
      }
    }
    return out;
  }
}
