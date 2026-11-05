import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/candidature_repository.dart';
import 'data/repository_native.dart'
    if (dart.library.js_interop) 'data/repository_web.dart';
import 'state/candidature_controller.dart';
import 'ui/accueil_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PisteApp(repository: creerRepository()));
}

class PisteApp extends StatefulWidget {
  const PisteApp({super.key, required this.repository});
  final CandidatureRepository repository;

  @override
  State<PisteApp> createState() => _PisteAppState();
}

class _PisteAppState extends State<PisteApp> {
  late final CandidatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CandidatureController(widget.repository);
    unawaited(_controller.charger());
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(widget.repository.fermer());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Piste',
    debugShowCheckedModeBanner: false,
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007F86),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F8FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F8FB),
        foregroundColor: Color(0xFF173345),
        centerTitle: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    home: AccueilPage(controller: _controller),
  );
}
