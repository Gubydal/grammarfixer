import 'package:app_starter/features/auth/domain/entities/app_user.dart';
import 'package:app_starter/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:app_starter/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repo.dart';

void main() {
  test('login success emits Authenticated', () async {
    final repo = FakeAuthRepo()
      ..currentUser = AppUser(uid: '1', email: 'user@example.com');
    final cubit = AuthCubit(authRepo: repo);

    await cubit.login('user@example.com', 'password');

    expect(cubit.state, isA<Authenticated>());
    expect((cubit.state as Authenticated).user.email, 'user@example.com');
  });

  test('login failure emits error and returns to Unauthenticated', () async {
    final repo = FakeAuthRepo()..failLogin = true;
    final cubit = AuthCubit(authRepo: repo);

    await cubit.login('user@example.com', 'wrong');

    expect(cubit.state, isA<Unauthenticated>());
  });

  test('updatePassword delegates to the repo', () async {
    final repo = FakeAuthRepo();
    final cubit = AuthCubit(authRepo: repo);

    await cubit.updatePassword('new-password');

    expect(repo.updatedPassword, 'new-password');
  });
}
