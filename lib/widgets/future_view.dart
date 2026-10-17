import 'package:flutter/material.dart';

class FutureView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;
  final bool scaffold;
  const FutureView({super.key, required this.load, required this.builder, this.scaffold = false});

  @override
  State<FutureView<T>> createState() => _FutureViewState<T>();
}

class _FutureViewState<T> extends State<FutureView<T>> {
  late Future<T> _f = widget.load();

  Widget _wrap(Widget w) => widget.scaffold ? Scaffold(appBar: AppBar(), body: w) : w;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _f,
      builder: (c, s) {
        if (s.connectionState != ConnectionState.done) {
          return _wrap(const Center(child: CircularProgressIndicator()));
        }
        if (s.hasError) {
          final msg = s.error.toString().startsWith('Exception') || s.error is Error
              ? 'حدث خطأ غير متوقع'
              : s.error.toString();
          return _wrap(Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 12),
                Text(msg, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => setState(() => _f = widget.load()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ]),
            ),
          ));
        }
        return widget.builder(c, s.data as T);
      },
    );
  }
}
