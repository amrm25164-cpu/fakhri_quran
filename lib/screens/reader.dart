import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../models/surah.dart';
import '../services/quran_service.dart';
import '../storage/store.dart';
import '../widgets/fonts.dart';
import '../widgets/future_view.dart';

/// Audio: verse-by-verse MP3 from cdn.islamic.network (AlQuran Cloud audio editions).
const reciters = <String, String>{
  'ar.alafasy': 'مشاري العفاسي',
  'ar.abdulbasitmurattal': 'عبد الباسط عبد الصمد (مرتل)',
  'ar.husary': 'محمود خليل الحصري',
  'ar.minshawi': 'محمد صديق المنشاوي',
};

class ReaderScreen extends StatefulWidget {
  final int surahNumber;
  final int ayah;
  const ReaderScreen({super.key, required this.surahNumber, this.ayah = 1});
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<ProcessingState>? _sub;
  late int _sn = widget.surahNumber;
  late int _target = widget.ayah;
  Surah? _cur;
  int? _playing;
  Map<int, String>? _tr;
  final Map<int, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    Store.setLastRead(_sn, _target);
    _sub = _player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) _advance();
    });
    if (Store.showTr) _loadTr();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _loadTr() async {
    try {
      final t = await QuranService.translation();
      if (mounted) setState(() => _tr = t);
    } catch (e) {
      Store.showTr = false;
      if (mounted) {
        setState(() {});
        _snack('تعذر تحميل الترجمة: $e');
      }
    }
  }

  void _advance() {
    final c = _cur;
    final p = _playing;
    if (c == null || p == null) return;
    if (p + 1 < c.ayahs.length) {
      _play(c, p + 1);
    } else {
      setState(() => _playing = null);
    }
  }

  Future<void> _play(Surah s, int idx) async {
    final a = s.ayahs[idx];
    setState(() => _playing = idx);
    Store.setLastRead(s.number, a.num);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[a.num]?.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.1, duration: const Duration(milliseconds: 250));
    });
    try {
      await _player.setUrl('https://cdn.islamic.network/quran/audio/128/${Store.reciter}/${a.global}.mp3');
      _player.play();
    } catch (_) {
      if (mounted) {
        setState(() => _playing = null);
        _snack('تعذر تشغيل الصوت. تحقق من الاتصال أو جرّب قارئًا آخر.');
      }
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    if (mounted) setState(() => _playing = null);
  }

  void _go(int n) {
    _player.stop();
    setState(() {
      _sn = n;
      _target = 1;
      _playing = null;
      _keys.clear();
    });
    Store.setLastRead(n, 1);
  }

  void _tune() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('حجم الخط'),
            Slider(
              value: Store.fontSize,
              min: 20,
              max: 48,
              onChanged: (v) {
                Store.fontSize = v;
                setSheet(() {});
                setState(() {});
              },
            ),
            const Text('تباعد الأسطر'),
            Slider(
              value: Store.lineHeight,
              min: 1.4,
              max: 3,
              onChanged: (v) {
                Store.lineHeight = v;
                setSheet(() {});
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('إظهار الترجمة الإنجليزية (Saheeh International)'),
              value: Store.showTr,
              onChanged: (v) {
                Store.showTr = v;
                setSheet(() {});
                setState(() {});
                if (v && _tr == null) _loadTr();
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _audioBar(Surah s) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${s.name} — الآية ${s.ayahs[_playing!].num} • ${reciters[Store.reciter]}',
            style: AppFonts.of('reciter', 13)),
        Row(children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (c, snap) {
              final st = snap.data;
              final busy = st?.processingState == ProcessingState.loading ||
                  st?.processingState == ProcessingState.buffering;
              if (busy) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final pl = st?.playing ?? false;
              return IconButton(
                icon: Icon(pl ? Icons.pause : Icons.play_arrow),
                onPressed: () => pl ? _player.pause() : _player.play(),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<Duration?>(
              stream: _player.durationStream,
              builder: (c, d) {
                final dur = d.data?.inMilliseconds.toDouble() ?? 0.0;
                return StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (c, p) {
                    final pos = p.data?.inMilliseconds.toDouble() ?? 0.0;
                    return Slider(
                      value: dur > 0 ? pos.clamp(0.0, dur).toDouble() : 0.0,
                      max: dur > 0 ? dur : 1.0,
                      onChanged: dur > 0 ? (v) => _player.seek(Duration(milliseconds: v.round())) : null,
                    );
                  },
                );
              },
            ),
          ),
          IconButton(icon: const Icon(Icons.stop), onPressed: _stop),
        ]),
      ]),
    );
  }

  Widget _ayahTile(Surah s, int idx) {
    final a = s.ayahs[idx];
    final key = '${s.number}:${a.num}';
    final bm = Store.isBookmarked(key);
    final isPlaying = _playing == idx;
    final cs = Theme.of(context).colorScheme;
    return Card(
      key: _keys.putIfAbsent(a.num, () => GlobalKey()),
      color: isPlaying ? cs.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CircleAvatar(radius: 14, child: Text('${a.num}', style: const TextStyle(fontSize: 12))),
            const Spacer(),
            IconButton(
              tooltip: 'إشارة مرجعية',
              icon: Icon(bm ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () => setState(() => Store.toggleBookmark(key)),
            ),
            IconButton(
              tooltip: 'نسخ',
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${a.text}\n﴾${s.name}: ${a.num}﴿'));
                _snack('تم النسخ');
              },
            ),
            IconButton(
              tooltip: 'مشاركة',
              icon: const Icon(Icons.share),
              onPressed: () => Share.share('${a.text}\n﴾${s.name}: ${a.num}﴿'),
            ),
            IconButton(
              tooltip: 'استماع',
              icon: Icon(isPlaying ? Icons.stop_circle : Icons.play_circle),
              onPressed: () => isPlaying ? _stop() : _play(s, idx),
            ),
          ]),
          Text(
            a.text,
            textAlign: TextAlign.justify,
            style: AppFonts.of('quran', Store.fontSize, h: Store.lineHeight),
          ),
          if (Store.showTr && _tr != null && _tr![a.global] != null) ...[
            const Divider(),
            Text(_tr![a.global]!,
                textDirection: TextDirection.ltr, style: AppFonts.of('translation', 15, h: 1.5)),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureView<List<Surah>>(
      scaffold: true,
      load: QuranService.load,
      builder: (c, all) {
        final s = all[_sn - 1];
        _cur = s;
        if (_target > 1) {
          final t = _target;
          _target = 1;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _keys[t]?.currentContext;
            if (ctx != null) Scrollable.ensureVisible(ctx);
          });
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(s.name, style: AppFonts.of('title', 20)),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'القارئ',
                icon: const Icon(Icons.record_voice_over),
                onSelected: (v) => setState(() => Store.reciter = v),
                itemBuilder: (_) => [
                  for (final e in reciters.entries)
                    CheckedPopupMenuItem<String>(
                        value: e.key, checked: Store.reciter == e.key, child: Text(e.value)),
                ],
              ),
              IconButton(icon: const Icon(Icons.text_fields), onPressed: _tune),
            ],
          ),
          body: ListView(
            key: ValueKey(_sn),
            padding: const EdgeInsets.all(8),
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('${s.en} • ${s.ayahs.length} آية • ${s.typeAr}'),
                ),
              ),
              for (var i = 0; i < s.ayahs.length; i++) _ayahTile(s, i),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_playing != null) _audioBar(s),
              Row(children: [
                Expanded(
                    child: TextButton(
                        onPressed: _sn > 1 ? () => _go(_sn - 1) : null, child: const Text('السورة السابقة'))),
                Expanded(
                    child: TextButton(
                        onPressed: _sn < 114 ? () => _go(_sn + 1) : null, child: const Text('السورة التالية'))),
              ]),
            ]),
          ),
        );
      },
    );
  }
}
