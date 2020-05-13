import 'package:bloc/bloc.dart';

import 'auth_service.dart';

class AuthState {}

class UnresolvedState extends AuthState {}

class LoadingState extends AuthState {}

class UnauthenticatedState extends AuthState {}

class AuthenticatedState extends AuthState {
  User user;

  AuthenticatedState(this.user);
}

class AuthEvent {}

class RestoreAuthEvent extends AuthEvent {}

class SignInEvent extends AuthEvent {
  Credentials credentials;
  SignInEvent(this.credentials);
}

class SignOutEvent extends AuthEvent {}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService);

  @override
  AuthState get initialState => UnresolvedState();

  @override
  Stream<AuthState> mapEventToState(AuthEvent event) async* {
    switch (event.runtimeType) {
      case RestoreAuthEvent:
        yield LoadingState();
        yield await restoreAuth();
        break;

      case SignInEvent:
        yield LoadingState();
        yield await signIn((event as SignInEvent).credentials);
        break;

      case SignOutEvent:
        await authService.signOut();
        yield UnauthenticatedState();
        break;
    }
  }

  Future<AuthState> restoreAuth() async {
    final user = await authService.readAuthFromStorage();
    return _resolveStateFromUser(user);
  }

  Future<AuthState> signIn(Credentials credentials) async {
    final user = await authService.signIn(credentials);
    return _resolveStateFromUser(user);
  }

  AuthState _resolveStateFromUser(User user) {
    if (user == null) {
      return UnauthenticatedState();
    } else {
      return AuthenticatedState(user);
    }
  }
}
