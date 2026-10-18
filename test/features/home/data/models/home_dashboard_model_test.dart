import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/home/data/models/home_dashboard_model.dart';

import '../../home_fixtures.dart';

void main() {
  test('convierte el JSON de la RPC en la entidad', () {
    expect(HomeDashboardModel.fromJson(dashboardJson).toEntity(), dashboard);
  });

  test('sin estadísticas, misión ni hábitos usa los valores por defecto', () {
    final entity = HomeDashboardModel.fromJson(const {
      'display_name': '  ',
      'character_class': null,
      'level': null,
      'priority_mission': null,
      'habits': null,
      'habits_done': 0,
    }).toEntity();

    expect(entity, emptyDashboard);
  });
}
