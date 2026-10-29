import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:proyecto_movil/features/auth/data/models/user_model.dart';

void main() {
  supabase.User userWith(Map<String, dynamic> metadata) => supabase.User(
    id: 'u1',
    appMetadata: const {},
    userMetadata: metadata,
    aud: 'authenticated',
    email: 'ana@correo.com',
    createdAt: '2026-10-27T00:00:00Z',
  );

  String? nameOf(Map<String, dynamic> metadata) =>
      UserModel.fromSupabase(userWith(metadata)).username;

  test('el registro con correo usa username', () {
    expect(nameOf({'username': 'Ana', 'full_name': 'Ana Pérez'}), 'Ana');
  });

  test('Google y Apple usan full_name o name', () {
    expect(nameOf({'full_name': '  Leo Gómez '}), 'Leo Gómez');
    expect(nameOf({'name': 'Sol'}), 'Sol');
  });

  test('un username en blanco pasa al siguiente; sin nombre queda null', () {
    expect(nameOf({'username': '  ', 'full_name': 'Mar Ruiz'}), 'Mar Ruiz');
    expect(nameOf({}), isNull);
  });
}
