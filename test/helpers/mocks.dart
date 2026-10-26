import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

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
import 'package:proyecto_movil/features/profile/domain/usecases/set_active_title.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/update_identity.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:proyecto_movil/features/stage/data/datasources/stage_remote_datasource.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/archive_stage_item.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/complete_project.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/complete_stage_task.dart';
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
