import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/net.dart';
import '../storage/store.dart';
import '../widgets/fonts.dart';
import '../widgets/future_view.dart';

/// Times come from the Aladhan API (api.aladhan.com) for the chosen city.
class PrayerTab extends StatefulWidget {
  const PrayerTab({super.key});
  @override
  State<PrayerTab> createState() => _PrayerTabState();
}

class _PrayerTabState extends State<PrayerTab> {
  static const cities = [
    ['مكة المكرمة', 'Makkah', 'Saudi Arabia'],
    ['المدينة المنورة', 'Madinah', 'Saudi Arabia'],
    ['الرياض', 'Riyadh', 'Saudi Arabia'],
    ['القاهرة', 'Cairo', 'Egypt'],
    ['دبي', 'Dubai', 'United Arab Emirates'],
    ['عمّان', 'Amman', 'Jordan'],
    ['بغداد', 'Baghdad', 'Iraq'],
    ['الدار البيضاء', 'Casablanca', 'Morocco'],
    ['إسطنبول', 'Istanbul', 'Turkey'],
    ['لندن', 'London', 'United Kingdom'],
  ];
  static const names = {
    'Fajr': 'الفجر',
    'Sunrise': 'الشروق',
    'Dhuhr': 'الظهر',
    'Asr': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء',
  };
  late int _city = Store.cityIndex.clamp(0, cities.length - 1);

  Future<Map<String, String>> _load() async {
    final c = cities[_city];
    final body = await Net.get(Uri.https('api.aladhan.com', '/v1/timingsByCity', {'city': c[1], 'country': c[2]}));
    final t = jsonDecode(body)['data']['timings'] as Map<String, dynamic>;
    return {for (final k in names.keys) k: t[k].toString()};
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButton<int>(
            isExpanded: true,
            value: _city,
            items: [for (var i = 0; i < cities.length; i++) DropdownMenuItem(value: i, child: Text(cities[i][0]))],
            onChanged: (v) {
              Store.cityIndex = v!;
              setState(() => _city = v);
            },
          ),
        ),
        Expanded(
          child: FutureView<Map<String, String>>(
            key: ValueKey(_city),
            load: _load,
            builder: (c, t) => ListView(children: [
              for (final e in names.entries)
                ListTile(
                  title: Text(e.value, style: AppFonts.of('title', 20)),
                  trailing: Text(t[e.key]!, style: const TextStyle(fontSize: 20)),
                ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('المصدر: Aladhan API. قد تختلف المواقيت قليلاً عن الجهة الرسمية في بلدك.',
                    textAlign: TextAlign.center),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
