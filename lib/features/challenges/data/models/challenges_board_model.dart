import 'package:proyecto_movil/features/challenges/domain/entities/challenges_board.dart';

/// Respuesta JSON de `challenges_overview`
/// (supabase/migrations/052_challenges_league.sql).
class ChallengesBoardModel {
  const ChallengesBoardModel(this.json);

  factory ChallengesBoardModel.fromJson(Map<String, dynamic> json) =>
      ChallengesBoardModel(json);

  final Map<String, dynamic> json;

  ChallengesBoard toEntity() {
    final m = json['month'] as Map<String, dynamic>? ?? const {};
    final l = json['league'] as Map<String, dynamic>? ?? const {};
    return ChallengesBoard(
      daily: [
        for (final d in _list(json['daily']))
          DailyChallenge(
            key: d['key'] as String,
            progress: _int(d['progress']),
            target: _int(d['target']),
            coins: _int(d['coins']),
            claimed: d['claimed'] == true,
          ),
      ],
      month: MonthChallenge(
        progress: _int(m['progress']),
        target: _int(m['target']),
        coins: _int(m['coins']),
        claimed: m['claimed'] == true,
        daysLeft: _int(m['days_left']),
      ),
      league: League(
        division: _int(l['division']),
        daysLeft: _int(l['days_left']),
        xp: _int(l['xp']),
        lastResult: LeagueResult.values.asNameMap()[l['last_result']],
        rivals: [
          for (final r in _list(l['rivals']))
            Rival(name: r['name'] as String, xp: _int(r['xp'])),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> _list(Object? value) =>
      (value as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;
}
