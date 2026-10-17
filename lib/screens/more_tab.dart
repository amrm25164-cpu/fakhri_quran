import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/surah.dart';
import '../services/quran_service.dart';
import '../storage/store.dart';
import '../widgets/fonts.dart';
import '../widgets/future_view.dart';
import 'reader.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(children: [
        ListTile(leading: const Icon(Icons.touch_app), title: const Text('السبحة'), onTap: () => _push(context, const TasbeehScreen())),
        ListTile(leading: const Icon(Icons.bookmark), title: const Text('الإشارات المرجعية'), onTap: () => _push(context, const BookmarksScreen())),
        ListTile(leading: const Icon(Icons.settings), title: const Text('الإعدادات'), onTap: () => _push(context, const SettingsScreen())),
        ListTile(leading: const Icon(Icons.info_outline), title: const Text('حول التطبيق والمصادر'), onTap: () => _push(context, const AboutScreen())),
      ]),
    );
  }
}

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});
  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int _n = Store.tasbeeh;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('السبحة')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _n++);
              Store.tasbeeh = _n;
            },
            child: Container(
              width: 220,
              height: 220,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary),
              child: Text('$_n', style: TextStyle(fontSize: 64, color: cs.onPrimary)),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _n = 0);
              Store.tasbeeh = 0;
            },
            icon: const Icon(Icons.refresh),
            label: const Text('تصفير'),
          ),
        ]),
      ),
    );
  }
}

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});
  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureView<List<Surah>>(
      scaffold: true,
      load: QuranService.load,
      builder: (c, all) {
        final items = Store.bookmarks;
        return Scaffold(
          appBar: AppBar(title: const Text('الإشارات المرجعية')),
          body: items.isEmpty
              ? const Center(child: Text('لا توجد إشارات مرجعية بعد'))
              : ListView(children: [
                  for (final k in items)
                    Builder(builder: (_) {
                      final p = k.split(':');
                      final s = all[int.parse(p[0]) - 1];
                      final a = s.ayahs.firstWhere((x) => x.num == int.parse(p[1]));
                      return ListTile(
                        title: Text(a.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.of('quran', 20)),
                        subtitle: Text('${s.name} : ${a.num}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() => Store.toggleBookmark(k)),
                        ),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ReaderScreen(surahNumber: s.number, ayah: a.num))),
                      );
                    }),
                ]),
        );
      },
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _confirm(String msg, Future<void> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (ok == true) await action();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(children: [
        SwitchListTile(title: const Text('الوضع الداكن'), value: Store.dark, onChanged: (v) => setState(() => Store.dark = v)),
        ListTile(title: Text('حجم خط القرآن: ${Store.fontSize.round()}')),
        Slider(value: Store.fontSize, min: 20, max: 48, onChanged: (v) => setState(() => Store.fontSize = v)),
        ListTile(title: Text('تباعد الأسطر: ${Store.lineHeight.toStringAsFixed(1)}')),
        Slider(value: Store.lineHeight, min: 1.4, max: 3, onChanged: (v) => setState(() => Store.lineHeight = v)),
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          child: Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center, style: AppFonts.of('quran', Store.fontSize, h: Store.lineHeight)),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('إعادة تحميل بيانات القرآن'),
          onTap: () async {
            try {
              await QuranService.load(refresh: true);
              _snack('تم تحديث البيانات');
            } catch (e) {
              _snack('$e');
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('مسح سجل البحث'),
          onTap: () => setState(Store.clearHistory),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever),
          title: const Text('حذف بيانات المستخدم (إشارات، تقدم، إعدادات)'),
          onTap: () => _confirm('سيتم حذف كل بياناتك المحفوظة على الجهاز. متابعة؟', () async {
            await Store.clearUserData();
            if (mounted) setState(() {});
          }),
        ),
      ]),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: ListView(padding: const EdgeInsets.all(16), children: const [
        Text('فخري القرآن — الإصدار 1.0.0', style: TextStyle(fontSize: 20)),
        SizedBox(height: 12),
        Text('نص القرآن: AlQuran Cloud API (طبعة quran-uthmani)، يُحمَّل عند أول تشغيل ثم يُخزَّن محليًا.'),
        SizedBox(height: 8),
        Text('الترجمة: Saheeh International (en.sahih) من AlQuran Cloud API.'),
        SizedBox(height: 8),
        Text('الصوت: cdn.islamic.network (تلاوة آية بآية). لا يوجد تشغيل في الخلفية.'),
        SizedBox(height: 8),
        Text('مواقيت الصلاة: Aladhan API.'),
        SizedBox(height: 8),
        Text('الخط: UthmanicHafs1.ttf عند وجوده في assets/fonts، وإلا يُستخدم خط عربي بديل.'),
        SizedBox(height: 8),
        Text('استوديو الفيديو: معاينة فقط، ولا يوجد تصدير MP4 في هذه النسخة.'),
      ]),
    );
  }
}
