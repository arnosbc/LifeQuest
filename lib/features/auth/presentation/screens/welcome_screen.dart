import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Bienvenida antes del login: paisaje de montañas, marca y «Comenzar».
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _deep = Color(0xFF3B2A72);

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: _deep,
    ),
    child: Scaffold(
      backgroundColor: _deep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LifeQuestLandscape(hiker: true, alignment: Alignment(0, .4)),
          // Oscurece la parte baja para que el texto blanco se lea.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x003B2A72), _deep],
                stops: [0, .55, .92],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                children: [
                  const LifeQuestLogo(size: 84),
                  const SizedBox(height: QSpace.s),
                  const LifeQuestWordmark(size: 36, onDark: true),
                  const SizedBox(height: QSpace.s),
                  Text(
                    'Tus metas, tu mejor versión',
                    style: QText.body(
                      Colors.white,
                    ).copyWith(fontSize: 15, letterSpacing: .4),
                  ),
                  const Spacer(),
                  Text(
                    'Planifica  •  Avanza  •  Logra',
                    style: QText.label(Colors.white).copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: QSpace.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () => context.go(RoutePaths.login),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _deep,
                        textStyle: QText.label(_deep).copyWith(fontSize: 16),
                      ),
                      child: const Text('Comenzar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
