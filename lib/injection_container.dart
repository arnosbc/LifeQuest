import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/features/assistant/data/datasources/assistant_remote_datasource.dart';
import 'package:proyecto_movil/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/apply_day_plan.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/get_day_plan.dart';
import 'package:proyecto_movil/features/assistant/data/datasources/speech_voice_input.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/voice_input.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/break_down_task.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/listen_voice.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/interpret_capture.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/save_capture.dart';
import 'package:proyecto_movil/features/assistant/presentation/blocs/assistant_bloc.dart';
import 'package:proyecto_movil/features/assistant/presentation/blocs/capture_bloc.dart';
import 'package:proyecto_movil/core/calendar/device_phone_calendar.dart';
import 'package:proyecto_movil/core/calendar/phone_event.dart';
import 'package:proyecto_movil/features/home/domain/usecases/connect_calendar.dart';
import 'package:proyecto_movil/features/home/domain/usecases/schedule_task.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/snooze_mission.dart';
import 'package:proyecto_movil/features/reminders/data/datasources/reminders_local_datasource.dart';
import 'package:proyecto_movil/features/reminders/data/datasources/reminders_remote_datasource.dart';
import 'package:proyecto_movil/features/reminders/data/repositories/reminders_repository_impl.dart';
import 'package:proyecto_movil/features/reminders/domain/repositories/reminders_repository.dart';
import 'package:proyecto_movil/features/reminders/domain/usecases/sync_reminders.dart';
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
import 'package:proyecto_movil/features/journal/data/datasources/journal_remote_datasource.dart';
import 'package:proyecto_movil/features/journal/data/repositories/journal_repository_impl.dart';
import 'package:proyecto_movil/features/journal/domain/repositories/journal_repository.dart';
import 'package:proyecto_movil/features/journal/domain/usecases/get_journal.dart';
import 'package:proyecto_movil/features/journal/presentation/blocs/journal_bloc.dart';
import 'package:proyecto_movil/features/missions/data/datasources/missions_remote_datasource.dart';
import 'package:proyecto_movil/features/missions/data/repositories/missions_repository_impl.dart';
import 'package:proyecto_movil/features/missions/domain/repositories/missions_repository.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/complete_mission.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/create_mission.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/get_missions_board.dart';
import 'package:proyecto_movil/features/missions/presentation/blocs/missions_bloc.dart';
import 'package:proyecto_movil/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:proyecto_movil/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:proyecto_movil/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:proyecto_movil/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:proyecto_movil/features/onboarding/domain/usecases/get_onboarding_status.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
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
import 'package:proyecto_movil/features/profile/domain/usecases/save_theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/update_identity.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:proyecto_movil/features/stage/data/datasources/stage_remote_datasource.dart';
import 'package:proyecto_movil/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:proyecto_movil/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:proyecto_movil/features/settings/domain/repositories/settings_repository.dart';
import 'package:proyecto_movil/features/settings/domain/usecases/get_settings.dart';
import 'package:proyecto_movil/features/settings/domain/usecases/save_game_settings.dart';
import 'package:proyecto_movil/features/settings/presentation/blocs/settings_bloc.dart';
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
import 'package:proyecto_movil/features/brain_dump/data/datasources/brain_dump_remote_datasource.dart';
import 'package:proyecto_movil/features/brain_dump/data/repositories/brain_dump_repository_impl.dart';
import 'package:proyecto_movil/features/brain_dump/domain/repositories/brain_dump_repository.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/get_brain_dump.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/capture_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/file_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/convert_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/delete_thought.dart';
import 'package:proyecto_movil/features/brain_dump/presentation/blocs/brain_dump_bloc.dart';
import 'package:proyecto_movil/features/stats/data/datasources/stats_remote_datasource.dart';
import 'package:proyecto_movil/features/stats/data/repositories/stats_repository_impl.dart';
import 'package:proyecto_movil/features/stats/domain/repositories/stats_repository.dart';
import 'package:proyecto_movil/features/stats/domain/usecases/get_stats.dart';
import 'package:proyecto_movil/features/stats/presentation/blocs/stats_bloc.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/rename_mission.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/delete_mission.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/rename_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/delete_habit.dart';
import 'package:proyecto_movil/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:proyecto_movil/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:proyecto_movil/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:proyecto_movil/features/notifications/domain/usecases/get_notifications.dart';
import 'package:proyecto_movil/features/notifications/domain/usecases/mark_notifications_read.dart';
import 'package:proyecto_movil/features/notifications/presentation/blocs/notifications_bloc.dart';

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
    () => HomeBloc(
      getHomeDashboard: sl(),
      completeHabit: sl(),
      scheduleTask: sl(),
      connectCalendar: sl(),
    ),
  );
  sl.registerLazySingleton(() => ScheduleTask(sl()));
  sl.registerLazySingleton(() => GetHomeDashboard(sl()));
  sl.registerLazySingleton(() => CompleteHabit(sl()));
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => ConnectCalendar(sl()));
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(sl()),
  );

  // ---------- Misiones ----------
  sl.registerFactory(
    () => MissionsBloc(
      getMissionsBoard: sl(),
      createMission: sl(),
      completeMission: sl(),
      renameMission: sl(),
      deleteMission: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetMissionsBoard(sl()));
  sl.registerLazySingleton(() => RenameMission(sl()));
  sl.registerLazySingleton(() => DeleteMission(sl()));
  sl.registerLazySingleton(() => CreateMission(sl()));
  sl.registerLazySingleton(() => CompleteMission(sl()));
  sl.registerLazySingleton(() => SnoozeMission(sl()));
  sl.registerLazySingleton<MissionsRepository>(
    () => MissionsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<MissionsRemoteDataSource>(
    () => MissionsRemoteDataSourceImpl(sl()),
  );

  // ---------- Calendario del teléfono (core: lo leen Hoy y el Asistente) ----------
  sl.registerLazySingleton<PhoneCalendar>(
    () => DevicePhoneCalendar(SharedPreferencesAsync()),
  );

  // ---------- Asistente ----------
  sl.registerFactory(() => AssistantBloc(getDayPlan: sl(), applyDayPlan: sl()));
  sl.registerLazySingleton(() => GetDayPlan(sl()));
  sl.registerFactory(
    () =>
        CaptureBloc(interpret: sl(), breakDown: sl(), save: sl(), listen: sl()),
  );
  sl.registerLazySingleton(() => ListenVoice(sl()));
  sl.registerLazySingleton<VoiceInput>(SpeechVoiceInput.new);
  sl.registerLazySingleton(() => InterpretCapture(sl()));
  sl.registerLazySingleton(() => BreakDownTask(sl()));
  sl.registerLazySingleton(() => SaveCapture(sl()));
  sl.registerLazySingleton(() => ApplyDayPlan(sl()));
  sl.registerLazySingleton<AssistantRepository>(
    () => AssistantRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AssistantRemoteDataSource>(
    () => AssistantRemoteDataSourceImpl(sl()),
  );

  // ---------- Recordatorios ----------
  sl.registerLazySingleton(FlutterLocalNotificationsPlugin.new);
  sl.registerLazySingleton(() => SyncReminders(sl()));
  sl.registerLazySingleton<RemindersRepository>(
    () => RemindersRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<RemindersRemoteDataSource>(
    () => RemindersRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<RemindersLocalDataSource>(
    () => RemindersLocalDataSourceImpl(sl()),
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
      renameHabit: sl(),
      deleteHabit: sl(),
    ),
  );
  sl.registerLazySingleton(() => RenameHabit(sl()));
  sl.registerLazySingleton(() => DeleteHabit(sl()));
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

  // ---------- Diario ----------
  sl.registerFactory(() => JournalBloc(getJournal: sl()));
  sl.registerLazySingleton(() => GetJournal(sl()));
  sl.registerLazySingleton<JournalRepository>(
    () => JournalRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<JournalRemoteDataSource>(
    () => JournalRemoteDataSourceImpl(sl()),
  );

  // ---------- Brain Dump ----------
  sl.registerFactory(
    () => BrainDumpBloc(
      getBoard: sl(),
      capture: sl(),
      file: sl(),
      convert: sl(),
      delete: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetBrainDump(sl()));
  sl.registerLazySingleton(() => CaptureThought(sl()));
  sl.registerLazySingleton(() => FileThought(sl()));
  sl.registerLazySingleton(() => ConvertThought(sl()));
  sl.registerLazySingleton(() => DeleteThought(sl()));
  sl.registerLazySingleton<BrainDumpRepository>(
    () => BrainDumpRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<BrainDumpRemoteDataSource>(
    () => BrainDumpRemoteDataSourceImpl(sl()),
  );

  // ---------- Estadísticas ----------
  sl.registerFactory(() => StatsBloc(getStats: sl()));
  sl.registerLazySingleton(() => GetStats(sl()));
  sl.registerLazySingleton<StatsRepository>(() => StatsRepositoryImpl(sl()));
  sl.registerLazySingleton<StatsRemoteDataSource>(
    () => StatsRemoteDataSourceImpl(sl()),
  );

  // ---------- Avisos ----------
  sl.registerFactory(
    () => NotificationsBloc(getNotifications: sl(), markRead: sl()),
  );
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => MarkNotificationsRead(sl()));
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(sl()),
  );

  // ---------- Onboarding ----------
  // Bloc: singleton porque el router lo consulta en toda la app.
  sl.registerLazySingleton(
    () => OnboardingBloc(getOnboardingStatus: sl(), completeOnboarding: sl()),
  );
  sl.registerLazySingleton(() => GetOnboardingStatus(sl()));
  sl.registerLazySingleton(() => CompleteOnboarding(sl()));
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceImpl(sl()),
  );

  // ---------- Perfil ----------
  sl.registerFactory(
    () => ProfileBloc(
      getCharacterProfile: sl(),
      updateIdentity: sl(),
      createSkill: sl(),
      renameSkill: sl(),
      deleteSkill: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetCharacterProfile(sl()));
  sl.registerLazySingleton(() => UpdateIdentity(sl()));
  sl.registerLazySingleton(() => CreateSkill(sl()));
  sl.registerLazySingleton(() => RenameSkill(sl()));
  sl.registerLazySingleton(() => DeleteSkill(sl()));
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl()),
  );

  // ---------- Configuración (Game Master) ----------
  sl.registerFactory(
    () => SettingsBloc(getSettings: sl(), saveGameSettings: sl()),
  );
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => SaveGameSettings(sl()));
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(sl()),
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
