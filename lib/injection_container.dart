import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:proyecto_movil/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/get_current_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/login_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/logout_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/register_user.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';

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
}
