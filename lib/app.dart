import 'package:flutter/material.dart';

import 'features/home/presentation/home_screen.dart';

/// Raíz de la app: tema y pantalla inicial.
class ClashOfWordsApp extends StatelessWidget {
  /// Crea la app.
  const ClashOfWordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clash of Words',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
