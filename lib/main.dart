import 'package:flutter/material.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF29B951),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F9F6),
      ),
      routes: {'/login': (context) => const LoginPage()},
      home: const LoginPage(),
    );
  }
}
