import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/features/auth/presentation/screens/login_screen.dart';
import 'package:proyecto_movil/features/auth/stores/auth_store.dart';
import 'package:proyecto_movil/app/config/app_shell.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';

// Se pasan al compilar: flutter run --dart-define-from-file=supabase.json
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
// Clave publicable (sb_publishable_…) o la anon key heredada; ambas son
// públicas por diseño: los datos los protege el RLS.
const _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_supabaseUrl.isEmpty || _supabaseKey.isEmpty) {
    throw StateError(
      'Faltan SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY. Copia '
      'supabase.example.json a supabase.json, rellénalo y ejecuta: '
      'flutter run --dart-define-from-file=supabase.json',
    );
  }
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La sesión se guarda en el dispositivo: si sigue viva, se entra directo.
    // Se lee una vez; después navegan las pantallas de auth.
    final user = ref.read(authStoreProvider).user;
    return MaterialApp(
      title: 'LifeQuest',
      debugShowCheckedModeBanner: false,
      theme: LifeQuestTheme.light,
      darkTheme: LifeQuestTheme.dark,
      themeMode: ThemeMode.system,
      routes: {'/login': (context) => const LoginScreen()},
      home: user == null
          ? const LoginScreen()
          : LifeQuestTheme.lightOnly(AppShell(userName: user.displayName)),
    );
  }
}
