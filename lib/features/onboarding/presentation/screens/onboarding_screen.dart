import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:proyecto_movil/features/onboarding/presentation/widgets/onboarding_steps.dart';

/// Onboarding de 5 pasos. Nada se guarda hasta terminar o saltar; al hacerlo
/// el bloc pasa a [OnboardingNotNeeded] y el router lleva a Inicio.
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
  Widget build(BuildContext context) =>
      BlocConsumer<OnboardingBloc, OnboardingState>(
        listenWhen: (_, state) =>
            state is OnboardingPending && state.error != null,
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text((state as OnboardingPending).error!),
              behavior: SnackBarBehavior.floating,
              backgroundColor: context.lq.ink,
              action: SnackBarAction(
                label: 'Reintentar',
                textColor: context.lq.background,
                onPressed: _submit,
              ),
            ),
          ),
        builder: (context, state) => Scaffold(
          body: SafeArea(
            child: switch (state) {
              OnboardingPending(:final status, :final saving) => _content(
                status,
                saving,
              ),
              _ => Center(
                child: Semantics(
                  label: 'Preparando tu aventura',
                  child: CircularProgressIndicator(color: context.lq.deepGreen),
                ),
              ),
            },
          ),
        ),
      );

  Widget _content(OnboardingStatus status, bool saving) {
    final lq = context.lq;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
            child: Row(
              children: [
                if (_step > 0)
                  IconButton(
                    onPressed: saving ? null : _back,
                    tooltip: 'Atrás',
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: lq.ink,
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    'Paso ${_step + 1} de ${OnboardingScreen.stepCount}',
                    style: TextStyle(color: lq.muted, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: saving ? null : _submit,
                  style: TextButton.styleFrom(
                    foregroundColor: lq.deepGreen,
                    minimumSize: const Size(64, 48),
                  ),
                  child: const Text('Saltar'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ExcludeSemantics(
              child: LinearProgressIndicator(
                value: (_step + 1) / OnboardingScreen.stepCount,
                color: lq.deepGreen,
                backgroundColor: lq.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: saving ? null : _next,
                style: FilledButton.styleFrom(
                  backgroundColor: lq.deepGreen,
                  foregroundColor: lq.onDeepGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: saving
                    ? SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: lq.muted,
                          semanticsLabel: 'Guardando',
                        ),
                      )
                    : Text(switch (_step) {
                        0 => 'Empezar',
                        _ when last => 'Entrar al reino',
                        _ => 'Continuar',
                      }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
