import 'package:flutter/material.dart';
import '../services/api_service.dart'; // REST API service

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

  // Step 1: Send code
  Future<void> sendCode() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.sendRecoveryCode(emailController.text);
      if (response.success) {
        setState(() => isCodeSent = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Code envoyé à votre email")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur lors de l'envoi du code")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Step 2: Verify code
  Future<void> verifyCode() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.verifyRecoveryCode(
        emailController.text,
        codeController.text,
      );
      if (response.success) {
        setState(() => isVerified = true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Code incorrect")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur de vérification")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Step 3: Reset password
  Future<void> resetPassword() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.resetPassword(
        emailController.text,
        newPasswordController.text,
      );
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mot de passe mis à jour avec succès")),
        );
        Navigator.pop(context); // Go back to login
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la mise à jour du mot de passe"),
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

              // Step 1: Email
              if (!isCodeSent)
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
                        onPressed: isLoading ? null : sendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFC87AAA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Envoyer le code",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

              // Step 2: Enter 4-digit code
              if (isCodeSent && !isVerified)
                Column(
                  children: [
                    TextField(
                      controller: codeController,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Code à 4 chiffres",
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
                        onPressed: isLoading ? null : verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFC87AAA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Vérifier le code",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

              // Step 3: New password
              if (isVerified)
                Column(
                  children: [
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Nouveau mot de passe",
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
                        onPressed: isLoading ? null : resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFC87AAA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Réinitialiser le mot de passe",
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
