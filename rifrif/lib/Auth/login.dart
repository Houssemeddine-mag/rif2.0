import 'package:flutter/material.dart';
// import '../services/api_service.dart'; // Uncomment when API is ready
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

  @override
  void initState() {
    super.initState();
    // Initialize test credentials
    emailController.text = 'h@h.com';
    passwordController.text = '12345';
  }

  /* TODO: API Integration Steps:
   * 1. Make sure the ApiService.login method is implemented in '../services/api_service.dart'
   * 2. The login method should return a response with:
   *    - success: boolean
   *    - message: string
   *    - token: string (optional for authentication)
   * 3. Uncomment the API integration code below
   * 4. Remove the temporary direct navigation
   */
  Future<void> loginWithEmail() async {
    setState(() => isLoading = true);

    // Temporary direct navigation - REMOVE THIS when API is ready
    await Future.delayed(Duration(milliseconds: 500)); // Simulated loading
    Navigator.pushReplacementNamed(context, '/home');
    setState(() => isLoading = false);

    /* Uncomment this when API is ready:
    try {
      final response = await ApiService.login(
        emailController.text,
        passwordController.text,
      );
      if (response.success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur de connexion")));
    } finally {
      setState(() => isLoading = false);
    }
    */
  }

  // Social login placeholders
  void loginWithGoogle() {
    // TODO: Implement Google Sign-In
  }

  void loginWithFacebook() {
    // TODO: Implement Facebook Sign-In
  }

  void loginWithLinkedIn() {
    // TODO: Implement LinkedIn Sign-In
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
                          "Se connecter",
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
                      "Mot de passe oublié ?",
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
                      "Créer un compte",
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
                "Ou connectez-vous avec",
                style: TextStyle(color: Color(0xFFAA6B94)),
              ),
              SizedBox(height: 15),

              // Social login buttons
              Column(
                children: [
                  _socialButton(
                    "Login withGoogle",
                    loginWithGoogle,
                    Icons.g_mobiledata,
                  ),
                  SizedBox(height: 10),
                  _socialButton(
                    "Login with Facebook",
                    loginWithFacebook,
                    Icons.facebook,
                  ),
                  SizedBox(height: 10),
                  _socialButton(
                    "Login with LinkedIn",
                    loginWithLinkedIn,
                    Icons.work,
                  ),
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
