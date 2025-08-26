import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginResponse {
  final bool success;
  final String message;
  final String? token;

  LoginResponse({required this.success, required this.message, this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'An error occurred',
      token: json['token'],
    );
  }

  factory LoginResponse.error(String message) {
    return LoginResponse(success: false, message: message);
  }
}

class ApiService {
  static const baseUrl = "http://your-backend-url/api";

  static Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(json.decode(response.body));
      } else {
        return LoginResponse.error('Failed to login. Please try again.');
      }
    } catch (e) {
      return LoginResponse.error('Network error occurred');
    }
  }

  static Future<LoginResponse> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        return LoginResponse.fromJson(json.decode(response.body));
      } else {
        return LoginResponse.error('Failed to signup. Please try again.');
      }
    } catch (e) {
      return LoginResponse.error('Network error occurred');
    }
  }

  static Future<LoginResponse> sendRecoveryCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-recovery-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(json.decode(response.body));
      } else {
        return LoginResponse.error(
          'Failed to send recovery code. Please try again.',
        );
      }
    } catch (e) {
      return LoginResponse.error('Network error occurred');
    }
  }

  static Future<LoginResponse> verifyRecoveryCode(
    String email,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-recovery-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(json.decode(response.body));
      } else {
        return LoginResponse.error('Invalid recovery code. Please try again.');
      }
    } catch (e) {
      return LoginResponse.error('Network error occurred');
    }
  }

  static Future<LoginResponse> resetPassword(
    String email,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(json.decode(response.body));
      } else {
        return LoginResponse.error(
          'Failed to reset password. Please try again.',
        );
      }
    } catch (e) {
      return LoginResponse.error('Network error occurred');
    }
  }
}
