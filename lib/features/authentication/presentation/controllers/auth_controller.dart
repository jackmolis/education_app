import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_auth_repository.dart';
import '../../domain/auth_repository.dart';

/// Simple Auth service to abstract away calling the repository.
class AuthService {
  final AuthRepository _authRepository;

  AuthService(this._authRepository);

  /// Attempts to sign in the user.
  Future<void> signIn(String email, String password) async {
    await _authRepository.signInWithEmailAndPassword(email, password);
  }

  /// Attempts to register the user.
  Future<void> register(String email, String password) async {
    await _authRepository.registerWithEmailAndPassword(email, password);
  }

  /// Signs out the user.
  Future<void> signOut() async {
    await _authRepository.signOut();
  }
}

/// Provider exposing the AuthService logic to UI.
final authControllerProvider = Provider.autoDispose<AuthService>((ref) {
  return AuthService(ref.watch(authRepositoryProvider));
});
