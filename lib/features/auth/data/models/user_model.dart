import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:proyecto_movil/features/auth/domain/entities/user.dart';

/// Usuario tal como llega de Supabase Auth (`auth.users`).
class UserModel {
  const UserModel({required this.id, required this.email, this.username});

  factory UserModel.fromSupabase(supabase.User user) {
    String? username;
    for (final key in const ['username', 'full_name', 'name']) {
      final value = user.userMetadata?[key];
      if (value is String && value.trim().isNotEmpty) {
        username = value.trim();
        break;
      }
    }
    return UserModel(id: user.id, email: user.email ?? '', username: username);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String? ?? '',
    username: json['username'] as String?,
  );

  final String id;
  final String email;
  final String? username;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
  };

  User toEntity() => User(id: id, email: email, username: username);
}
