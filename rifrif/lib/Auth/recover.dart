import 'package:flutter/material.dart';
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
    // Initialize test credentials
    emailController.text = 'h@h.com';
    codeController.text = '1234';
    newPasswordController.text = '12345';
  }

  // Send a password reset email using Firebase
  Future<void> sendPasswordResetEmail() async {
    setState(() => isLoading = true);
    try {
      await FirebaseService.sendPasswordReset(emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email de réinitialisation envoyé.")),
      );
      Navigator.pop(context);
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
                  color: Color(0xFFAA6B94),
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
                    "← Retour à la connexion",
                    style: TextStyle(
                      color: Color(0xFFAA6B94),
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
                      labelStyle: TextStyle(color: Color(0xFFAA6B94)),
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
                        backgroundColor: Color(0xFFC87AAA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Envoyer l'email de réinitialisation",
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
