import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/quran_service.dart';
import '../storage/store.dart';
import '../widgets/fonts.dart';
import '../widgets/future_view.dart';

/// Video design PREVIEW. MP4 export is not implemented in this build.
class StudioTab extends StatefulWidget {
  const StudioTab({super.key});
  @override
  State<StudioTab> createState() => _StudioTabState();
}

class _StudioTabState extends State<StudioTab> with SingleTickerProviderStateMixin {
  static const fgs = [Colors.white, Color(0xFFFFD66B), Color(0xFF111111)];
  static const bgs = [
    [Color(0xFF053D27), Color(0xFF0B5D3B)],
    [Color(0xFF111827), Color(0xFF1F2937)],
    [Color(0xFF3B2A0A), Color(0xFFC9A227)],
  ];

  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  late final Animation<double> _op = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
  ]).animate(_ac);

  final _textC = TextEditingController();
  final _trC = TextEditingController();
  final _recC = TextEditingController();
  List<Surah> _all = [];
  bool _init = false;
  int _sn = 1, _from = 1, _to = 1;
  double _ratio = 9 / 16, _size = 30, _secs = 6, _lh = 1.9;
  int _fg = 0, _bg = 0;
  bool _ref = true, _showTr = false;

  @override
  void dispose() {
    _ac.dispose();
    _textC.dispose();
    _trC.dispose();
    _recC.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _applyText() {
    final s = _all[_sn - 1];
    final sel = s.ayahs.where((a) => a.num >= _from && a.num <= _to).toList();
    _textC.text = sel.map((a) => a.text).join(' ');
    _fillTr();
  }

  Future<void> _fillTr() async {
    if (!_showTr) return;
    try {
      final t = await QuranService.translation();
      final s = _all[_sn - 1];
      _trC.text = s.ayahs
          .where((a) => a.num >= _from && a.num <= _to)
          .map((a) => t[a.global] ?? '')
          .join(' ');
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _showTr = false);
        _snack('تعذر تحميل الترجمة: $e');
      }
    }
  }

  void _play() {
    _ac.duration = Duration(milliseconds: (_secs * 1000).round());
    _ac.forward(from: 0);
  }

  void _savePreset() {
    final l = Store.presets;
    l.add({'name': 'نمط ${l.length + 1}', 'size': _size, 'fg': _fg, 'bg': _bg, 'ratio': _ratio, 'secs': _secs, 'ref': _ref, 'lh': _lh});
    Store.presets = l;
    _snack('تم حفظ النمط');
  }

  Future<void> _loadPreset() async {
    final l = Store.presets;
    final p = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('الأنماط المحفوظة'),
        children: l.isEmpty
            ? [const Padding(padding: EdgeInsets.all(16), child: Text('لا توجد أنماط محفوظة'))]
            : [
                for (final p in l)
                  SimpleDialogOption(onPressed: () => Navigator.pop(c, p), child: Text(p['name'] as String)),
              ],
      ),
    );
    if (p == null || !mounted) return;
    setState(() {
      _size = (p['size'] as num).toDouble();
      _fg = p['fg'] as int;
      _bg = p['bg'] as int;
      _ratio = (p['ratio'] as num).toDouble();
      _secs = (p['secs'] as num).toDouble();
      _ref = p['ref'] as bool;
      _lh = (p['lh'] as num).toDouble();
    });
  }

  Widget _preview(Surah s) {
    final fg = fgs[_fg];
    final refText = _from == _to ? '${s.name} • $_from' : '${s.name} • $_from-$_to';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: AspectRatio(
          aspectRatio: _ratio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: bgs[_bg]),
              ),
              child: LayoutBuilder(
                builder: (c, box) => AnimatedBuilder(
                  animation: _ac,
                  builder: (c, _) {
                    final o = _ac.status == AnimationStatus.forward ? _op.value : 1.0;
                    return Opacity(
                      opacity: o,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: box.maxWidth),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              if (_ref) Text(refText, style: AppFonts.of('title', _size * 0.6, c: fgs[1])),
                              Text(_textC.text,
                                  textAlign: TextAlign.center, style: AppFonts.of('quran', _size, h: _lh, c: fg)),
                              if (_showTr && _trC.text.isNotEmpty)
                                Text(_trC.text,
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.center,
                                    style: AppFonts.of('translation', _size * 0.5, c: fg)),
                              if (_recC.text.isNotEmpty)
                                Text(_recC.text, style: AppFonts.of('reciter', _size * 0.5, c: fg)),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureView<List<Surah>>(
        load: QuranService.load,
        builder: (c, all) {
          _all = all;
          if (!_init) {
            _init = true;
            _applyText();
          }
          final s = all[_sn - 1];
          return ListView(padding: const EdgeInsets.all(12), children: [
            _preview(s),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: _play, icon: const Icon(Icons.play_arrow), label: const Text('معاينة'))),
              const SizedBox(width: 8),
              IconButton(onPressed: _savePreset, icon: const Icon(Icons.save), tooltip: 'حفظ النمط'),
              IconButton(onPressed: _loadPreset, icon: const Icon(Icons.folder_open), tooltip: 'تحميل نمط'),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _sn,
                  items: [for (final x in all) DropdownMenuItem(value: x.number, child: Text('${x.number}. ${x.name}'))],
                  onChanged: (v) => setState(() {
                    _sn = v!;
                    _from = 1;
                    _to = 1;
                    _applyText();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _from,
                items: [for (var i = 1; i <= s.ayahs.length; i++) DropdownMenuItem(value: i, child: Text('من $i'))],
                onChanged: (v) => setState(() {
                  _from = v!;
                  if (_to < _from) _to = _from;
                  _applyText();
                }),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _to,
                items: [for (var i = _from; i <= s.ayahs.length; i++) DropdownMenuItem(value: i, child: Text('إلى $i'))],
                onChanged: (v) => setState(() {
                  _to = v!;
                  _applyText();
                }),
              ),
            ]),
            TextField(
              controller: _textC,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'نص الآية (تعديل للتصميم فقط)', border: OutlineInputBorder()),
              style: AppFonts.of('quran', 20),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _recC,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'اسم القارئ (اختياري)', border: OutlineInputBorder()),
            ),
            SwitchListTile(
              title: const Text('إظهار الترجمة'),
              value: _showTr,
              onChanged: (v) {
                setState(() => _showTr = v);
                if (v) {
                  _fillTr();
                } else {
                  _trC.clear();
                }
              },
            ),
            if (_showTr)
              TextField(
                controller: _trC,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'الترجمة (قابلة للتعديل)', border: OutlineInputBorder()),
              ),
            SwitchListTile(title: const Text('إظهار اسم السورة ورقم الآية'), value: _ref, onChanged: (v) => setState(() => _ref = v)),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 9 / 16, label: Text('9:16')),
                ButtonSegment(value: 1.0, label: Text('1:1')),
                ButtonSegment(value: 16 / 9, label: Text('16:9')),
              ],
              selected: {_ratio},
              onSelectionChanged: (v) => setState(() => _ratio = v.first),
            ),
            const Text('حجم الخط'),
            Slider(value: _size, min: 16, max: 60, onChanged: (v) => setState(() => _size = v)),
            const Text('تباعد الأسطر'),
            Slider(value: _lh, min: 1.2, max: 2.8, onChanged: (v) => setState(() => _lh = v)),
            Text('مدة الحركة: ${_secs.toStringAsFixed(1)} ثانية (ظهور تدريجي ثم اختفاء)'),
            Slider(value: _secs, min: 2, max: 12, onChanged: (v) => setState(() => _secs = v)),
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Text('لون النص'),
              for (var i = 0; i < fgs.length; i++)
                ChoiceChip(
                  label: Text('${i + 1}'),
                  avatar: CircleAvatar(backgroundColor: fgs[i], radius: 8),
                  selected: _fg == i,
                  onSelected: (_) => setState(() => _fg = i),
                ),
            ]),
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Text('الخلفية'),
              for (var i = 0; i < bgs.length; i++)
                ChoiceChip(
                  label: Text('تدرج ${i + 1}'),
                  selected: _bg == i,
                  onSelected: (_) => setState(() => _bg = i),
                ),
            ]),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _snack('تصدير MP4 غير متوفر في هذه النسخة؛ هذه الشاشة معاينة للتصميم فقط.'),
              icon: const Icon(Icons.movie),
              label: const Text('تصدير فيديو (غير متوفر)'),
            ),
          ]);
        },
      ),
    );
  }
}
