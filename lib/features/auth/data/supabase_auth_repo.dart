import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../domain/entities/app_user.dart';
import '../domain/repos/auth_repo.dart';

class SupabaseAuthRepo implements AuthRepo {
  SupabaseAuthRepo(this._client);

  final SupabaseClient _client;

  AppUser _mapUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return AppUser(
      uid: user.id,
      email: user.email ?? '',
      displayName:
          (metadata['display_name'] ??
              metadata['full_name'] ??
              metadata['name']) as String?,
    );
  }

  Future<void> _ensureProfile(AppUser user) async {
    final values = <String, dynamic>{
      'id': user.uid,
      'email': user.email,
    };
    if (user.displayName != null) {
      values['display_name'] = user.displayName;
    }
    await _client
        .schema(AppConfig.supabaseSchema)
        .from('profiles')
        .upsert(values);
  }

  @override
  Future<AppUser?> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = _mapUser(response.user!);
      await _ensureProfile(user);
      return user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<AppUser?> registerWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name},
      );

      if (response.session == null) {
        throw Exception(
          'Check your email to confirm your account before signing in.',
        );
      }

      final user = _mapUser(response.user!);
      await _ensureProfile(user);
      return user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      if (AppConfig.googleWebClientId.isEmpty) {
        throw Exception('GOOGLE_WEB_CLIENT_ID is not configured.');
      }

      final signIn = GoogleSignIn.instance;
      await signIn.initialize(serverClientId: AppConfig.googleWebClientId);
      final googleAccount = await signIn.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null) {
        throw Exception('Google sign-in did not return an ID token.');
      }

      final authorization =
          await googleAccount.authorizationClient.authorizationForScopes(
            const [],
          );

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );

      final user = _mapUser(response.user!);
      await _ensureProfile(user);
      return user;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _mapUser(user);
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  @override
  Future<String> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConfig.deepLinkUri.toString(),
      );
      return 'Password reset email sent! Check your inbox';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Password update failed: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final response = await _client.functions.invoke(
        'delete-account',
        body: {'schema': AppConfig.supabaseSchema},
      );
      if (response.status < 200 || response.status >= 300) {
        throw Exception('Account deletion failed: ${response.data}');
      }
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }
}
