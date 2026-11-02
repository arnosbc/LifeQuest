import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:proyecto_movil/features/onboarding/presentation/widgets/onboarding_steps.dart';

/// Onboarding de 5 pasos (Onboarding.dc.html con DESIGN.md v2). Nada se guarda
/// hasta terminar o saltar; al hacerlo el bloc pasa a [OnboardingNotNeeded] y
/// el router lleva a Inicio.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const stepCount = 5;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _identity = TextEditingController();
  final _skill = TextEditingController();
  int _step = 0;

  // Solo cambia en el paso 4: quien salta antes se queda en Normal (FR-005).
  GameDifficulty _difficulty = GameDifficulty.normal;

  @override
  void dispose() {
    _identity.dispose();
    _skill.dispose();
    super.dispose();
  }

  void _submit() => context.read<OnboardingBloc>().add(
    OnboardingSubmitted(
      OnboardingChoices(
        identity: _identity.text,
        skill: _skill.text,
        difficulty: _difficulty,
      ),
    ),
  );

  void _next() => _step == OnboardingScreen.stepCount - 1
      ? _submit()
      : setState(() => _step++);

  void _back() => setState(() => _step--);

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (_, state) =>
          state is OnboardingPending && state.error != null,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text((state as OnboardingPending).error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: q.strong,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: q.toastAction,
              onPressed: _submit,
            ),
          ),
        ),
      builder: (context, state) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: q.bg,
          body: switch (state) {
            OnboardingPending(:final status, :final saving) => _content(
              status,
              saving,
            ),
            _ => Center(
              child: Semantics(
                label: 'Preparando tu cuenta',
                child: CircularProgressIndicator(color: q.ink),
              ),
            ),
          },
        ),
      ),
    );
  }

  Widget _content(OnboardingStatus status, bool saving) {
    final q = context.q;
    final last = _step == OnboardingScreen.stepCount - 1;
    return PopScope(
      // Atrás del sistema vuelve al paso anterior conservando lo escrito.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !saving) _back();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            step: _step,
            big: _step == 0,
            onBack: _step > 0 && !saving ? _back : null,
            onSkip: saving ? null : _submit,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: switch (_step) {
                0 => const WelcomeStep(),
                1 => IdentityStep(controller: _identity),
                2 => SkillStep(controller: _skill),
                3 => DifficultyStep(
                  options: status.difficulties,
                  selected: _difficulty,
                  onSelected: (level) => setState(() => _difficulty = level),
                ),
                _ => SummaryStep(
                  identity: _identity.text,
                  skill: _skill.text,
                  difficulty: _difficulty,
                ),
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(QRadius.block),
                boxShadow: [
                  BoxShadow(color: q.buttonShadow, offset: const Offset(0, 4)),
                ],
              ),
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: saving ? null : _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: q.accent,
                    foregroundColor: q.onAccent,
                    // Guardando no es «desactivado»: mantiene sus colores.
                    disabledBackgroundColor: q.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(QRadius.block),
                    ),
                    textStyle: QText.label(q.onAccent).copyWith(fontSize: 17),
                  ),
                  child: saving
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: q.onAccent,
                            semanticsLabel: 'Guardando',
                          ),
                        )
                      : Text(switch (_step) {
                          0 => 'Empezar',
                          _ when last => 'Ir al inicio',
                          _ => 'Continuar',
                        }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banda del tema con las formas del Hero, volver, los puntos de avance,
/// «Saltar» y el icono del Asistente (sin mascota, DESIGN.md v2 §1).
class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.big,
    required this.onBack,
    required this.onSkip,
  });

  final int step;
  final bool big;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final t = q.hero;
    final top = MediaQuery.paddingOf(context).top;
    final spark = big ? 72.0 : 52.0;
    return AnimatedContainer(
      duration: context.motion(QMotion.sheet),
      height: (big ? 260 : 180) + top,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: SvgPicture.string(
                LifeQuestLandscape.svg(),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, top + 8, 8, 0),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 48,
                  child: onBack == null
                      ? null
                      : IconButton(
                          onPressed: onBack,
                          tooltip: 'Atrás',
                          icon: QIcon(
                            QIcons.back,
                            color: QHeroTone.text,
                            size: 22,
                            strokeWidth: 2.4,
                          ),
                        ),
                ),
                Expanded(
                  child: _Progress(step: step, kicker: t.kicker),
                ),
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: t.kicker,
                    minimumSize: const Size(64, 48),
                    textStyle: QText.label(t.kicker),
                  ),
                  child: const Text('Saltar'),
                ),
              ],
            ),
          ),
          Positioned(
            left: QSpace.xl,
            bottom: QSpace.l,
            child: ExcludeSemantics(
              child: Container(
                width: spark,
                height: spark,
                decoration: BoxDecoration(
                  color: QHeroTone.actionBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: QIcon(
                  QIcons.spark,
                  color: QHeroTone.badgeBg,
                  size: spark * .5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.kicker});

  final int step;
  final Color kicker;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < OnboardingScreen.stepCount; i++)
              AnimatedContainer(
                duration: context.motion(QMotion.sheet),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == step ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= step ? QHeroTone.badgeBg : QHeroTone.actionBg,
                  borderRadius: BorderRadius.circular(QRadius.pill),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Paso ${step + 1} de ${OnboardingScreen.stepCount}',
        style: QText.body(kicker).copyWith(fontSize: 12),
      ),
    ],
  );
}
