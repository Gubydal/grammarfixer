import 'package:app_starter/features/auth/domain/entities/app_user.dart';
import 'package:app_starter/features/auth/domain/repos/auth_repo.dart';

class FakeAuthRepo implements AuthRepo {
  AppUser? currentUser;
  bool failLogin = false;
  String? updatedPassword;

  @override
  Future<AppUser?> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    if (failLogin) throw Exception('Login failed');
    return currentUser;
  }

  @override
  Future<AppUser?> registerWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    return currentUser;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AppUser?> getCurrentUser() async => currentUser;

  @override
  Future<String> sendPasswordResetEmail(String email) async {
    return 'Password reset email sent! Check your inbox';
  }

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<AppUser?> signInWithGoogle() async => currentUser;

  @override
  Future<void> updatePassword(String newPassword) async {
    updatedPassword = newPassword;
  }
}
