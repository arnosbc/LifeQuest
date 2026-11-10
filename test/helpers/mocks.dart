import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/calendar/phone_event.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/listen_voice.dart';
import 'package:proyecto_movil/features/home/domain/usecases/connect_calendar.dart';
import 'package:proyecto_movil/features/home/domain/usecases/complete_reminder.dart';
import 'package:proyecto_movil/features/home/domain/usecases/schedule_task.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/set_habit_reminder.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/update_task.dart';
import 'package:proyecto_movil/features/reminders/domain/usecases/sync_reminders.dart';

import 'package:proyecto_movil/features/notifications/domain/usecases/get_notifications.dart';
import 'package:proyecto_movil/features/notifications/domain/usecases/mark_notifications_read.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/rename_task.dart'
    as rm;
import 'package:proyecto_movil/features/tasks/domain/usecases/delete_task.dart'
    as dm;
import 'package:proyecto_movil/features/habits/domain/usecases/rename_habit.dart'
    as rh;
import 'package:proyecto_movil/features/habits/domain/usecases/delete_habit.dart'
    as dh;
import 'package:proyecto_movil/features/brain_dump/domain/usecases/get_brain_dump.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/capture_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/file_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/convert_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/delete_thought.dart';
import 'package:proyecto_movil/features/stats/domain/usecases/get_stats.dart';
import 'package:proyecto_movil/features/journal/domain/usecases/get_journal.dart';
import 'package:proyecto_movil/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/get_current_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/login_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/logout_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/register_user.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/focus/data/datasources/focus_remote_datasource.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/add_focus_step.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/capture_distraction.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/get_recall_questions.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/save_resume_note.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/save_step_proof.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/complete_focus_cycle.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/complete_session_task.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/end_focus.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/get_focus_board.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/schedule_focus_task.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/start_focus.dart';
import 'package:proyecto_movil/features/focus/presentation/blocs/focus_bloc.dart';
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
import 'package:proyecto_movil/features/tasks/data/datasources/tasks_remote_datasource.dart';
import 'package:proyecto_movil/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/complete_task.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/create_task.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/get_tasks_board.dart';
import 'package:proyecto_movil/features/tasks/presentation/blocs/tasks_bloc.dart';
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
import 'package:proyecto_movil/features/profile/domain/usecases/update_identity.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:proyecto_movil/features/stage/data/datasources/stage_remote_datasource.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/archive_stage_item.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/delete_stage_item.dart';
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

class MockFocusRemoteDataSource extends Mock implements FocusRemoteDataSource {}

class MockFocusRepository extends Mock implements FocusRepository {}

class MockGetFocusBoard extends Mock implements GetFocusBoard {}

class MockStartFocus extends Mock implements StartFocus {}

class MockCompleteFocusCycle extends Mock implements CompleteFocusCycle {}

class MockCompleteSessionTask extends Mock implements CompleteSessionTask {}

class MockEndFocus extends Mock implements EndFocus {}

class MockAddFocusStep extends Mock implements AddFocusStep {}

class MockSaveStepProof extends Mock implements SaveStepProof {}

class MockSaveResumeNote extends Mock implements SaveResumeNote {}

class MockCaptureDistraction extends Mock implements CaptureDistraction {}

class MockGetRecallQuestions extends Mock implements GetRecallQuestions {}

class MockScheduleFocusTask extends Mock implements ScheduleFocusTask {}

class MockFocusBloc extends MockBloc<FocusEvent, FocusState>
    implements FocusBloc {}

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

class MockScheduleTask extends Mock implements ScheduleTask {}

class MockUpdateTask extends Mock implements UpdateTask {}

class MockSetHabitReminder extends Mock implements SetHabitReminder {}

class MockConnectCalendar extends Mock implements ConnectCalendar {}

class MockCompleteReminder extends Mock implements CompleteReminder {}

class MockListenVoice extends Mock implements ListenVoice {}

/// Calendario del teléfono de prueba: fijo, sin plugin.
class FakePhoneCalendar implements PhoneCalendar {
  FakePhoneCalendar({this.granted = false, this.list = const []});

  bool granted;
  final List<PhoneEvent> list;
  final requested = <(DateTime, DateTime)>[];
  int asked = 0;

  @override
  Future<CalendarAccess> access() async =>
      granted ? CalendarAccess.granted : CalendarAccess.denied;

  @override
  Future<CalendarAccess> requestAccess() async {
    asked++;
    granted = true;
    return CalendarAccess.granted;
  }

  @override
  Future<List<PhoneEvent>> events(DateTime from, DateTime to) async {
    requested.add((from, to));
    return granted ? list : const [];
  }
}

class MockSyncReminders extends Mock implements SyncReminders {}

class MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockTasksBloc extends MockBloc<TasksEvent, TasksState>
    implements TasksBloc {}

class MockTasksRepository extends Mock implements TasksRepository {}

class MockTasksRemoteDataSource extends Mock implements TasksRemoteDataSource {}

class MockGetTasksBoard extends Mock implements GetTasksBoard {}

class MockCreateTask extends Mock implements CreateTask {}

class MockCompleteTask extends Mock implements CompleteTask {}

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

class MockDeleteStageItem extends Mock implements DeleteStageItem {}

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

// Diario (020).
class MockGetJournal extends Mock implements GetJournal {}

// Brain Dump y Estadísticas (023, 025).
class MockGetBrainDump extends Mock implements GetBrainDump {}

class MockCaptureThought extends Mock implements CaptureThought {}

class MockFileThought extends Mock implements FileThought {}

class MockConvertThought extends Mock implements ConvertThought {}

class MockDeleteThought extends Mock implements DeleteThought {}

class MockGetStats extends Mock implements GetStats {}

// Renombrar y borrar (028).
class MockRenameTask extends Mock implements rm.RenameTask {}

class MockDeleteTask extends Mock implements dm.DeleteTask {}

class MockRenameHabit extends Mock implements rh.RenameHabit {}

class MockDeleteHabit extends Mock implements dh.DeleteHabit {}

// Avisos (029).
class MockGetNotifications extends Mock implements GetNotifications {}

class MockMarkNotificationsRead extends Mock implements MarkNotificationsRead {}
