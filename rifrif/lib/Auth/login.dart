import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../pages_presenter/presentation.dart';
import 'signup.dart';
import 'recover.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> loginWithEmail() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    // Check for static admin credentials
    if (emailController.text.trim() == 'M_admin@RIF.com' &&
        passwordController.text == 'Di8dibXp') {
      try {
        print('[Login] Static admin login detected');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Admin login successful!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to admin interface
        Navigator.pushReplacementNamed(context, '/admin');
        return;
      } catch (e) {
        print('[Login] Error in admin login: $e');
      } finally {
        setState(() => isLoading = false);
      }
      return;
    }

    // Check for static presenter credentials
    if (emailController.text.trim() == 'Present@RIF.com' &&
        passwordController.text == 'Pr9sentXp') {
      try {
        print('[Login] Static presenter login detected');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Presenter login successful!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to presenter interface directly (bypassing route protection)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PresentationPage()),
        );
        return;
      } catch (e) {
        print('[Login] Error in presenter login: $e');
      } finally {
        setState(() => isLoading = false);
      }
      return;
    }

    try {
      print(
          '[Login] Attempting to sign in with email: ${emailController.text}');

      final credential = await FirebaseService.signInWithEmail(
        emailController.text.trim(),
        passwordController.text,
      );

      print('[Login] Sign in successful');

      if (credential.user != null) {
        try {
          // Create user model
          final userModel = UserModel.fromFirebaseUser(credential.user!);
          print('[Login] User model created: ${userModel.email}');

          // Check if user needs to complete profile
          final shouldRedirectToProfile =
              await FirebaseService.shouldRedirectToProfile(
                  credential.user!.uid);

          if (shouldRedirectToProfile) {
            print('[Login] Redirecting to profile completion');
            Navigator.pushReplacementNamed(context, '/profile');
          } else {
            print('[Login] Redirecting to home');
            Navigator.pushReplacementNamed(context, '/home');
          }
        } catch (e) {
          print('[Login] Error creating user model: $e');
          throw FirebaseAuthException(
            code: 'user-model-error',
            message: 'Error creating user profile',
          );
        }
      } else {
        print('[Login] Credential user is null');
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'No user data received',
        );
      }
    } catch (e) {
      print('[Login] Error: $e');
      String errorMessage = "An error occurred";

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = "No user found with this email";
            break;
          case 'wrong-password':
            errorMessage = "Incorrect password";
            break;
          case 'invalid-email':
            errorMessage = "Invalid email";
            break;
          case 'user-disabled':
            errorMessage = "This account has been disabled";
            break;
          case 'too-many-requests':
            errorMessage = "Too many login attempts. Please try again later";
            break;
          case 'operation-not-allowed':
            errorMessage = "Email/password login is not enabled";
            break;
          case 'network-request-failed':
            errorMessage =
                "Network connection error. Check your internet connection";
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Social login methods
  Future<void> loginWithGoogle() async {
    setState(() => isLoading = true);
    try {
      print('[Login] Starting Google login process...');

      // Pre-check: Verify if user is already signed in with Firebase
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print(
            '[Login] User already signed in with Firebase, signing out first: ${currentUser.email}');
        await FirebaseService.signOut(); // Utilisation de la méthode du service
      }

      print('[Login] Calling FirebaseService.signInWithGoogle()');
      final UserCredential? userCredential =
          await FirebaseService.signInWithGoogle();

      if (userCredential == null) {
        print('[Login] Sign in result is null');
        throw FirebaseAuthException(
          code: 'error-null-result',
          message: 'Login failed',
        );
      }

      final user = userCredential.user;
      if (user == null) {
        print('[Login] User is null after successful sign in');
        throw FirebaseAuthException(
          code: 'error-null-user',
          message: 'Unable to retrieve user information',
        );
      }

      print('[Login] Got valid user: ${user.email}');

      // User model creation
      try {
        final userModel = UserModel.fromFirebaseUser(user);
        print('[Login] Successfully created user model: ${userModel.email}');

        // Check if user needs to complete profile
        final shouldRedirectToProfile =
            await FirebaseService.shouldRedirectToProfile(user.uid);

        if (shouldRedirectToProfile) {
          print('[Login] Google user redirecting to profile completion');
          Navigator.pushReplacementNamed(context, '/profile');
        } else {
          print('[Login] Google user redirecting to home');
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (modelError) {
        print('[Login] Error creating user model: $modelError');
        print('[Login] Stack trace: ${StackTrace.current}');
        throw FirebaseAuthException(
          code: 'error-user-model',
          message: 'Error creating user profile',
        );
      }
    } catch (e) {
      print('[Login] Error in loginWithGoogle: $e');
      String errorMessage = "An error occurred while signing in with Google";

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'ERROR_ABORTED_BY_USER':
          case 'error-null-result':
            errorMessage = "Google sign-in was cancelled";
            break;
          case 'network_error':
            errorMessage =
                "Erreur de connexion réseau. Vérifiez votre connexion internet.";
            break;
          case 'popup_closed_by_user':
            errorMessage = "La fenêtre de connexion Google a été fermée";
            break;
          case 'ERROR_MISSING_GOOGLE_AUTH_TOKEN':
            errorMessage = "Erreur d'authentification avec Google";
            break;
          case 'error-null-user':
          case 'error-user-model':
            errorMessage = e.message ?? errorMessage;
            break;
          case 'ERROR_INVALID_USER_DATA':
            errorMessage =
                "Les données utilisateur sont invalides ou incomplètes";
            break;
          default:
            if (e.message != null && e.message!.isNotEmpty) {
              errorMessage = e.message!;
            }
        }
      } else if (e.toString().contains('PlatformException')) {
        errorMessage = "Erreur de plateforme lors de la connexion Google";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        duration: Duration(seconds: 4),
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loginWithGithub() async {
    setState(() => isLoading = true);
    try {
      print('[Login] Starting GitHub login process...');

      final userCredential = await FirebaseService.signInWithGithub();

      if (userCredential.user != null) {
        print('[Login] GitHub login successful: ${userCredential.user!.email}');

        // Create user model
        final userModel = UserModel.fromFirebaseUser(userCredential.user!);
        print('[Login] User model created: ${userModel.email}');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "GitHub sign-in successful! Welcome ${userModel.displayName ?? userModel.email}"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Check if user needs to complete profile
        final shouldRedirectToProfile =
            await FirebaseService.shouldRedirectToProfile(
                userCredential.user!.uid);

        if (shouldRedirectToProfile) {
          print('[Login] GitHub user redirecting to profile completion');
          Navigator.pushReplacementNamed(context, '/profile');
        } else {
          print('[Login] GitHub user redirecting to home');
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print('[Login] GitHub login error: $e');
      String errorMessage = "Erreur lors de la connexion avec GitHub";

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'popup-closed-by-user':
          case 'user-cancelled':
            errorMessage = "Connexion annulée par l'utilisateur";
            break;
          case 'network-request-failed':
            errorMessage =
                "Erreur de connexion réseau. Vérifiez votre connexion internet.";
            break;
          case 'invalid-credential':
            errorMessage =
                "Erreur d'authentification GitHub. Veuillez réessayer.";
            break;
          case 'account-exists-with-different-credential':
            errorMessage =
                "Un compte existe déjà avec cette adresse email via un autre fournisseur.";
            break;
          case 'operation-not-supported-in-this-environment':
            errorMessage =
                "L'authentification GitHub n'est pas supportée dans cet environnement.";
            break;
          default:
            errorMessage = e.message ?? "Erreur d'authentification GitHub";
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFDFD),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Center(
                child: Image.asset(
                  'lib/resource/rifnonbgcopy.png', // Change to your logo path
                  height: 180,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Connexion",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAA6B94),
                ),
              ),
              SizedBox(height: 40),

              // Email field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Color(0xFFAA6B94)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Password field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  labelStyle: TextStyle(color: Color(0xFFAA6B94)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFC87AAA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Sign In",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
              SizedBox(height: 10),

              // Forgot Password & Sign Up links
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecoverPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color(0xFFAA6B94),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Create Account",
                      style: TextStyle(
                        color: Color(0xFFAA6B94),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              Text(
                "Or sign in with",
                style: TextStyle(color: Color(0xFFAA6B94)),
              ),
              SizedBox(height: 15),

              // Social login buttons
              Column(
                children: [
                  _socialButton(
                    "Continue with Google",
                    loginWithGoogle,
                    Icons.g_mobiledata,
                    Color(0xFFDB4437), // Google red
                  ),
                  SizedBox(height: 10),
                  _socialButton(
                    "Continue with GitHub",
                    loginWithGithub,
                    Icons.code,
                    Color(0xFF333333), // GitHub dark
                  ),
                ],
              ),

              SizedBox(height: 40),

              // Cooperation logos section
              Column(
                children: [
                  Text(
                    "In Cooperation With",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFAA6B94),
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      // Univ2 Logo
                      Image.asset(
                        'lib/resource/LOGO_Univ2-removebg-preview.png',
                        height: 80,
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 15),
                      // IEEE Logo
                      Image.asset(
                        'lib/resource/IEEE.png',
                        height: 80,
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 15),
                      // IEEE DZ Logo
                      Image.asset(
                        'lib/resource/IEEE dz.png',
                        height: 80,
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String text, VoidCallback onPressed, IconData icon,
      [Color? iconColor]) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor ?? Color(0xFFAA6B94), size: 24),
        label: Text(text,
            style: TextStyle(
              color: iconColor ?? Color(0xFFAA6B94),
              fontWeight: FontWeight.w500,
            )),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFDFDFD),
          side: BorderSide(color: iconColor ?? Color(0xFFAA6B94)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 1,
        ),
      ),
    );
  }
}
