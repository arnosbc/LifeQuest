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
import 'package:proyecto_movil/features/home/data/datasources/home_remote_datasource.dart';
import 'package:proyecto_movil/features/home/data/repositories/home_repository_impl.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';
import 'package:proyecto_movil/features/home/domain/usecases/complete_habit.dart';
import 'package:proyecto_movil/features/home/domain/usecases/get_home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
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
