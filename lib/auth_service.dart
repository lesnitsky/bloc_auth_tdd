class User {
  String id;
  String name;

  User(this.id, this.name);
}

class Credentials {
  String username;
  String password;

  Credentials(this.username, this.password);
}

abstract class AuthService {
  Future<User> readAuthFromStorage();
  Future<User> signIn(Credentials credentials);
  Future<void> signOut();
}
