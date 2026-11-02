import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/app/home_screen_widget.dart';

void main() {
  test('los enlaces del widget llevan a la pantalla correcta', () {
    expect(
      HomeScreenWidget.routeFor(Uri.parse('lifequest://focus?task=t1')),
      RoutePaths.focusOn('t1'),
    );
    expect(
      HomeScreenWidget.routeFor(Uri.parse('lifequest://focus')),
      RoutePaths.dungeon,
    );
    expect(
      HomeScreenWidget.routeFor(Uri.parse('lifequest://home')),
      RoutePaths.home,
    );
    expect(HomeScreenWidget.routeFor(Uri.parse('https://x.com')), isNull);
    expect(HomeScreenWidget.routeFor(null), isNull);
  });
}
