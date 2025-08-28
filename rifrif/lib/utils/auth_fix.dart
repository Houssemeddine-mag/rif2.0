import 'package:firebase_auth/firebase_auth.dart';

extension UserCredentialExt on UserCredential {
  UserCredential get safe => this;
}

extension UserExt on User {
  User get safe => this;
}
