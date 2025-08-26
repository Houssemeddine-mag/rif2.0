import 'package:flutter/material.dart';
import '../services/api_service.dart'; // REST API file

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

  @override
  void initState() {
    super.initState();
    // Initialize test credentials
    nameController.text = 'Test User';
    emailController.text = 'h@h.com';
    passwordController.text = '12345';
  }

  // Email signup
  Future<void> signupWithEmail() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.signup(
        nameController.text,
        emailController.text,
        passwordController.text,
      );
      if (response.success) {
        // Navigate to home page
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur lors de l'inscription")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Social signup placeholders
  void signupWithGoogle() {
    // TODO: Implement Google Sign-Up
  }

  void signupWithFacebook() {
    // TODO: Implement Facebook Sign-Up
  }

  void signupWithLinkedIn() {
    // TODO: Implement LinkedIn Sign-Up
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
                  _socialButton("LinkedIn", signupWithLinkedIn, Icons.work),
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
