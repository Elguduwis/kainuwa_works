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

  static Future<Map<String, dynamic>> fetchWallet() async {
    final userId = await getUserId();
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
    final userId = await getUserId();
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
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    try {
      final res = await http.post(Uri.parse(ApiConfig.getClientProfile), body: {'user_id': userId});
      if (res.statusCode == 200) return json.decode(res.body);
      return {'status': 'error', 'message': 'Server error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed'};
    }
  }

  static Future<Map<String, dynamic>> fetchProviders({String query = '', String categoryId = '0'}) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.getProviders), 
        body: {'query': query, 'category_id': categoryId}
      );
      if (res.statusCode == 200) return json.decode(res.body);
      return {'status': 'error', 'message': 'Server error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed'};
    }
  }

  static Future<Map<String, dynamic>> fetchWorkerProfile(String workerId) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.getWorkerProfile), body: {'worker_id': workerId});
      if (res.statusCode == 200) return json.decode(res.body);
      return {'status': 'error', 'message': 'Server error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed'};
    }
  }

  static Future<Map<String, dynamic>> createBooking(Map<String, String> data) async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    
    data['client_id'] = userId; // Inject the logged-in user's ID
    
    try {
      final res = await http.post(Uri.parse(ApiConfig.createBooking), body: data);
      if (res.statusCode == 200) return json.decode(res.body);
      return {'status': 'error', 'message': 'Server error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed'};
    }
  }
}
