import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_shell.dart';
import 'storage/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const FakhriApp());
}

class FakhriApp extends StatelessWidget {
  const FakhriApp({super.key});

  ThemeData _theme(Brightness b) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B5D3B),
          secondary: const Color(0xFFC9A227),
          brightness: b,
        ),
        fontFamilyFallback: const ['Noto Naskh Arabic', 'Amiri', 'Roboto'],
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Store.changes,
      builder: (context, _, child) => MaterialApp(
        title: 'Fakhri Quran',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: Store.dark ? ThemeMode.dark : ThemeMode.light,
        home: const HomeShell(),
      ),
    );
  }
}