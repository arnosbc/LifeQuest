import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/questly_brand.dart';

/// Bienvenida antes del acceso: logo, mascota y «Comenzar». Siempre oscura,
/// como Foco: es la portada de la app.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _suelo = QColors.bgDark;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: _suelo,
    ),
    child: Scaffold(
      backgroundColor: _suelo,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Resplandor rojo de marca detrás de la mascota.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, 0.05),
                radius: 0.75,
                // Opacos: mezclar transparente con opaco deja un anillo.
                colors: [Color(0xFF4F1B1E), Color(0xFF261614), _suelo],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const QuestlyBrand(
                    logo: 104,
                    color: QColors.textDark,
                    lemaColor: QColors.text2Dark,
                  ),
                  const Expanded(child: _Mascota()),
                  Aparece(
                    delay: const Duration(milliseconds: 520),
                    child: Text(
                      'Anota  ·  Organiza tu día  ·  Avanza',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: QText.family,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: QColors.textDark.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Aparece(
                    delay: const Duration(milliseconds: 640),
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        // push: «atrás» en el acceso vuelve aquí en vez de cerrar la app.
                        onPressed: () => context.push(RoutePaths.login),
                        style: FilledButton.styleFrom(
                          backgroundColor: QColors.textDark,
                          foregroundColor: QColors.text,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: QText.family,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: const Text('Comenzar'),
                      ),
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

/// La mascota flotando despacio (quieta si el sistema pide reducir movimiento).
class _Mascota extends StatefulWidget {
  const _Mascota();

  @override
  State<_Mascota> createState() => _MascotaState();
}

class _MascotaState extends State<_Mascota>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flota = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quieta = context.motion(QMotion.fade) == Duration.zero;
    if (quieta) {
      _flota.stop();
    } else if (!_flota.isAnimating) {
      _flota.repeat();
    }
  }

  @override
  void dispose() {
    _flota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Aparece(
    delay: const Duration(milliseconds: 300),
    desde: 40,
    child: AnimatedBuilder(
      animation: _flota,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, math.sin(_flota.value * 2 * math.pi) * 8),
        child: child,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Image.asset(
            'assets/images/marca/bienvenida.png',
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}
