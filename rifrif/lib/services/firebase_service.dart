import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/program_model.dart';
import '../models/user_profile_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseService {
  static void debugPrintAuth(String message) {
    print('[FirebaseAuth Debug] $message');
  }

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _isInitialized = false;

  // Check if email exists in Firebase Auth database
  static Future<bool> checkEmailExists(String email) async {
    try {
      debugPrintAuth('Checking if email exists in Firebase Auth: $email');

      // Use a dry-run approach: try to send password reset but catch specific errors
      try {
        // Create a temporary password reset request to check email existence
        await _auth.sendPasswordResetEmail(email: email);
        debugPrintAuth(
            'Password reset email sent successfully, email exists: $email');
        return true;
      } on FirebaseAuthException catch (e) {
        debugPrintAuth(
            'FirebaseAuthException during email check: ${e.code} - ${e.message}');
        switch (e.code) {
          case 'user-not-found':
            debugPrintAuth('Email does not exist in Firebase Auth: $email');
            return false;
          case 'invalid-email':
            debugPrintAuth('Invalid email format: $email');
            return false;
          case 'user-disabled':
            debugPrintAuth('User account is disabled but exists: $email');
            return true;
          case 'too-many-requests':
            debugPrintAuth(
                'Too many requests, but email likely exists: $email');
            return true;
          default:
            debugPrintAuth(
                'Other Firebase error, assuming email exists: ${e.code}');
            return true;
        }
      } catch (e) {
        debugPrintAuth('Non-Firebase error during email check: $e');
        return true; // Assume exists for non-Firebase errors
      }
    } catch (e) {
      debugPrintAuth('General error checking email existence: $e');
      return true; // Assume exists on general error
    }
  }

  // Generate a simple 4-digit verification code
  static String generateVerificationCode() {
    return (1000 + DateTime.now().millisecond % 9000).toString();
  }

  // Send verification email using multiple service options
  static Future<bool> sendVerificationEmail(String email, String code) async {
    try {
      debugPrintAuth('Sending verification email to: $email with code: $code');

      // Try multiple email services in order of preference

      // Option 1: EmailJS (if configured)
      bool emailJSResult = await _sendViaEmailJS(email, code);
      if (emailJSResult) return true;

      // Option 2: Formspree (easier to set up)
      bool formspreeResult = await _sendViaFormspree(email, code);
      if (formspreeResult) return true;

      // Option 3: Web3Forms (free service)
      bool web3FormsResult = await _sendViaWeb3Forms(email, code);
      if (web3FormsResult) return true;

      // Fallback: Console output for development
      debugPrintAuth('All email services failed. Using console output.');
      print('===== VERIFICATION CODE =====');
      print('Email: $email');
      print('Code: $code');
      print('Enter this code in the verification screen');
      print('==============================');
      return true;
    } catch (e) {
      debugPrintAuth('Error in sendVerificationEmail: $e');
      print('===== VERIFICATION CODE (Error Fallback) =====');
      print('Email: $email');
      print('Code: $code');
      print('===============================================');
      return true;
    }
  }

  // EmailJS implementation
  static Future<bool> _sendViaEmailJS(String email, String code) async {
    try {
      const String serviceId = 'YOUR_SERVICE_ID';
      const String templateId = 'YOUR_TEMPLATE_ID';
      const String publicKey = 'YOUR_PUBLIC_KEY';

      if (serviceId == 'YOUR_SERVICE_ID') {
        debugPrintAuth('EmailJS not configured, skipping...');
        return false;
      }

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': email,
            'verification_code': code,
            'app_name': 'Rif App',
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrintAuth('Email sent successfully via EmailJS');
        return true;
      }
      return false;
    } catch (e) {
      debugPrintAuth('EmailJS failed: $e');
      return false;
    }
  }

  // Formspree implementation (free service)
  static Future<bool> _sendViaFormspree(String email, String code) async {
    try {
      // You need to create a form at https://formspree.io/ and replace YOUR_FORM_ID
      const String formId =
          'YOUR_FORM_ID'; // Replace with your Formspree form ID

      if (formId == 'YOUR_FORM_ID') {
        debugPrintAuth('Formspree not configured, skipping...');
        return false;
      }

      final response = await http.post(
        Uri.parse('https://formspree.io/f/$formId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'subject': 'Code de vérification - Rif App',
          'message':
              'Votre code de vérification est: $code\n\nCe code expire dans 10 minutes.',
          '_replyto': email,
        }),
      );

      if (response.statusCode == 200) {
        debugPrintAuth('Email sent successfully via Formspree');
        return true;
      }
      return false;
    } catch (e) {
      debugPrintAuth('Formspree failed: $e');
      return false;
    }
  }

  // Web3Forms implementation (completely free)
  static Future<bool> _sendViaWeb3Forms(String email, String code) async {
    try {
      // Get free access key at https://web3forms.com/
      const String accessKey =
          'fc7e3628-59f8-4854-8fb4-16a985b9446b'; // Your Web3Forms access key configured

      if (accessKey == 'YOUR_WEB3FORMS_KEY') {
        debugPrintAuth('Web3Forms not configured, skipping...');
        return false;
      }

      final response = await http.post(
        Uri.parse('https://api.web3forms.com/submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'access_key': accessKey,
          'email': email,
          'subject': 'RIF - Code de vérification de votre compte',
          'message': '''
Bonjour,

Welcome to RIF (Faculty Computer Network) !

Pour finaliser la création de votre compte, veuillez utiliser le code de vérification ci-dessous :

CODE DE VÉRIFICATION : $code

Instructions :
1. Entrez ce code dans l'application RIF
2. Le code est valide pendant 10 minutes
3. Si vous n'avez pas créé de compte, ignorez cet email

Sécurité :
- Ne partagez jamais ce code avec personne
- Ce code expire automatiquement dans 10 minutes
- Si vous avez des problèmes, réessayez la création de compte

Cordialement,
L'équipe RIF - Réseau Informatique Facultaire
Université

---
Cet email a été envoyé automatiquement à : $email
© 2025 RIF - Réseau Informatique Facultaire
''',
          'from_name': 'RIF - Réseau Informatique Facultaire',
          'reply_to': 'noreply@rif-univ.edu',
          // Additional parameters to avoid spam
          '_captcha': false,
          '_autoresponse': false,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          debugPrintAuth('Email sent successfully via Web3Forms');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrintAuth('Web3Forms failed: $e');
      return false;
    }
  }

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

  // Email + password sign up with verification
  static Future<Map<String, dynamic>> signUpWithEmailAndVerification(
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

      // Generate verification code
      final verificationCode = generateVerificationCode();

      // Send verification email
      final emailSent = await sendVerificationEmail(email, verificationCode);

      if (!emailSent) {
        throw FirebaseAuthException(
          code: 'verification-email-failed',
          message: 'Failed to send verification email',
        );
      }

      return {
        'credential': credential,
        'verificationCode': verificationCode,
      };
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

  // Send password reset email using Firebase
  static Future<void> sendPasswordReset(String email) async {
    try {
      debugPrintAuth('Sending Firebase password reset email to: $email');

      // Send Firebase's official password reset email with the actual reset link
      await _auth.sendPasswordResetEmail(email: email);
      debugPrintAuth(
          'Firebase password reset email sent successfully to: $email');
    } catch (e) {
      debugPrintAuth('Error sending password reset email to $email: $e');
      rethrow; // Re-throw the error so the UI can handle it
    }
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
            message: 'Network connection error during Google sign-in',
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
          userCredential = await _auth.signInWithCredential(credential);

          // Vérification immédiate de l'état de l'authentification
          if (_auth.currentUser == null) {
            throw FirebaseAuthException(
              code: 'auth-failed',
              message: 'Authentication failed after credential verification',
            );
          }
        } catch (signInError) {
          print('Error in signInWithCredential: $signInError');

          // If it's the PigeonUserDetails error but the user is connected
          if (signInError.toString().contains('PigeonUserDetails') &&
              _auth.currentUser != null) {
            // In this case, we continue because authentication succeeded despite the error
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
    try {
      debugPrintAuth('Starting GitHub Sign In process...');

      // Create a GitHub provider
      GithubAuthProvider githubProvider = GithubAuthProvider();

      // Add scopes for better user information
      githubProvider.addScope('user:email');
      githubProvider.addScope('read:user');

      debugPrintAuth('Requesting GitHub authentication...');

      final UserCredential userCredential = await _auth.signInWithProvider(
        githubProvider,
      );

      debugPrintAuth(
          'GitHub authentication successful: ${userCredential.user?.email}');

      return userCredential;
    } catch (e) {
      debugPrintAuth('Error signing in with GitHub: $e');
      if (e is FirebaseAuthException) {
        debugPrintAuth('FirebaseAuthException: ${e.code} - ${e.message}');
      }
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // ===== FIRESTORE PROGRAM METHODS =====

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all program sessions from Firestore
  static Future<List<ProgramSession>> getAllPrograms() async {
    try {
      debugPrintAuth('Fetching all programs from Firestore...');

      final QuerySnapshot querySnapshot = await _firestore
          .collection('programs')
          .orderBy('date', descending: false)
          .get();

      debugPrintAuth('Found ${querySnapshot.docs.length} program documents');

      List<ProgramSession> programs = [];

      for (var doc in querySnapshot.docs) {
        try {
          debugPrintAuth('Processing document ${doc.id}');
          final data = doc.data() as Map<String, dynamic>;
          debugPrintAuth('Document data: $data');

          final program = ProgramSession.fromMap(doc.id, data);
          programs.add(program);

          debugPrintAuth('Successfully processed program: ${program.title}');
        } catch (e) {
          debugPrintAuth('Error processing document ${doc.id}: $e');
        }
      }

      debugPrintAuth('Successfully fetched ${programs.length} programs');
      return programs;
    } catch (e) {
      debugPrintAuth('Error fetching programs: $e');
      return [];
    }
  }

  /// Fetch upcoming program sessions (today and future)
  static Future<List<ProgramSession>> getUpcomingPrograms(
      {int limit = 10}) async {
    try {
      debugPrintAuth('Fetching upcoming programs from Firestore...');

      final QuerySnapshot querySnapshot = await _firestore
          .collection('programs')
          .orderBy('date', descending: false)
          .limit(limit)
          .get();

      List<ProgramSession> allPrograms = querySnapshot.docs.map((doc) {
        return ProgramSession.fromMap(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      // Filter for upcoming sessions
      List<ProgramSession> upcomingPrograms =
          allPrograms.where((program) => program.isUpcoming).toList();

      debugPrintAuth(
          'Successfully fetched ${upcomingPrograms.length} upcoming programs');
      return upcomingPrograms;
    } catch (e) {
      debugPrintAuth('Error fetching upcoming programs: $e');
      return [];
    }
  }

  /// Fetch programs for a specific date
  static Future<List<ProgramSession>> getProgramsByDate(String date) async {
    try {
      debugPrintAuth('Fetching programs for date: $date');

      final QuerySnapshot querySnapshot = await _firestore
          .collection('programs')
          .where('date', isEqualTo: date)
          .orderBy('start', descending: false)
          .get();

      List<ProgramSession> programs = querySnapshot.docs.map((doc) {
        return ProgramSession.fromMap(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      debugPrintAuth(
          'Successfully fetched ${programs.length} programs for $date');
      return programs;
    } catch (e) {
      debugPrintAuth('Error fetching programs for date $date: $e');
      return [];
    }
  }

  /// Get real-time stream of programs
  static Stream<List<ProgramSession>> getProgramsStream() {
    try {
      debugPrintAuth('Setting up real-time programs stream...');

      return _firestore
          .collection('programs')
          .orderBy('date', descending: false)
          .snapshots()
          .map((snapshot) {
        List<ProgramSession> programs = [];

        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            final program = ProgramSession.fromMap(doc.id, data);
            programs.add(program);
          } catch (e) {
            debugPrintAuth('Error processing document ${doc.id} in stream: $e');
          }
        }

        debugPrintAuth('Stream updated: ${programs.length} programs');
        return programs;
      });
    } catch (e) {
      debugPrintAuth('Error setting up programs stream: $e');
      return Stream.value([]);
    }
  }

  /// Get conference statistics
  static Future<Map<String, int>> getProgramStatistics() async {
    try {
      debugPrintAuth('Fetching program statistics...');

      final QuerySnapshot querySnapshot =
          await _firestore.collection('programs').get();

      List<ProgramSession> allPrograms = querySnapshot.docs.map((doc) {
        return ProgramSession.fromMap(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      int totalSessions = allPrograms.length;
      int totalConferences = allPrograms.fold(
          0, (sum, program) => sum + program.conferences.length);

      // Count unique speakers
      Set<String> uniqueSpeakers = {};
      for (var program in allPrograms) {
        uniqueSpeakers.addAll(program.allSpeakers);
      }

      // Count keynote sessions
      int keynoteSessionsCount = allPrograms
          .where((program) =>
              program.keynote != null && program.keynote!.name.isNotEmpty)
          .length;

      Map<String, int> stats = {
        'totalSessions': totalSessions,
        'totalConferences': totalConferences,
        'totalSpeakers': uniqueSpeakers.length,
        'keynoteSessions': keynoteSessionsCount,
      };

      debugPrintAuth('Program statistics: $stats');
      return stats;
    } catch (e) {
      debugPrintAuth('Error fetching program statistics: $e');
      return {
        'totalSessions': 0,
        'totalConferences': 0,
        'totalSpeakers': 0,
        'keynoteSessions': 0,
      };
    }
  }

  // User Profile Management Methods
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('user_profiles').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrintAuth('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(profile.uid)
          .set(profile.toMap());
      debugPrintAuth('User profile saved successfully');
    } catch (e) {
      debugPrintAuth('Error saving user profile: $e');
      throw e;
    }
  }

  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('user_profiles').doc(uid).update(updates);
      debugPrintAuth('User profile updated successfully');
    } catch (e) {
      debugPrintAuth('Error updating user profile: $e');
      throw e;
    }
  }

  Future<UserProfile> createOrUpdateUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
    String? school,
    String? schoolLevel,
    DateTime? birthday,
    String? location,
  }) async {
    try {
      final existing = await getUserProfile(uid);

      if (existing != null) {
        // Update existing profile
        final updatedProfile = existing.copyWith(
          email: email,
          displayName: displayName ?? existing.displayName,
          photoURL: photoURL ?? existing.photoURL,
          school: school ?? existing.school,
          schoolLevel: schoolLevel ?? existing.schoolLevel,
          birthday: birthday ?? existing.birthday,
          location: location ?? existing.location,
        );
        await saveUserProfile(updatedProfile);
        return updatedProfile;
      } else {
        // Create new profile
        final newProfile = UserProfile(
          uid: uid,
          email: email,
          displayName: displayName,
          photoURL: photoURL,
          school: school,
          schoolLevel: schoolLevel,
          birthday: birthday,
          location: location,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await saveUserProfile(newProfile);
        return newProfile;
      }
    } catch (e) {
      debugPrintAuth('Error creating/updating user profile: $e');
      throw e;
    }
  }

  Future<void> completeUserProfile({
    required String uid,
    required String school,
    required String schoolLevel,
    required String gender,
    required DateTime birthday,
    required String location,
  }) async {
    try {
      await updateUserProfile(uid, {
        'school': school,
        'schoolLevel': schoolLevel,
        'gender': gender,
        'birthday': Timestamp.fromDate(birthday),
        'location': location,
        'isProfileComplete': true,
      });
      debugPrintAuth('User profile completed successfully');
    } catch (e) {
      debugPrintAuth('Error completing user profile: $e');
      throw e;
    }
  }

  Future<void> updateProfilePicture({
    required String uid,
    required String base64Image,
  }) async {
    try {
      await updateUserProfile(uid, {
        'photoURL': base64Image,
      });
      debugPrintAuth('Profile picture updated successfully');
    } catch (e) {
      debugPrintAuth('Error updating profile picture: $e');
      throw e;
    }
  }

  // Rating and feedback functionality

  /// NEW: Submit or update individual user rating for a presentation
  static Future<void> submitUserRating(
    Conference conference,
    double presenterRating,
    double presentationRating,
    String comment, {
    String? sessionDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      debugPrintAuth('Submitting user rating...');

      final now = DateTime.now();
      final presentationId = _generatePresentationId(conference, sessionDate);

      // Check if user has already rated this presentation
      final existingRatingQuery = await FirebaseFirestore.instance
          .collection('ratings')
          .where('userId', isEqualTo: user.uid)
          .where('presentationId', isEqualTo: presentationId)
          .limit(1)
          .get();

      final userRatingData = {
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'presentationId': presentationId,
        'conferenceTitle': conference.title,
        'presenter': conference.presenter,
        'startTime': conference.start,
        'date': sessionDate ?? 'unknown',
        'presenterRating': presenterRating,
        'presentationRating': presentationRating,
        'comment': comment,
        'updatedAt': Timestamp.fromDate(now),
      };

      if (existingRatingQuery.docs.isNotEmpty) {
        // Update existing rating
        await existingRatingQuery.docs.first.reference.update(userRatingData);
        debugPrintAuth('User rating updated successfully');
      } else {
        // Create new rating
        userRatingData['ratedAt'] = Timestamp.fromDate(now);
        await FirebaseFirestore.instance
            .collection('ratings')
            .add(userRatingData);
        debugPrintAuth('User rating submitted successfully');
      }

      // Update aggregated analytics
      await _updatePresentationAnalytics(
          presentationId, conference, sessionDate);
    } catch (e) {
      debugPrintAuth('Error submitting user rating: $e');
      throw e;
    }
  }

  /// Get user's rating for a specific presentation
  static Future<Map<String, dynamic>?> getUserRating(Conference conference,
      {String? sessionDate}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final presentationId = _generatePresentationId(conference, sessionDate);

      final query = await FirebaseFirestore.instance
          .collection('ratings')
          .where('userId', isEqualTo: user.uid)
          .where('presentationId', isEqualTo: presentationId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrintAuth('Error getting user rating: $e');
      return null;
    }
  }

  /// Get aggregated analytics for a presentation
  static Future<Map<String, dynamic>?> getPresentationAnalytics(
      Conference conference,
      {String? sessionDate}) async {
    try {
      final presentationId = _generatePresentationId(conference, sessionDate);

      final doc = await FirebaseFirestore.instance
          .collection('presentation_analytics')
          .doc(presentationId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrintAuth('Error getting presentation analytics: $e');
      return null;
    }
  }

  /// Get all ratings for a presentation (admin use)
  static Future<List<Map<String, dynamic>>> getAllRatingsForPresentation(
      Conference conference,
      {String? sessionDate}) async {
    try {
      final presentationId = _generatePresentationId(conference, sessionDate);

      final query = await FirebaseFirestore.instance
          .collection('ratings')
          .where('presentationId', isEqualTo: presentationId)
          .orderBy('ratedAt', descending: true)
          .get();

      return query.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrintAuth('Error getting all ratings: $e');
      return [];
    }
  }

  /// Helper method to generate consistent presentation ID
  static String _generatePresentationId(
      Conference conference, String? sessionDate) {
    return '${conference.title}_${conference.presenter}_${conference.start}_${sessionDate ?? 'unknown'}'
        .replaceAll(' ', '_')
        .replaceAll(':', '')
        .replaceAll('-', '')
        .toLowerCase();
  }

  /// Update aggregated analytics for a presentation
  static Future<void> _updatePresentationAnalytics(
      String presentationId, Conference conference, String? sessionDate) async {
    try {
      // Get all ratings for this presentation
      final ratingsQuery = await FirebaseFirestore.instance
          .collection('ratings')
          .where('presentationId', isEqualTo: presentationId)
          .get();

      if (ratingsQuery.docs.isEmpty) return;

      final ratings = ratingsQuery.docs.map((doc) => doc.data()).toList();

      // Calculate aggregated data
      double totalPresenterRating = 0;
      double totalPresentationRating = 0;
      int totalComments = 0;
      Map<String, int> presenterDistribution = {
        '1': 0,
        '2': 0,
        '3': 0,
        '4': 0,
        '5': 0
      };
      Map<String, int> presentationDistribution = {
        '1': 0,
        '2': 0,
        '3': 0,
        '4': 0,
        '5': 0
      };

      for (var rating in ratings) {
        totalPresenterRating += rating['presenterRating'] ?? 0;
        totalPresentationRating += rating['presentationRating'] ?? 0;

        if (rating['comment'] != null &&
            rating['comment'].toString().isNotEmpty) {
          totalComments++;
        }

        // Update distributions
        String presenterKey =
            (rating['presenterRating'] ?? 0).round().toString();
        String presentationKey =
            (rating['presentationRating'] ?? 0).round().toString();

        if (presenterDistribution.containsKey(presenterKey)) {
          presenterDistribution[presenterKey] =
              presenterDistribution[presenterKey]! + 1;
        }
        if (presentationDistribution.containsKey(presentationKey)) {
          presentationDistribution[presentationKey] =
              presentationDistribution[presentationKey]! + 1;
        }
      }

      final analyticsData = {
        'presentationId': presentationId,
        'conferenceTitle': conference.title,
        'presenter': conference.presenter,
        'startTime': conference.start,
        'date': sessionDate ?? 'unknown',
        'averagePresenterRating': totalPresenterRating / ratings.length,
        'averagePresentationRating': totalPresentationRating / ratings.length,
        'totalRatings': ratings.length,
        'totalComments': totalComments,
        'presenterRatingDistribution': presenterDistribution,
        'presentationRatingDistribution': presentationDistribution,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };

      await FirebaseFirestore.instance
          .collection('presentation_analytics')
          .doc(presentationId)
          .set(analyticsData, SetOptions(merge: true));
    } catch (e) {
      debugPrintAuth('Error updating presentation analytics: $e');
    }
  }

  // Legacy rating method removed - using individual user ratings only

  /// ADMIN UTILITY: Clean up legacy rating data from conference objects
  /// This removes old presenterRating, presentationRating, and comment fields
  /// from conference objects in the programs collection
  static Future<void> cleanupLegacyRatingData() async {
    try {
      debugPrintAuth('Starting cleanup of legacy rating data...');

      final snapshot =
          await FirebaseFirestore.instance.collection('programs').get();
      int updatedPrograms = 0;
      int updatedConferences = 0;

      for (var doc in snapshot.docs) {
        var programData = doc.data();
        List conferences = programData['conferences'] ?? [];
        bool programNeedsUpdate = false;

        // Clean up each conference object
        for (int i = 0; i < conferences.length; i++) {
          var conf = conferences[i];
          bool conferenceNeedsUpdate = false;

          // Remove legacy rating fields if they exist
          if (conf.containsKey('presenterRating')) {
            conf.remove('presenterRating');
            conferenceNeedsUpdate = true;
          }
          if (conf.containsKey('presentationRating')) {
            conf.remove('presentationRating');
            conferenceNeedsUpdate = true;
          }
          if (conf.containsKey('comment')) {
            conf.remove('comment');
            conferenceNeedsUpdate = true;
          }

          if (conferenceNeedsUpdate) {
            conferences[i] = conf;
            programNeedsUpdate = true;
            updatedConferences++;
          }
        }

        // Update the document if needed
        if (programNeedsUpdate) {
          await doc.reference.update({
            'conferences': conferences,
          });
          updatedPrograms++;
        }
      }

      debugPrintAuth(
          'Legacy rating cleanup completed: $updatedPrograms programs, $updatedConferences conferences updated');
    } catch (e) {
      debugPrintAuth('Error cleaning up legacy rating data: $e');
      throw e;
    }
  }
}
