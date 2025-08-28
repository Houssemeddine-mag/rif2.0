import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/auth_fix.dart';

class FirebaseService {
  static void debugPrintAuth(String message) {
    print('[FirebaseAuth Debug] $message');
  }

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _isInitialized = false;

  static void initialize() {
    if (!_isInitialized) {
      debugPrintAuth('Initializing Firebase Authentication Service');
      _auth.authStateChanges().listen((User? user) {
        if (user == null) {
          debugPrintAuth('Auth State Changed: User is signed out');
        } else {
          debugPrintAuth('Auth State Changed: User is signed in');
          debugPrintAuth('User email: ${user.email}');
          debugPrintAuth('Email verified: ${user.emailVerified}');
          debugPrintAuth('User ID: ${user.uid}');
          debugPrintAuth(
              'Provider IDs: ${user.providerData.map((e) => e.providerId).join(', ')}');
        }
      });
      _isInitialized = true;
    }
  }

  static User? get currentUser {
    final user = _auth.currentUser;
    debugPrintAuth(
        'Current user check - Email: ${user?.email ?? 'null'}, UID: ${user?.uid ?? 'null'}');
    return user;
  }

  static UserModel? get currentUserModel {
    final user = _auth.currentUser;
    if (user != null) {
      return UserModel.fromFirebaseUser(user);
    }
    return null;
  }

  // Email + password sign up
  static Future<UserCredential> signUpWithEmail(
    String email,
    String password,
  ) async {
    debugPrintAuth('Attempting to create account with email: $email');
    try {
      if (email.isEmpty || password.isEmpty) {
        debugPrintAuth('Email or password is empty');
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email and password cannot be empty',
        );
      }

      if (password.length < 6) {
        debugPrintAuth('Password is too short');
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password should be at least 6 characters',
        );
      }

      debugPrintAuth('Calling Firebase createUserWithEmailAndPassword');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrintAuth('Successfully created account: ${credential.user?.email}');
      return credential;
    } catch (e) {
      debugPrintAuth('Error creating account: $e');
      if (e is FirebaseAuthException) {
        rethrow;
      }
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Email + password sign in
  static Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    debugPrintAuth('Attempting to sign in with email: $email');
    try {
      if (email.isEmpty || password.isEmpty) {
        debugPrintAuth('Email or password is empty');
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email and password cannot be empty',
        );
      }

      debugPrintAuth('Calling Firebase signInWithEmailAndPassword');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrintAuth(
          'Successfully signed in with email: ${credential.user?.email}');
      return credential;
    } catch (e) {
      debugPrintAuth('Error signing in with email: $e');
      if (e is FirebaseAuthException) {
        rethrow;
      }
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Send password reset email
  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Google Sign-In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign In process...');

      // Initialize GoogleSignIn with proper scopes and configuration
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          'openid',
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ],
        signInOption: SignInOption.standard,
      );

      // Check if already signed in and sign out
      print('Checking current sign in status...');
      try {
        final currentUser = googleSignIn.currentUser;
        if (currentUser != null) {
          print(
              'User already signed in, signing out first: ${currentUser.email}');
          await googleSignIn.signOut();
          await FirebaseAuth.instance.signOut();
        }
      } catch (e) {
        print('Error checking/signing out current user: $e');
      }

      // Begin interactive sign in process
      print('Requesting Google Sign In...');
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
        print('Sign in dialog completed');
      } catch (e) {
        print('Error during Google signIn() call: $e');
        if (e.toString().contains('network_error')) {
          throw FirebaseAuthException(
            code: 'network_error',
            message: 'Erreur de connexion réseau lors de la connexion Google',
          );
        }
        rethrow;
      }

      if (googleUser == null) {
        print('Google Sign In was aborted by user (null user)');
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      print('Got Google Sign In account: ${googleUser.email}');

      // Obtain auth details from request
      print('Getting Google auth details...');
      final GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        print('Got authentication details');
      } catch (e) {
        print('Error getting authentication details: $e');
        throw FirebaseAuthException(
          code: 'ERROR_AUTHENTICATION_DETAILS',
          message: 'Failed to get authentication details from Google',
        );
      }

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Failed to get Google auth tokens');
        throw FirebaseAuthException(
          code: 'ERROR_MISSING_GOOGLE_AUTH_TOKEN',
          message: 'Missing Google Auth Token',
        );
      }

      // Create new credential for Firebase
      print('Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      print('Signing in to Firebase with credential...');
      try {
        // Utilisation de signInWithCredential avec gestion spécifique pour Pigeon
        UserCredential? userCredential;
        try {
          final tempCred = await _auth.signInWithCredential(credential);
          userCredential = tempCred.safe;

          // Vérification immédiate de l'état de l'authentification
          if (_auth.currentUser == null) {
            throw FirebaseAuthException(
              code: 'auth-failed',
              message: 'Authentication failed after credential verification',
            );
          }
        } catch (signInError) {
          print('Error in signInWithCredential: $signInError');

          // Si c'est l'erreur PigeonUserDetails mais que l'utilisateur est connecté
          if (signInError.toString().contains('PigeonUserDetails') &&
              _auth.currentUser != null) {
            // Dans ce cas, on continue car l'authentification a réussi malgré l'erreur
            print(
                'Continuing despite PigeonUserDetails error - user is authenticated');
            return await _auth.signInWithCredential(credential);
          }

          throw FirebaseAuthException(
            code: 'ERROR_FIREBASE_SIGNIN',
            message: 'Error signing in with Firebase: $signInError',
          );
        }

        if (userCredential.user == null) {
          throw FirebaseAuthException(
            code: 'ERROR_NULL_USER',
            message: 'Firebase sign in succeeded but user is null',
          );
        }

        // Vérification supplémentaire des données utilisateur
        final user = userCredential.user!;
        if (user.email == null || user.email!.isEmpty) {
          throw FirebaseAuthException(
            code: 'ERROR_INVALID_USER_DATA',
            message: 'User email is missing',
          );
        }

        print('Successfully signed in with Google: ${user.email}');

        // Validation directe des données utilisateur au lieu de créer le modèle immédiatement
        if (!user.emailVerified) {
          print('Warning: Email not verified for user ${user.email}');
        }

        return userCredential;
      } catch (e) {
        print('Error signing in with credential: $e');
        if (e is FirebaseAuthException) {
          rethrow;
        }
        throw FirebaseAuthException(
          code: 'ERROR_FIREBASE_SIGNIN',
          message: 'Error signing in with Firebase: ${e.toString()}',
        );
      }
    } catch (e) {
      print('Error during Google sign in: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // GitHub Sign-In
  static Future<UserCredential> signInWithGithub() async {
    // Create a GitHub provider
    GithubAuthProvider githubProvider = GithubAuthProvider();

    try {
      final UserCredential userCredential = await _auth.signInWithProvider(
        githubProvider,
      );
      return userCredential;
    } catch (e) {
      print('Error signing in with GitHub: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
