import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';

class ClientService {
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    return userId?.toString();
  }

  // Generic helper to catch JSON parsing errors that cause infinite loading
  static Future<Map<String, dynamic>> _safePost(String url, Map<String, dynamic> body) async {
    try {
      final res = await http.post(Uri.parse(url), body: body).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        try {
          return json.decode(res.body);
        } catch (e) {
          return {'status': 'error', 'message': 'Backend returned invalid data. Check PHP errors.'};
        }
      }
      return {'status': 'error', 'message': 'Server error: ${res.statusCode}'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection timed out or failed.'};
    }
  }

  static Future<Map<String, dynamic>> fetchWallet() async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    return await _safePost(ApiConfig.getWallet, {'user_id': userId});
  }

  static Future<Map<String, dynamic>> fetchBookings() async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    return await _safePost(ApiConfig.getClientBookings, {'user_id': userId});
  }

  static Future<Map<String, dynamic>> fetchProfile() async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    return await _safePost(ApiConfig.getClientProfile, {'user_id': userId});
  }

  static Future<Map<String, dynamic>> fetchProviders({String query = '', String categoryId = '0'}) async {
    return await _safePost(ApiConfig.getProviders, {'query': query, 'category_id': categoryId});
  }

  static Future<Map<String, dynamic>> fetchWorkerProfile(String workerId) async {
    return await _safePost(ApiConfig.getWorkerProfile, {'worker_id': workerId});
  }

  static Future<Map<String, dynamic>> createBooking(Map<String, String> data) async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    data['client_id'] = userId; 
    return await _safePost(ApiConfig.createBooking, data);
  }
}
