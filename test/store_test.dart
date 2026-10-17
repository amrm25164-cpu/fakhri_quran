import 'package:flutter_test/flutter_test.dart';
import 'package:quran/services/quran_service.dart';
import 'package:quran/storage/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
  });

  test('bookmark toggle', () {
    Store.toggleBookmark('1:1');
    expect(Store.isBookmarked('1:1'), true);
    Store.toggleBookmark('1:1');
    expect(Store.isBookmarked('1:1'), false);
  });

  test('last read persists', () {
    expect(Store.lastRead, [1, 1]);
    Store.setLastRead(2, 255);
    expect(Store.lastRead, [2, 255]);
  });

  test('tasbeeh persists', () {
    Store.tasbeeh = 33;
    expect(Store.tasbeeh, 33);
  });

  test('arabic normalization strips diacritics', () {
    expect(QuranService.norm('بِسْمِ'), 'بسم');
  });
}
