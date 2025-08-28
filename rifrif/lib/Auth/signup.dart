import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

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
        SnackBar(content: Text("Veuillez remplir tous les champs")),
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
          message: 'Le mot de passe doit contenir au moins 6 caractères',
        );
      }

      print('[Signup] Creating account with email: ${emailController.text}');
      final credential = await FirebaseService.signUpWithEmail(
        emailController.text.trim(),
        passwordController.text,
      );

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
              message: 'Les données du compte sont incomplètes',
            );
          }

          // Navigation vers Home si tout est OK
          Navigator.pushReplacementNamed(context, '/home');
        } catch (profileError) {
          print('[Signup] Error updating user profile: $profileError');
          throw FirebaseAuthException(
            code: 'profile-update-error',
            message: 'Erreur lors de la mise à jour du profil',
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
      String errorMessage = "Une erreur s'est produite lors de l'inscription";

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = "Cet email est déjà utilisé";
            break;
          case 'weak-password':
            errorMessage = e.message ?? "Le mot de passe est trop faible";
            break;
          case 'invalid-email':
            errorMessage = "Email invalide";
            break;
          case 'operation-not-allowed':
            errorMessage =
                "L'inscription par email/mot de passe n'est pas activée";
            break;
          case 'network-request-failed':
            errorMessage =
                "Erreur de connexion réseau. Vérifiez votre connexion internet";
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

  void signupWithFacebook() {
    // TODO: Implement Facebook Sign-Up
  }

  Future<void> signupWithGithub() async {
    setState(() => isLoading = true);
    try {
      final cred = await FirebaseService.signInWithGithub();
      if (cred.user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
                "Bienvenue sur Rif",
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
                          "S'inscrire",
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
                    "Déjà un compte ? Se connecter",
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
                  _socialButton("Google", signupWithGoogle, Icons.g_mobiledata),
                  SizedBox(height: 10),
                  _socialButton("Facebook", signupWithFacebook, Icons.facebook),
                  SizedBox(height: 10),
                  _socialButton("GitHub", signupWithGithub, Icons.code),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String text, VoidCallback onPressed, IconData icon) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Color(0xFFAA6B94), size: 24),
        label: Text(text, style: TextStyle(color: Color(0xFFAA6B94))),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFDFDFD),
          side: BorderSide(color: Color(0xFFAA6B94)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
