import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart'; // Firebase auth service

class RecoverPage extends StatefulWidget {
  const RecoverPage({Key? key}) : super(key: key);

  @override
  _RecoverPageState createState() => _RecoverPageState();
}

class _RecoverPageState extends State<RecoverPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  bool isCodeSent = false;
  bool isVerified = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  // Send a password reset email using Firebase
  Future<void> sendPasswordResetEmail() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez entrer votre adresse email")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      print(
          '[Recover] Checking if email exists first: ${emailController.text.trim()}');

      // First check if email exists using our custom method
      final emailExists =
          await FirebaseService.checkEmailExists(emailController.text.trim());
      print('[Recover] Email exists result: $emailExists');

      if (!emailExists) {
        print('[Recover] Email does not exist, showing error message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Email invalide"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      print('[Recover] Email exists, attempting to send password reset email');

      // If email exists, send the reset email
      await FirebaseService.sendPasswordReset(emailController.text.trim());

      print('[Recover] Password reset email sent successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Email de réinitialisation envoyé. Vérifiez votre boîte email ou dans le spam."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      print('[Recover] FirebaseAuthException: ${e.code} - ${e.message}');
      print('[Recover] Full error details: $e');
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = "Email invalide";
          print('[Recover] User not found - showing email invalide message');
          break;
        case 'invalid-email':
          errorMessage = "Format d'email invalide";
          break;
        case 'too-many-requests':
          errorMessage = "Trop de tentatives. Veuillez réessayer plus tard.";
          break;
        case 'network-request-failed':
          errorMessage =
              "Erreur de connexion. Vérifiez votre connexion internet.";
          break;
        default:
          errorMessage = "Erreur lors de l'envoi de l'email: ${e.message}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor:
              e.code == 'user-not-found' ? Colors.orange : Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print('[Recover] General error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Erreur lors de l'envoi de l'email de réinitialisation"),
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
                  'lib/resource/rifnonbgcopy.png',
                  height: 180,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Récupération de mot de passe",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF614f96),
                ),
              ),
              SizedBox(height: 40),

              // Back to Login link
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "← Back to Sign In",
                    style: TextStyle(
                      color: Color(0xFF614f96),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              // Password reset - send reset email
              Column(
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: Color(0xFF614f96)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : sendPasswordResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF614f96),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Send Password Reset Email",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
