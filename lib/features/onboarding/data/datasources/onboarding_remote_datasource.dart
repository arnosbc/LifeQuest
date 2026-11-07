import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/onboarding/data/models/onboarding_status_model.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

/// RPCs del Onboarding en Supabase. Lanza [ServerException] o [NetworkException].
abstract class OnboardingRemoteDataSource {
  Future<OnboardingStatusModel> getStatus();

  Future<void> complete(OnboardingChoices choices);
}

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  const OnboardingRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<OnboardingStatusModel> getStatus() => guardSupabase(() async {
    final json = await _client.rpc<Map<String, dynamic>?>(
      'onboarding_overview',
    );
    // Null: aún no existe la fila de profiles de este usuario.
    if (json == null) throw const ServerException(code: 'profile_not_found');
    return OnboardingStatusModel.fromJson(json);
  });

  @override
  Future<void> complete(OnboardingChoices choices) => guardSupabase(() async {
    await _client.rpc<void>(
      'complete_onboarding',
      params: {
        'p_identity': choices.identity,
        'p_skill': choices.skill,
        'p_difficulty': choices.difficulty.name,
      },
    );
    // Mismo update directo que Ajustes (016/033).
    if (choices.aiEnabled) {
      await _client
          .from('game_master_settings')
          .update({'ai_enabled': true})
          .eq('user_id', _client.auth.currentUser!.id);
    }
  });
}
