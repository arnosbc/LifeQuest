import 'package:proyecto_movil/features/auth/models/app_user.dart';
import 'package:proyecto_movil/features/auth/services/auth_service.dart';

/// AuthService en memoria para tests: sin red ni Supabase.
class FakeAuthService implements AuthService {
  FakeAuthService({this.currentUser, this.signUpOutcome, this.failure});

  @override
  AppUser? currentUser;

  /// Resultado del próximo registro (por defecto, entra directo).
  SignUpOutcome? signUpOutcome;

  /// Si no es null, la próxima acción falla con este error.
  AuthFailure? failure;

  int signOutCalls = 0;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (failure != null) throw failure!;
    return AppUser(id: 'u1', email: email);
  }

  @override
  Future<(SignUpOutcome, AppUser)> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    if (failure != null) throw failure!;
    return (
      signUpOutcome ?? SignUpOutcome.signedIn,
      AppUser(id: 'u1', email: email, username: username),
    );
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}
