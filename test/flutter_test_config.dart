import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// El fondo de estrellas se anima sin fin y haría fallar `pumpAndSettle`; con
/// «Quitar animaciones» activo queda quieto, igual que en el teléfono.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  await testMain();
}
