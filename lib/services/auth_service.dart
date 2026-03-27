import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.login), body: {'identifier': identifier, 'password': password});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['requires_otp'] != true) {
          final prefs = await SharedPreferences.getInstance();
          
          // SAFELY PARSE ID TO PREVENT TYPE ERROR CRASH
          int userId = int.tryParse(data['user']['id'].toString()) ?? 0;
          await prefs.setInt('user_id', userId);
          await prefs.setString('role', data['user']['role'].toString());
          await prefs.setString('full_name', data['user']['full_name'].toString());
        }
        return data;
      }
      return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      // EXPOSE THE ACTUAL ERROR INSTEAD OF A GENERIC MESSAGE
      return {'status': 'error', 'message': 'App Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.register), body: userData);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
    } catch (e) { 
      return {'status': 'error', 'message': 'App Error: $e'}; 
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.verifyOtp), body: {'email': email, 'otp': otp});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          
          int userId = int.tryParse(data['user']['id'].toString()) ?? 0;
          await prefs.setInt('user_id', userId);
          await prefs.setString('role', data['user']['role'].toString());
          await prefs.setString('full_name', data['user']['full_name'].toString());
        }
        return data;
      }
      return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
    } catch (e) { 
      return {'status': 'error', 'message': 'App Error: $e'}; 
    }
  }

  static Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.resendOtp), body: {'email': email});
      if (response.statusCode == 200) return json.decode(response.body);
      return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
    } catch (e) { 
      return {'status': 'error', 'message': 'App Error: $e'}; 
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
