import 'package:flutter/material.dart';

class ClashOfWordsApp extends StatelessWidget {
  const ClashOfWordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clash of Words',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const Scaffold(body: Center(child: Text('Clash of Words'))),
    );
  }
}
