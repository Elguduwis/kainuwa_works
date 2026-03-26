import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';

class ClientService {
  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    return userId?.toString();
  }

  static Future<Map<String, dynamic>> fetchWallet() async {
    final userId = await _getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    try {
      final res = await http.post(Uri.parse(ApiConfig.getWallet), body: {'user_id': userId});
      if (res.statusCode == 200) return json.decode(res.body);
      return {'status': 'error', 'message': 'Server error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed'};
    }
  }

  static Future<Map<String, dynamic>> fetchBookings() async {
    final userId = await _getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    try {
      final res = await http.post(Uri.parse(ApiConfig.getClientBookings), body: {'user_id': userId});
      if (res.statusCode == 200) return json.decode(res.body);
      return {'status': 'error', 'message': 'Server error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed'};
    }
  }

  static Future<Map<String, dynamic>> fetchProfile() async {
    final userId = await _getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    try {
      final res = await http.post(Uri.parse(ApiConfig.getClientProfile), body: {'user_id': userId});
      if (res.statusCode == 200) return json.decode(res.body);
      return {'status': 'error', 'message': 'Server error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed'};
    }
  }
}
