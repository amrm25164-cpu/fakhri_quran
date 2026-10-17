import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/quran_service.dart';
import '../storage/store.dart';
import '../widgets/fonts.dart';
import '../widgets/future_view.dart';
import 'more_tab.dart';
import 'prayer_tab.dart';
import 'quran_tab.dart';
import 'reader.dart';
import 'studio_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: [
        HomeTab(go: (n) => setState(() => _i = n)),
        const QuranTab(),
        const StudioTab(),
        const PrayerTab(),
        const MoreTab(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (n) => setState(() => _i = n),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'القرآن'),
          NavigationDestination(icon: Icon(Icons.movie_creation_outlined), selectedIcon: Icon(Icons.movie_creation), label: 'الاستوديو'),
          NavigationDestination(icon: Icon(Icons.access_time), selectedIcon: Icon(Icons.access_time_filled), label: 'الصلاة'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'المزيد'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final ValueChanged<int> go;
  const HomeTab({super.key, required this.go});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Widget _tile(IconData icon, String label, VoidCallback onTap) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureView<List<Surah>>(
        load: QuranService.load,
        builder: (c, all) {
          final l = Store.lastRead;
          final s = all[l[0] - 1];
          const gold = Color(0xFFFFD66B);
          return ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFF053D27), Color(0xFF0B5D3B)]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('فخري القرآن', style: AppFonts.of('title', 26, c: gold, w: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('متابعة القراءة', style: AppFonts.of('title', 14, c: Colors.white70)),
                Text('${s.name} — الآية ${l[1]}', style: AppFonts.of('title', 20, c: Colors.white)),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black),
                  onPressed: () => Navigator.of(c)
                      .push(MaterialPageRoute(builder: (_) => ReaderScreen(surahNumber: l[0], ayah: l[1])))
                      .then((_) => setState(() {})),
                  child: const Text('افتح المصحف'),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                _tile(Icons.menu_book, 'فهرس السور', () => widget.go(1)),
                _tile(Icons.movie_creation, 'استوديو الفيديو', () => widget.go(2)),
                _tile(Icons.access_time, 'مواقيت الصلاة', () => widget.go(3)),
                _tile(Icons.more_horiz, 'السبحة والإعدادات', () => widget.go(4)),
              ],
            ),
          ]);
        },
      ),
    );
  }
}
