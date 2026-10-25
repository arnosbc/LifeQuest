import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/account_action_tile.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/character_card.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/hero_status_card.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/profile_quick_link.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/profile_sheets.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/skill_tile.dart';

/// Perfil del Personaje. Necesita un [ProfileBloc] (lo provee el router).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.userName,
    required this.onOpenNotifications,
    required this.onOpenHelp,
    required this.onOpenJournal,
    required this.onOpenMarketplace,
    required this.onOpenSettings,
  });

  /// Nombre de la sesión; se usa mientras el perfil no tenga uno propio.
  final String userName;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenJournal;
  final VoidCallback onOpenMarketplace;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => BlocConsumer<ProfileBloc, ProfileState>(
    listenWhen: (_, state) => state is ProfileSuccess && state.message != null,
    listener: (context, state) =>
        showLifeQuestMessage(context, (state as ProfileSuccess).message!),
    builder: (context, state) => switch (state) {
      ProfileInitial() || ProfileLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.deepGreen),
      ),
      ProfileFailure(:final message) => _ErrorView(
        message: message,
        onRetry: () =>
            context.read<ProfileBloc>().add(const ProfileRequested()),
      ),
      ProfileSuccess(:final profile, :final saving) => RefreshIndicator(
        color: context.lq.deepGreen,
        onRefresh: () => _refresh(context.read<ProfileBloc>()),
        child: _content(context, profile, saving: saving),
      ),
    },
  );

  static Future<void> _refresh(ProfileBloc bloc) {
    bloc.add(const ProfileRequested());
    return bloc.stream.firstWhere(
      (state) => state is! ProfileSuccess || !state.saving,
    );
  }

  Widget _content(
    BuildContext context,
    CharacterProfile profile, {
    required bool saving,
  }) {
    final lq = context.lq;
    final name = profile.displayName ?? userName;
    final bloc = context.read<ProfileBloc>();

    Future<void> editIdentity() async {
      final result = await showIdentitySheet(
        context,
        displayName: name,
        identityStatement: profile.identityStatement,
      );
      if (result case (final displayName, final identity)) {
        bloc.add(
          ProfileIdentitySaved(
            displayName: displayName,
            identityStatement: identity,
          ),
        );
      }
    }

    Future<void> chooseTitle() async {
      final choice = await showTitleSheet(
        context,
        earned: profile.earnedTitles,
        active: profile.activeTitle,
      );
      if (choice != null) bloc.add(ProfileActiveTitleChanged(choice.titleId));
    }

    Future<void> addSkill() async {
      if (await showSkillSheet(context) case SkillNameSaved(:final name)) {
        bloc.add(ProfileSkillCreated(name));
      }
    }

    Future<void> editSkill(Skill skill) async {
      switch (await showSkillSheet(context, name: skill.name)) {
        case SkillNameSaved(:final name) when name != skill.name:
          bloc.add(ProfileSkillRenamed(skillId: skill.id, name: name));
        case SkillDeleteRequested():
          bloc.add(ProfileSkillDeleted(skill.id));
        case _:
      }
    }

    void soon(String feature) =>
        showLifeQuestMessage(context, '$feature llegará pronto.');

    return LifeQuestPage(
      title: 'Perfil',
      subtitle: 'Tu progreso, a tu manera.',
      trailing: IconButton(
        onPressed: onOpenSettings,
        tooltip: 'Configuración',
        icon: const Icon(Icons.settings_outlined, size: 22),
        color: lq.ink,
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      children: [
        // Guardando o refrescando: una línea fina, sin tapar el contenido.
        SizedBox(
          height: 3,
          child: saving
              ? LinearProgressIndicator(
                  color: lq.deepGreen,
                  backgroundColor: Colors.transparent,
                )
              : null,
        ),
        const SizedBox(height: 8),
        CharacterCard(
          name: name,
          profile: profile,
          onEditIdentity: editIdentity,
          onChooseTitle: chooseTitle,
        ),
        const SizedBox(height: 12),
        HeroStatusCard(profile: profile),
        const SizedBox(height: 28),
        const LifeQuestSectionHeading('ACCESOS RÁPIDOS'),
        const SizedBox(height: 8),
        // Dos filas de 3: seis en una fila no caben en un teléfono.
        _group(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              for (final row in [
                [
                  ProfileQuickLink(
                    icon: Icons.menu_book_outlined,
                    label: 'Diario',
                    onTap: onOpenJournal,
                  ),
                  ProfileQuickLink(
                    icon: Icons.insights_outlined,
                    label: 'Estadísticas',
                    onTap: () => soon('Las Estadísticas'),
                  ),
                  ProfileQuickLink(
                    icon: Icons.visibility_outlined,
                    label: 'Vision Board',
                    onTap: () => soon('El Vision Board'),
                  ),
                ],
                [
                  ProfileQuickLink(
                    icon: Icons.inventory_2_outlined,
                    label: 'Inventario y logros',
                    onTap: () => soon('El Inventario y los logros'),
                  ),
                  ProfileQuickLink(
                    icon: Icons.storefront_outlined,
                    label: 'Marketplace',
                    onTap: onOpenMarketplace,
                  ),
                  ProfileQuickLink(
                    icon: Icons.tune_rounded,
                    label: 'Configuración',
                    onTap: onOpenSettings,
                  ),
                ],
              ])
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final link in row) Expanded(child: link)],
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        LifeQuestSectionHeading(
          'ÁRBOL DE HABILIDADES',
          action: '${profile.skills.length} / ${profile.skillLimit}',
        ),
        if (profile.skills.isEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Las skills son tus áreas de vida. Cada misión y hábito que '
            'vincules a una la hará crecer.',
            style: TextStyle(color: lq.muted, fontSize: 13, height: 1.4),
          ),
        ],
        for (final pair in _pairs([
          for (final skill in profile.skills)
            SkillTile(skill: skill, onTap: () => editSkill(skill)),
          if (profile.canAddSkill) AddSkillTile(onTap: addSkill),
        ])) ...[const SizedBox(height: 8), _row(pair)],
        const SizedBox(height: 28),
        const LifeQuestSectionHeading('CUENTA'),
        const SizedBox(height: 8),
        _group(
          child: Column(
            children: [
              AccountActionTile(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                onTap: onOpenNotifications,
              ),
              Divider(height: 1, indent: 54, color: lq.line),
              AccountActionTile(
                icon: Icons.help_outline,
                title: 'Ayuda',
                onTap: onOpenHelp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Superficie que agrupa filas tocables; recorta su efecto de toque.
  static Widget _group({required Widget child, EdgeInsets? padding}) =>
      LifeQuestSurface(
        padding: padding ?? EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      );

  static Iterable<List<Widget>> _pairs(List<Widget> tiles) sync* {
    for (var i = 0; i < tiles.length; i += 2) {
      yield tiles.sublist(i, i + 2 > tiles.length ? tiles.length : i + 2);
    }
  }

  /// Dos columnas de igual alto; una fila impar deja el hueco a la derecha.
  static Widget _row(List<Widget> children) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 8),
        Expanded(
          child: children.length > 1 ? children[1] : const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LifeQuestIconTile(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.lq.ink, fontSize: 15),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(
              backgroundColor: context.lq.deepGreen,
              foregroundColor: context.lq.onDeepGreen,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    ),
  );
}
