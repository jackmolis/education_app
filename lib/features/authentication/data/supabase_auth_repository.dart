import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_repository.dart';

/// Provider exposing the SupabaseClient instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider exposing the implementation of the AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

/// Provider exposing the authentication state stream.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Data layer implementation of the AuthRepository using Supabase.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabaseClient;

  SupabaseAuthRepository(this._supabaseClient);

  @override
  Stream<User?> get authStateChanges => _supabaseClient.auth.onAuthStateChange.map((event) => event.session?.user);

  @override
  User? get currentUser => _supabaseClient.auth.currentUser;

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final authResponse = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return authResponse.user;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  @override
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      final authResponse = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      return authResponse.user;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }
}
