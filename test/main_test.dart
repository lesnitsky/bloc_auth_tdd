import 'package:bloc_auth_tdd/auth_bloc.dart';
import 'package:bloc_auth_tdd/auth_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {}

final mockUser = User('42', 'testuser');
final mockCorrectCredentials = Credentials('username', 'password');

Matcher isAuthenticatedState(User user) {
  return const TypeMatcher<AuthenticatedState>()
      .having((state) => state.user, 'user', user);
}

void main() {
  AuthBloc bloc;
  AuthService authService;

  // setUp is called before each unit test
  setUp(() {
    authService = MockAuthService();
    bloc = AuthBloc(authService);
  });

  tearDown(() {
    bloc.close();
  });

  group('AuthBloc', () {
    test('has unresolved initial state', () {
      expect(bloc.initialState, isA<UnresolvedState>());
    });

    group('if user was previously authenticated', () {
      blocTest<AuthBloc, AuthEvent, AuthState>(
        'emits LoadingState, then AuthenticatedState when RestoreAuthEvent was added',
        build: () async => bloc,
        act: (bloc) async {
          when(authService.readAuthFromStorage())
              .thenAnswer((_) async => mockUser);
          bloc.add(RestoreAuthEvent());
        },
        expect: [isA<LoadingState>(), isAuthenticatedState(mockUser)],
      );
    });

    group("if user wasn't previously authenticated", () {
      blocTest<AuthBloc, AuthEvent, AuthState>(
        'emits LoadingState, then UnauthenticatedState when RestoreAuthEvent was added',
        build: () async => bloc,
        act: (bloc) async {
          when(authService.readAuthFromStorage()).thenAnswer((_) async => null);
          bloc.add(RestoreAuthEvent());
        },
        expect: [isA<LoadingState>(), isA<UnauthenticatedState>()],
      );
    });

    blocTest<AuthBloc, AuthEvent, AuthState>(
      'emits LoadingState, then AuthenticatedState when SignInEvent was added with correct credentials',
      build: () async => bloc,
      act: (bloc) async {
        when(authService.signIn(mockCorrectCredentials))
            .thenAnswer((_) async => mockUser);

        bloc.add(SignInEvent(mockCorrectCredentials));
      },
      expect: [isA<LoadingState>(), isAuthenticatedState(mockUser)],
    );

    blocTest<AuthBloc, AuthEvent, AuthState>(
      'emits LoadingState, then UnauthenticatedState when SignInEvent was added with wrong credentials',
      build: () async => bloc,
      act: (bloc) async {
        when(authService.signIn(any)).thenAnswer((invocation) async => null);

        when(authService.signIn(mockCorrectCredentials))
            .thenAnswer((invocation) async => mockUser);

        bloc.add(SignInEvent(Credentials('1234', '5678')));
      },
      expect: [isA<LoadingState>(), isA<UnauthenticatedState>()],
    );

    blocTest<AuthBloc, AuthEvent, AuthState>(
      'calls signOut of AuthService and emits UnauthenticatedState when SignOutEvent was added',
      build: () async => bloc,
      act: (bloc) async {
        bloc.add(SignOutEvent());
      },
      verify: (bloc) async {
        final state = bloc.state;
        if (state is UnauthenticatedState) {
          expect(verify(authService.signOut()).callCount, 1);
        }
      },
      expect: [isA<UnauthenticatedState>()],
    );
  });
}
