import 'package:flutter/material.dart';

import 'features/splash/splash_page.dart';

class TrackEApp extends StatelessWidget {
  const TrackEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackE',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}