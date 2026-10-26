import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:proyecto_movil/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/get_current_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/login_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/logout_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/register_user.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/dungeon/data/datasources/dungeon_remote_datasource.dart';
import 'package:proyecto_movil/features/dungeon/data/repositories/dungeon_repository_impl.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/complete_dungeon_cycle.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/complete_session_task.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/end_dungeon.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/get_dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/start_dungeon.dart';
import 'package:proyecto_movil/features/dungeon/presentation/blocs/dungeon_bloc.dart';
import 'package:proyecto_movil/features/habits/data/datasources/habits_remote_datasource.dart';
import 'package:proyecto_movil/features/habits/data/repositories/habits_repository_impl.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/complete_good_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/create_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/get_habits_board.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/register_bad_habit.dart';
import 'package:proyecto_movil/features/habits/presentation/blocs/habits_bloc.dart';
import 'package:proyecto_movil/features/home/data/datasources/home_remote_datasource.dart';
import 'package:proyecto_movil/features/home/data/repositories/home_repository_impl.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';
import 'package:proyecto_movil/features/home/domain/usecases/complete_habit.dart';
import 'package:proyecto_movil/features/home/domain/usecases/get_home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
import 'package:proyecto_movil/features/missions/data/datasources/missions_remote_datasource.dart';
import 'package:proyecto_movil/features/missions/data/repositories/missions_repository_impl.dart';
import 'package:proyecto_movil/features/missions/domain/repositories/missions_repository.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/complete_mission.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/create_mission.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/get_missions_board.dart';
import 'package:proyecto_movil/features/missions/presentation/blocs/missions_bloc.dart';
import 'package:proyecto_movil/features/profile/data/datasources/appearance_local_datasource.dart';
import 'package:proyecto_movil/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:proyecto_movil/features/profile/data/repositories/appearance_repository_impl.dart';
import 'package:proyecto_movil/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/appearance_repository.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/profile_repository.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/create_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/delete_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/get_character_profile.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/get_theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/rename_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/set_active_title.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/save_theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/update_identity.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:proyecto_movil/features/stage/data/datasources/stage_remote_datasource.dart';
import 'package:proyecto_movil/features/stage/data/repositories/stage_repository_impl.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/archive_stage_item.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/complete_project.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/complete_stage_task.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_goal.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_project.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_resource.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/get_stage_board.dart';
import 'package:proyecto_movil/features/stage/presentation/blocs/stage_bloc.dart';

final sl = GetIt.instance;

/// Registra todas las dependencias. Llamar una vez, después de
/// `Supabase.initialize`.
Future<void> initDependencies() async {
  // Externos
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // ---------- Auth ----------
  // Bloc: singleton porque la sesión es de toda la app.
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      getCurrentUser: sl(),
      loginUser: sl(),
      registerUser: sl(),
      logoutUser: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // Datasources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  // ---------- Home ----------
  // Bloc: factory, uno nuevo cada vez que se construye la pantalla.
  sl.registerFactory(
    () => HomeBloc(getHomeDashboard: sl(), completeHabit: sl()),
  );
  sl.registerLazySingleton(() => GetHomeDashboard(sl()));
  sl.registerLazySingleton(() => CompleteHabit(sl()));
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl()));
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(sl()),
  );

  // ---------- Misiones ----------
  sl.registerFactory(
    () => MissionsBloc(
      getMissionsBoard: sl(),
      createMission: sl(),
      completeMission: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetMissionsBoard(sl()));
  sl.registerLazySingleton(() => CreateMission(sl()));
  sl.registerLazySingleton(() => CompleteMission(sl()));
  sl.registerLazySingleton<MissionsRepository>(
    () => MissionsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<MissionsRemoteDataSource>(
    () => MissionsRemoteDataSourceImpl(sl()),
  );

  // ---------- Mazmorra ----------
  sl.registerFactory(
    () => DungeonBloc(
      getBoard: sl(),
      start: sl(),
      completeCycle: sl(),
      completeTask: sl(),
      end: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetDungeonBoard(sl()));
  sl.registerLazySingleton(() => StartDungeon(sl()));
  sl.registerLazySingleton(() => CompleteDungeonCycle(sl()));
  sl.registerLazySingleton(() => CompleteSessionTask(sl()));
  sl.registerLazySingleton(() => EndDungeon(sl()));
  sl.registerLazySingleton<DungeonRepository>(
    () => DungeonRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<DungeonRemoteDataSource>(
    () => DungeonRemoteDataSourceImpl(sl()),
  );

  // ---------- Hábitos ----------
  sl.registerFactory(
    () => HabitsBloc(
      getHabitsBoard: sl(),
      createHabit: sl(),
      completeGoodHabit: sl(),
      registerBadHabit: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetHabitsBoard(sl()));
  sl.registerLazySingleton(() => CreateHabit(sl()));
  sl.registerLazySingleton(() => CompleteGoodHabit(sl()));
  sl.registerLazySingleton(() => RegisterBadHabit(sl()));
  sl.registerLazySingleton<HabitsRepository>(() => HabitsRepositoryImpl(sl()));
  sl.registerLazySingleton<HabitsRemoteDataSource>(
    () => HabitsRemoteDataSourceImpl(sl()),
  );

  // ---------- Stage · P.A.R.A. ----------
  sl.registerFactory(
    () => StageBloc(
      getStageBoard: sl(),
      createProject: sl(),
      createGoal: sl(),
      completeTask: sl(),
      createResource: sl(),
      archive: sl(),
      completeProject: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetStageBoard(sl()));
  sl.registerLazySingleton(() => CreateProject(sl()));
  sl.registerLazySingleton(() => CreateGoal(sl()));
  sl.registerLazySingleton(() => CompleteStageTask(sl()));
  sl.registerLazySingleton(() => CreateResource(sl()));
  sl.registerLazySingleton(() => ArchiveStageItem(sl()));
  sl.registerLazySingleton(() => CompleteProject(sl()));
  sl.registerLazySingleton<StageRepository>(() => StageRepositoryImpl(sl()));
  sl.registerLazySingleton<StageRemoteDataSource>(
    () => StageRemoteDataSourceImpl(sl()),
  );

  // ---------- Perfil ----------
  sl.registerFactory(
    () => ProfileBloc(
      getCharacterProfile: sl(),
      updateIdentity: sl(),
      createSkill: sl(),
      renameSkill: sl(),
      deleteSkill: sl(),
      setActiveTitle: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetCharacterProfile(sl()));
  sl.registerLazySingleton(() => UpdateIdentity(sl()));
  sl.registerLazySingleton(() => CreateSkill(sl()));
  sl.registerLazySingleton(() => SetActiveTitle(sl()));
  sl.registerLazySingleton(() => RenameSkill(sl()));
  sl.registerLazySingleton(() => DeleteSkill(sl()));
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl()),
  );

  // ---------- Apariencia (tema) ----------
  // Bloc: singleton porque el tema es de toda la app.
  sl.registerLazySingleton(
    () => AppearanceBloc(getThemePreference: sl(), saveThemePreference: sl()),
  );
  sl.registerLazySingleton(() => GetThemePreference(sl()));
  sl.registerLazySingleton(() => SaveThemePreference(sl()));
  sl.registerLazySingleton<AppearanceRepository>(
    () => AppearanceRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AppearanceLocalDataSource>(
    () => AppearanceLocalDataSourceImpl(SharedPreferencesAsync()),
  );
}
