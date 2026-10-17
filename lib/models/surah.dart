class Ayah {
  final int global;
  final int num;
  final String text;
  const Ayah(this.global, this.num, this.text);
}

class Surah {
  final int number;
  final String name;
  final String en;
  final String type;
  final List<Ayah> ayahs;
  const Surah(this.number, this.name, this.en, this.type, this.ayahs);

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
        j['number'] as int,
        j['name'] as String,
        j['englishName'] as String,
        j['revelationType'] as String,
        (j['ayahs'] as List)
            .map((a) => Ayah(a['number'] as int, a['numberInSurah'] as int, a['text'] as String))
            .toList(),
      );

  String get typeAr => type == 'Meccan' ? 'مكية' : 'مدنية';
}

class Hit {
  final Surah surah;
  final Ayah ayah;
  const Hit(this.surah, this.ayah);
}
