import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/settings/data/models/settings_overview_model.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

/// Configuración en Supabase. Lanza [ServerException] o [NetworkException].
abstract class SettingsRemoteDataSource {
  Future<SettingsOverviewModel> getOverview();

  Future<void> save(GameSettings settings);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  const SettingsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<SettingsOverviewModel> getOverview() => guardSupabase(() async {
    final json = await _client.rpc<Map<String, dynamic>?>('settings_overview');
    // Null: aún no existe la fila de profiles de este usuario.
    if (json == null) throw const ServerException(code: 'profile_not_found');
    return SettingsOverviewModel.fromJson(json);
  });

  /// Update directo: el RLS, los grants de columna y los checks de 016
  /// limitan qué y cuánto se escribe. No toca la economía.
  @override
  Future<void> save(GameSettings settings) => guardSupabase(
    () => _client
        .from('game_master_settings')
        .update(SettingsOverviewModel.toRow(settings))
        .eq('user_id', _userId),
  );

  String get _userId =>
      _client.auth.currentUser?.id ??
      (throw const ServerException(code: 'not_authenticated'));
}
