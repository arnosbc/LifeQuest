import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/get_current_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/login_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/logout_user.dart';
import 'package:proyecto_movil/features/auth/domain/usecases/register_user.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockLoginUser extends Mock implements LoginUser {}

class MockRegisterUser extends Mock implements RegisterUser {}

class MockLogoutUser extends Mock implements LogoutUser {}
