import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => message;
}

class Net {
  static Future<String> get(Uri uri) async {
    try {
      final r = await http.get(uri).timeout(const Duration(seconds: 40));
      if (r.statusCode != 200) throw AppException('تعذر جلب البيانات (HTTP ${r.statusCode})');
      return utf8.decode(r.bodyBytes);
    } on SocketException {
      throw const AppException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw const AppException('انتهت مهلة الاتصال');
    } on http.ClientException {
      throw const AppException('تعذر الاتصال بالخادم');
    }
  }
}
