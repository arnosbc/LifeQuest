import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/profile/data/models/character_profile_model.dart';

/// Perfil en Supabase. Lanza [ServerException] o [NetworkException].
/// El RLS limita cada escritura a las filas del propio usuario.
abstract class ProfileRemoteDataSource {
  Future<CharacterProfileModel> getProfile();

  Future<void> updateIdentity({
    required String displayName,
    String? identityStatement,
  });

  Future<void> createSkill(String name);

  Future<void> renameSkill({required String skillId, required String name});

  Future<void> deleteSkill(String skillId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<CharacterProfileModel> getProfile() => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>?>('profile_overview');
    // Null: aún no existe la fila de profiles de este usuario.
    if (json == null) throw const ServerException(code: 'profile_not_found');
    return CharacterProfileModel.fromJson(json);
  });

  @override
  Future<void> updateIdentity({
    required String displayName,
    String? identityStatement,
  }) => _guard(() async {
    final identity = identityStatement?.trim();
    await _client
        .from('profiles')
        .update({
          'display_name': displayName.trim(),
          'identity_statement': identity == null || identity.isEmpty
              ? null
              : identity,
        })
        .eq('id', _userId);
  });

  @override
  Future<void> createSkill(String name) => _guard(
    () => _client.from('skills').insert({
      'user_id': _userId,
      'name': name.trim(),
    }),
  );

  @override
  Future<void> renameSkill({required String skillId, required String name}) =>
      _guard(
        () => _client
            .from('skills')
            .update({'name': name.trim()})
            .eq('id', skillId),
      );

  @override
  Future<void> deleteSkill(String skillId) =>
      _guard(() => _client.from('skills').delete().eq('id', skillId));

  String get _userId =>
      _client.auth.currentUser?.id ??
      (throw const ServerException(code: 'not_authenticated'));

  /// Los motivos propios de las funciones SQL llegan como mensaje (p. ej.
  /// `skill_limit_reached`) y el código SQLSTATE en [ServerException.statusCode].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ServerException {
      rethrow;
    } on PostgrestException catch (error) {
      throw ServerException(
        code: error.message,
        message: error.details?.toString(),
        statusCode: error.code,
      );
    } on ClientException catch (error) {
      throw NetworkException(error.message);
    } on TimeoutException catch (error) {
      throw NetworkException(error.message);
    }
  }
}
