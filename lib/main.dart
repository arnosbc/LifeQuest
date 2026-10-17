import 'package:flutter/material.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'shared/lifequest_widgets.dart';

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
      theme: LifeQuestTheme.light,
      darkTheme: LifeQuestTheme.dark,
      themeMode: ThemeMode.system,
      routes: {'/login': (context) => const LoginPage()},
      home: const LoginPage(),
    );
  }
}
