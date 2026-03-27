import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';

class WorkerService {
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    return userId?.toString();
  }

  static Future<Map<String, dynamic>> _safePost(String url, Map<String, dynamic> body) async {
    try {
      final res = await http.post(Uri.parse(url), body: body).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        try {
          return json.decode(res.body);
        } catch (e) {
          return {'status': 'error', 'message': 'Backend returned invalid data.'};
        }
      }
      return {'status': 'error', 'message': 'Server error: ${res.statusCode}'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection timed out or failed.'};
    }
  }

  static Future<Map<String, dynamic>> fetchDashboard() async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    return await _safePost(ApiConfig.getWorkerDashboard, {'user_id': userId});
  }

  static Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String status) async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    return await _safePost(ApiConfig.updateBookingStatus, {
      'user_id': userId,
      'booking_id': bookingId,
      'status': status
    });
  }
}
