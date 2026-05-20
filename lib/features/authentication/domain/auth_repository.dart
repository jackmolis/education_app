import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  /// Stream reporting the current authentication state.
  Stream<User?> get authStateChanges;

  /// Returns the current authenticated user, or null if unauthenticated.
  User? get currentUser;

  /// Signs in a user with an email and password.
  Future<User?> signInWithEmailAndPassword(String email, String password);

  /// Registers a new user with an email and password.
  Future<User?> registerWithEmailAndPassword(String email, String password);

  /// Signs out the current user.
  Future<void> signOut();
}
