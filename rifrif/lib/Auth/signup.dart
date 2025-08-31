import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'verification.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  // Email signup
  Future<void> signupWithEmail() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      print('[Signup] Starting email signup process');
      print('[Signup] Validating password length');

      if (passwordController.text.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password must be at least 6 characters long',
        );
      }

      print('[Signup] Creating account with email: ${emailController.text}');
      final result = await FirebaseService.signUpWithEmailAndVerification(
        emailController.text.trim(),
        passwordController.text,
      );

      final credential = result['credential'] as UserCredential;
      final verificationCode = result['verificationCode'] as String;

      if (credential.user != null) {
        print('[Signup] Account created successfully');
        print('[Signup] Updating display name to: ${nameController.text}');

        try {
          await credential.user!.updateDisplayName(nameController.text.trim());
          print('[Signup] Display name updated');

          // Verify that the user data is complete
          final user = credential.user!;
          if (user.email == null || user.email!.isEmpty) {
            throw FirebaseAuthException(
              code: 'invalid-user-data',
              message: 'Account data is incomplete',
            );
          }

          // Navigate to verification page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationPage(
                email: emailController.text.trim(),
                verificationCode: verificationCode,
              ),
            ),
          );
        } catch (profileError) {
          print('[Signup] Error updating user profile: $profileError');
          throw FirebaseAuthException(
            code: 'profile-update-error',
            message: 'Error updating profile',
          );
        }
      } else {
        print('[Signup] Credential user is null');
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'No user data received',
        );
      }
    } catch (e) {
      print('[Signup] Error: $e');
      String errorMessage = "An error occurred during registration";

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = "This email is already in use";
            break;
          case 'weak-password':
            errorMessage = e.message ?? "Password is too weak";
            break;
          case 'invalid-email':
            errorMessage = "Invalid email";
            break;
          case 'operation-not-allowed':
            errorMessage = "Email/password registration is not enabled";
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

  // Social signup placeholders
  Future<void> signupWithGoogle() async {
    setState(() => isLoading = true);
    try {
      print('[Signup] Starting Google signup process...');

      final userCredential = await FirebaseService.signInWithGoogle();

      if (userCredential == null) {
        print('[Signup] Sign in result is null');
        throw FirebaseAuthException(
          code: 'error-null-result',
          message: "L'inscription a échoué",
        );
      }

      final user = userCredential.user;
      if (user == null) {
        print('[Signup] User is null after successful sign in');
        throw FirebaseAuthException(
          code: 'error-null-user',
          message: 'Impossible de récupérer les informations utilisateur',
        );
      }

      print('[Signup] Got valid user: ${user.email}');

      // Navigation vers Home si tout est OK
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print('[Signup] Error in signupWithGoogle: $e');
      String errorMessage =
          "Une erreur s'est produite lors de l'inscription avec Google";

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'ERROR_ABORTED_BY_USER':
          case 'error-null-result':
            errorMessage = "L'inscription avec Google a été annulée";
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
            errorMessage = e.message ?? errorMessage;
            break;
          default:
            if (e.message != null && e.message!.isNotEmpty) {
              errorMessage = e.message!;
            }
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

  Future<void> signupWithGithub() async {
    setState(() => isLoading = true);
    try {
      print('[Signup] Starting GitHub signup process...');

      final userCredential = await FirebaseService.signInWithGithub();

      if (userCredential.user != null) {
        print(
            '[Signup] GitHub signup successful: ${userCredential.user!.email}');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "GitHub registration successful! Welcome ${userCredential.user!.displayName ?? userCredential.user!.email}"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to home
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('[Signup] GitHub signup error: $e');
      String errorMessage = "Erreur lors de l'inscription avec GitHub";

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'popup-closed-by-user':
          case 'user-cancelled':
            errorMessage = "Inscription annulée par l'utilisateur";
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
          default:
            errorMessage = e.message ?? "Erreur d'inscription GitHub";
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
                  'lib/resource/rifnonbgcopy.png', // Update with your logo path
                  height: 180,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Welcome to RIF",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAA6B94),
                ),
              ),
              SizedBox(height: 40),

              // Name field
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nom complet",
                  labelStyle: TextStyle(color: Color(0xFFAA6B94)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),

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

              // Signup button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signupWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFC87AAA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Sign Up",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
              SizedBox(height: 10),

              // Back to Login link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Already have an account? Sign In",
                    style: TextStyle(
                      color: Color(0xFFAA6B94),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              Text(
                "Ou inscrivez-vous avec",
                style: TextStyle(color: Color(0xFFAA6B94)),
              ),
              SizedBox(height: 15),

              // Social signup buttons
              Column(
                children: [
                  _socialButton(
                    "Sign up with Google",
                    signupWithGoogle,
                    Icons.g_mobiledata,
                    Color(0xFFDB4437), // Google red
                  ),
                  SizedBox(height: 10),
                  _socialButton(
                    "Sign up with GitHub",
                    signupWithGithub,
                    Icons.code,
                    Color(0xFF333333), // GitHub dark
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(
      String text, VoidCallback onPressed, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 24),
        label: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
