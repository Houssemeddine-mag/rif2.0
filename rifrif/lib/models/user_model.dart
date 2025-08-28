import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  factory UserModel.fromFirebaseUser(auth.User? user) {
    if (user == null) {
      throw ArgumentError('User cannot be null');
    }
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
    );
  }
}
