import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/features/notifications/domain/usecases/get_notifications.dart';
import 'package:proyecto_movil/features/notifications/domain/usecases/mark_notifications_read.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/rename_mission.dart'
    as rm;
import 'package:proyecto_movil/features/missions/domain/usecases/delete_mission.dart'
    as dm;
import 'package:proyecto_movil/features/habits/domain/usecases/rename_habit.dart'
    as rh;
import 'package:proyecto_movil/features/habits/domain/usecases/delete_habit.dart'
    as dh;
import 'package:proyecto_movil/features/tavern/domain/usecases/rename_npc.dart'
    as rn;
import 'package:proyecto_movil/features/tavern/domain/usecases/delete_npc.dart'
    as dn;
import 'package:proyecto_movil/features/brain_dump/domain/usecases/get_brain_dump.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/capture_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/file_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/convert_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/delete_thought.dart';
import 'package:proyecto_movil/features/vision/domain/usecases/get_vision_board.dart';
import 'package:proyecto_movil/features/vision/domain/usecases/save_vision.dart';
import 'package:proyecto_movil/features/vision/domain/usecases/set_vision_link.dart';
import 'package:proyecto_movil/features/stats/domain/usecases/get_stats.dart';
import 'package:proyecto_movil/features/inventory/domain/usecases/get_inventory.dart';
import 'package:proyecto_movil/features/goals/domain/usecases/archive_goal.dart';
import 'package:proyecto_movil/features/goals/domain/usecases/attack_boss.dart';
import 'package:proyecto_movil/features/goals/domain/usecases/get_goals_board.dart';
import 'package:proyecto_movil/features/journal/domain/usecases/get_journal.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/activate_elixir.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/buy_black_market_item.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/buy_market_item.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/get_market_board.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/upgrade_refuge.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/use_recovery_pass.dart';
import 'package:proyecto_movil/features/rpgenie/domain/usecases/complete_current_mission.dart';
import 'package:proyecto_movil/features/rpgenie/domain/usecases/get_current_mission.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/accept_npc_mission.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/complete_npc_mission.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/create_npc.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/get_tavern_board.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/suggest_npc_mission.dart';
import 'package:proyecto_movil/features/tavern/presentation/blocs/tavern_bloc.dart';
import 'package:proyecto_movil/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/get_current_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/login_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/logout_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/register_user.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/dungeon/data/datasources/dungeon_remote_datasource.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/complete_dungeon_cycle.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/complete_session_task.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/end_dungeon.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/get_dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/start_dungeon.dart';
import 'package:proyecto_movil/features/dungeon/presentation/blocs/dungeon_bloc.dart';
import 'package:proyecto_movil/features/habits/data/datasources/habits_remote_datasource.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/complete_good_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/create_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/get_habits_board.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/register_bad_habit.dart';
import 'package:proyecto_movil/features/habits/presentation/blocs/habits_bloc.dart';
import 'package:proyecto_movil/features/home/data/datasources/home_remote_datasource.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';
import 'package:proyecto_movil/features/home/domain/usecases/claim_daily_chest.dart';
import 'package:proyecto_movil/features/home/domain/usecases/complete_habit.dart';
import 'package:proyecto_movil/features/home/domain/usecases/get_home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
import 'package:proyecto_movil/features/missions/data/datasources/missions_remote_datasource.dart';
import 'package:proyecto_movil/features/missions/domain/repositories/missions_repository.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/complete_mission.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/create_mission.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/get_missions_board.dart';
import 'package:proyecto_movil/features/missions/presentation/blocs/missions_bloc.dart';
import 'package:proyecto_movil/features/profile/data/datasources/appearance_local_datasource.dart';
import 'package:proyecto_movil/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/appearance_repository.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/profile_repository.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/create_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/delete_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/get_character_profile.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/get_theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/rename_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/save_theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/get_theme_realm.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/save_theme_realm.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/set_active_title.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/update_identity.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:proyecto_movil/features/stage/data/datasources/stage_remote_datasource.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/archive_stage_item.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/complete_project.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/complete_stage_task.dart';
import 'package:proyecto_movil/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:proyecto_movil/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:proyecto_movil/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:proyecto_movil/features/onboarding/domain/usecases/get_onboarding_status.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:proyecto_movil/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:proyecto_movil/features/settings/domain/repositories/settings_repository.dart';
import 'package:proyecto_movil/features/settings/domain/usecases/get_settings.dart';
import 'package:proyecto_movil/features/settings/domain/usecases/save_game_settings.dart';
import 'package:proyecto_movil/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_goal.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_project.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_resource.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/get_stage_board.dart';
import 'package:proyecto_movil/features/stage/presentation/blocs/stage_bloc.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockLoginUser extends Mock implements LoginUser {}

class MockRegisterUser extends Mock implements RegisterUser {}

class MockLogoutUser extends Mock implements LogoutUser {}

class MockDungeonRemoteDataSource extends Mock
    implements DungeonRemoteDataSource {}

class MockDungeonRepository extends Mock implements DungeonRepository {}

class MockGetDungeonBoard extends Mock implements GetDungeonBoard {}

class MockStartDungeon extends Mock implements StartDungeon {}

class MockCompleteDungeonCycle extends Mock implements CompleteDungeonCycle {}

class MockCompleteSessionTask extends Mock implements CompleteSessionTask {}

class MockEndDungeon extends Mock implements EndDungeon {}

class MockDungeonBloc extends MockBloc<DungeonEvent, DungeonState>
    implements DungeonBloc {}

class MockHabitsBloc extends MockBloc<HabitsEvent, HabitsState>
    implements HabitsBloc {}

class MockHabitsRepository extends Mock implements HabitsRepository {}

class MockHabitsRemoteDataSource extends Mock
    implements HabitsRemoteDataSource {}

class MockGetHabitsBoard extends Mock implements GetHabitsBoard {}

class MockCreateHabit extends Mock implements CreateHabit {}

class MockCompleteGoodHabit extends Mock implements CompleteGoodHabit {}

class MockRegisterBadHabit extends Mock implements RegisterBadHabit {}

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockHomeRepository extends Mock implements HomeRepository {}

class MockHomeRemoteDataSource extends Mock implements HomeRemoteDataSource {}

class MockGetHomeDashboard extends Mock implements GetHomeDashboard {}

class MockCompleteHabit extends Mock implements CompleteHabit {}

class MockClaimDailyChest extends Mock implements ClaimDailyChest {}

class MockMissionsBloc extends MockBloc<MissionsEvent, MissionsState>
    implements MissionsBloc {}

class MockMissionsRepository extends Mock implements MissionsRepository {}

class MockMissionsRemoteDataSource extends Mock
    implements MissionsRemoteDataSource {}

class MockGetMissionsBoard extends Mock implements GetMissionsBoard {}

class MockCreateMission extends Mock implements CreateMission {}

class MockCompleteMission extends Mock implements CompleteMission {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class MockGetCharacterProfile extends Mock implements GetCharacterProfile {}

class MockUpdateIdentity extends Mock implements UpdateIdentity {}

class MockCreateSkill extends Mock implements CreateSkill {}

class MockRenameSkill extends Mock implements RenameSkill {}

class MockDeleteSkill extends Mock implements DeleteSkill {}

class MockSetActiveTitle extends Mock implements SetActiveTitle {}

class MockAppearanceBloc extends MockBloc<AppearanceEvent, AppearanceState>
    implements AppearanceBloc {}

class MockAppearanceRepository extends Mock implements AppearanceRepository {}

class MockAppearanceLocalDataSource extends Mock
    implements AppearanceLocalDataSource {}

class MockGetThemePreference extends Mock implements GetThemePreference {}

class MockSaveThemePreference extends Mock implements SaveThemePreference {}

class MockGetThemeRealm extends Mock implements GetThemeRealm {}

class MockSaveThemeRealm extends Mock implements SaveThemeRealm {}

class MockStageBloc extends MockBloc<StageEvent, StageState>
    implements StageBloc {}

class MockStageRepository extends Mock implements StageRepository {}

class MockStageRemoteDataSource extends Mock implements StageRemoteDataSource {}

class MockGetStageBoard extends Mock implements GetStageBoard {}

class MockCreateProject extends Mock implements CreateProject {}

class MockCreateResource extends Mock implements CreateResource {}

class MockArchiveStageItem extends Mock implements ArchiveStageItem {}

class MockCompleteProject extends Mock implements CompleteProject {}

class MockCreateGoal extends Mock implements CreateGoal {}

class MockCompleteStageTask extends Mock implements CompleteStageTask {}

class MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

class MockOnboardingRemoteDataSource extends Mock
    implements OnboardingRemoteDataSource {}

class MockGetOnboardingStatus extends Mock implements GetOnboardingStatus {}

class MockCompleteOnboarding extends Mock implements CompleteOnboarding {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockSettingsRemoteDataSource extends Mock
    implements SettingsRemoteDataSource {}

class MockGetSettings extends Mock implements GetSettings {}

class MockSaveGameSettings extends Mock implements SaveGameSettings {}

// Marketplace, Taverna, Diario, Objetivos y RPGenie (018–022).
class MockGetMarketBoard extends Mock implements GetMarketBoard {}

class MockBuyMarketItem extends Mock implements BuyMarketItem {}

class MockBuyBlackMarketItem extends Mock implements BuyBlackMarketItem {}

class MockUseRecoveryPass extends Mock implements UseRecoveryPass {}

class MockUpgradeRefuge extends Mock implements UpgradeRefuge {}

class MockActivateElixir extends Mock implements ActivateElixir {}

class MockTavernBloc extends MockBloc<TavernEvent, TavernState>
    implements TavernBloc {}

class MockGetTavernBoard extends Mock implements GetTavernBoard {}

class MockCreateNpc extends Mock implements CreateNpc {}

class MockSuggestNpcMission extends Mock implements SuggestNpcMission {}

class MockAcceptNpcMission extends Mock implements AcceptNpcMission {}

class MockCompleteNpcMission extends Mock implements CompleteNpcMission {}

class MockGetJournal extends Mock implements GetJournal {}

class MockGetGoalsBoard extends Mock implements GetGoalsBoard {}

class MockAttackBoss extends Mock implements AttackBoss {}

class MockArchiveGoal extends Mock implements ArchiveGoal {}

class MockGetCurrentMission extends Mock implements GetCurrentMission {}

class MockCompleteCurrentMission extends Mock
    implements CompleteCurrentMission {}

// Brain Dump, Vision Board, Estadísticas e Inventario (023–026).
class MockGetBrainDump extends Mock implements GetBrainDump {}

class MockCaptureThought extends Mock implements CaptureThought {}

class MockFileThought extends Mock implements FileThought {}

class MockConvertThought extends Mock implements ConvertThought {}

class MockDeleteThought extends Mock implements DeleteThought {}

class MockGetVisionBoard extends Mock implements GetVisionBoard {}

class MockSaveVision extends Mock implements SaveVision {}

class MockSetVisionLink extends Mock implements SetVisionLink {}

class MockGetStats extends Mock implements GetStats {}

class MockGetInventory extends Mock implements GetInventory {}

// Renombrar y borrar (028).
class MockRenameMission extends Mock implements rm.RenameMission {}

class MockDeleteMission extends Mock implements dm.DeleteMission {}

class MockRenameHabit extends Mock implements rh.RenameHabit {}

class MockDeleteHabit extends Mock implements dh.DeleteHabit {}

class MockRenameNpc extends Mock implements rn.RenameNpc {}

class MockDeleteNpc extends Mock implements dn.DeleteNpc {}

// Avisos (029).
class MockGetNotifications extends Mock implements GetNotifications {}

class MockMarkNotificationsRead extends Mock implements MarkNotificationsRead {}
