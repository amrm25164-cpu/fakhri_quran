import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/quran_service.dart';
import '../storage/store.dart';
import '../widgets/fonts.dart';
import '../widgets/future_view.dart';
import 'reader.dart';

class QuranTab extends StatefulWidget {
  const QuranTab({super.key});
  @override
  State<QuranTab> createState() => _QuranTabState();
}

class _QuranTabState extends State<QuranTab> {
  final _c = TextEditingController();
  String _q = '';
  List<Hit> _hits = [];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _open(int s, [int a = 1]) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(surahNumber: s, ayah: a)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureView<List<Surah>>(
        load: QuranService.load,
        builder: (c, all) {
          final nq = QuranService.norm(_q.trim());
          final list = nq.isEmpty
              ? all
              : all
                  .where((s) =>
                      QuranService.norm(s.name).contains(nq) ||
                      s.en.toLowerCase().contains(nq) ||
                      '${s.number}' == nq)
                  .toList();
          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _c,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم السورة أو بنص الآية',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _q.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            _c.clear();
                            _q = '';
                            _hits = [];
                          }),
                        ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (v) => setState(() {
                  _q = v;
                  _hits = [];
                }),
                onSubmitted: (v) {
                  if (v.trim().isEmpty) return;
                  Store.addHistory(v.trim());
                  setState(() => _hits = QuranService.searchVerses(all, v));
                },
              ),
            ),
            if (_q.isEmpty && Store.history.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final h in Store.history)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ActionChip(
                          label: Text(h),
                          onPressed: () => setState(() {
                            _c.text = h;
                            _q = h;
                            _hits = QuranService.searchVerses(all, h);
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(children: [
                for (final s in list)
                  ListTile(
                    leading: CircleAvatar(child: Text('${s.number}')),
                    title: Text(s.name, style: AppFonts.of('title', 20)),
                    subtitle: Text('${s.en} • ${s.ayahs.length} آية • ${s.typeAr}'),
                    onTap: () => _open(s.number),
                  ),
                if (_hits.isNotEmpty) ...[
                  const Divider(),
                  const Padding(padding: EdgeInsets.all(12), child: Text('نتائج البحث في الآيات')),
                  for (final h in _hits)
                    ListTile(
                      title: Text(h.ayah.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.of('quran', 20)),
                      subtitle: Text('${h.surah.name} : ${h.ayah.num}'),
                      onTap: () => _open(h.surah.number, h.ayah.num),
                    ),
                ] else if (_q.trim().length >= 2)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('اضغط زر البحث في لوحة المفاتيح للبحث في نص الآيات', textAlign: TextAlign.center),
                  ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}
