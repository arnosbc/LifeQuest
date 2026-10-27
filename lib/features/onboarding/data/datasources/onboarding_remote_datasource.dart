import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/onboarding/data/models/onboarding_status_model.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';

/// RPCs del Onboarding en Supabase. Lanza [ServerException] o [NetworkException].
abstract class OnboardingRemoteDataSource {
  Future<OnboardingStatusModel> getStatus();

  Future<void> complete(OnboardingChoices choices);
}

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  const OnboardingRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<OnboardingStatusModel> getStatus() => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>?>(
      'onboarding_overview',
    );
    // Null: aún no existe la fila de profiles de este usuario.
    if (json == null) throw const ServerException(code: 'profile_not_found');
    return OnboardingStatusModel.fromJson(json);
  });

  @override
  Future<void> complete(OnboardingChoices choices) => _guard(
    () => _client.rpc<void>(
      'complete_onboarding',
      params: {
        'p_identity': choices.identity,
        'p_skill': choices.skill,
        'p_difficulty': choices.difficulty.name,
      },
    ),
  );

  /// Los motivos de las funciones SQL llegan como mensaje (p. ej.
  /// `onboarding_done`) y el código SQLSTATE en [ServerException.statusCode].
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
