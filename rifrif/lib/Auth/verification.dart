import 'package:flutter/material.dart';

class VerificationPage extends StatefulWidget {
  final String email;
  final String verificationCode;

  const VerificationPage({
    Key? key,
    required this.email,
    required this.verificationCode,
  }) : super(key: key);

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController codeController = TextEditingController();
  bool isLoading = false;
  bool canResendCode = false;
  int resendTimer = 60;

  @override
  void initState() {
    super.initState();
    startResendTimer();
  }

  void startResendTimer() {
    setState(() {
      canResendCode = false;
      resendTimer = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        setState(() {
          resendTimer--;
        });
        return resendTimer > 0;
      }
      return false;
    }).then((_) {
      if (mounted) {
        setState(() {
          canResendCode = true;
        });
      }
    });
  }

  Future<void> verifyCode() async {
    if (codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter the verification code")),
      );
      return;
    }

    if (codeController.text.trim().length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Code must contain 4 digits")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      print('[Verification] Verifying code: ${codeController.text.trim()}');
      print('[Verification] Expected code: ${widget.verificationCode}');

      if (codeController.text.trim() == widget.verificationCode) {
        print('[Verification] Code is correct, account verified');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account verified successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to home page
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print('[Verification] Code is incorrect');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Incorrect verification code"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('[Verification] Error during verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error during verification"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> resendCode() async {
    if (!canResendCode) return;

    setState(() => isLoading = true);
    try {
      print('[Verification] Resending verification code to: ${widget.email}');

      // In a real implementation, you would call your backend service here
      // For now, we'll just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nouveau code envoyé par email"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      startResendTimer();
    } catch (e) {
      print('[Verification] Error resending code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'envoi du code"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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
                  height: 150,
                ),
              ),
              SizedBox(height: 30),

              // Title
              Text(
                "Vérification du compte",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF614f96),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Subtitle
              Text(
                "Un code de vérification à 4 chiffres a été envoyé à:",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),

              // Email display
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF614f96),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // Code input field
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  labelText: "Code de vérification",
                  labelStyle: TextStyle(color: Color(0xFF614f96)),
                  hintText: "0000",
                  hintStyle: TextStyle(letterSpacing: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF614f96), width: 2),
                  ),
                  counterText: "",
                ),
              ),
              SizedBox(height: 30),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF614f96),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20),

              // Resend code section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Code not received? ",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: canResendCode && !isLoading ? resendCode : null,
                    child: Text(
                      canResendCode
                          ? "Resend code"
                          : "Resend in ${resendTimer}s",
                      style: TextStyle(
                        color: canResendCode ? Color(0xFF614f96) : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Back to signup
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: Text(
                  "← Back to Sign Up",
                  style: TextStyle(
                    color: Color(0xFF614f96),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}
