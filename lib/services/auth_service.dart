import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        body: {
          'identifier': identifier,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', data['user']['id']);
          await prefs.setString('role', data['user']['role']);
          await prefs.setString('full_name', data['user']['full_name']);
        }
        return data;
      }
      return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed. Please check your internet.'};
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        body: userData,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', data['user']['id']);
          await prefs.setString('role', data['user']['role']);
          await prefs.setString('full_name', data['user']['full_name']);
        }
        return data;
      }
      return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed. Please check your internet.'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
