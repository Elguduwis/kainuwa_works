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
        try { return json.decode(res.body); } catch (e) { return {'status': 'error', 'message': 'Invalid data.'}; }
      }
      return {'status': 'error', 'message': 'Server error: ${res.statusCode}'};
    } catch (e) { return {'status': 'error', 'message': 'Connection timed out.'}; }
  }

  static Future<Map<String, dynamic>> fetchDashboard() async => await _safePost(ApiConfig.getWorkerDashboard, {'user_id': await getUserId()});
  static Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String status) async => await _safePost(ApiConfig.updateBookingStatus, {'user_id': await getUserId(), 'booking_id': bookingId, 'status': status});
  static Future<Map<String, dynamic>> fetchBookings() async => await _safePost(ApiConfig.getWorkerBookings, {'user_id': await getUserId()});
  static Future<Map<String, dynamic>> requestRelease(String bookingId) async => await _safePost(ApiConfig.requestRelease, {'user_id': await getUserId(), 'booking_id': bookingId});
  static Future<Map<String, dynamic>> fetchWallet() async => await _safePost(ApiConfig.getWorkerWallet, {'user_id': await getUserId()});
  static Future<Map<String, dynamic>> requestWithdrawal(String amount, String bankDetails) async => await _safePost(ApiConfig.requestWithdrawal, {'user_id': await getUserId(), 'amount': amount, 'bank_details': bankDetails});
  static Future<Map<String, dynamic>> fetchSettings() async => await _safePost(ApiConfig.getWorkerSettings, {'user_id': await getUserId()});
  static Future<Map<String, dynamic>> fetchPayoutMethods() async => await _safePost(ApiConfig.getPayoutMethods, {'user_id': await getUserId()});

  static Future<Map<String, dynamic>> updateAvailability(String status) async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    final url = '${ApiConfig.baseUrl}/update_availability.php';
    return await _safePost(url, {'user_id': userId, 'status': status});
  }

  static Future<Map<String, dynamic>> raiseDispute(String bookingId, String reason, String? imagePath) async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.raiseDispute));
    request.fields['user_id'] = userId;
    request.fields['booking_id'] = bookingId;
    request.fields['reason'] = reason;
    if (imagePath != null) request.files.add(await http.MultipartFile.fromPath('evidence', imagePath));
    try {
      var response = await request.send();
      return json.decode(await response.stream.bytesToString());
    } catch (e) { return {'status': 'error', 'message': 'Upload failed.'}; }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, String> data, String? imagePath) async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.updateProfile));
    request.fields['user_id'] = userId;
    request.fields['role'] = 'worker';
    data.forEach((key, value) => request.fields[key] = value);
    if (imagePath != null) request.files.add(await http.MultipartFile.fromPath('avatar', imagePath));
    try {
      var response = await request.send();
      return json.decode(await response.stream.bytesToString());
    } catch (e) { return {'status': 'error', 'message': 'Upload failed.'}; }
  }

  static Future<Map<String, dynamic>> uploadPortfolioImage(String imagePath) async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadPortfolio));
    request.fields['user_id'] = userId;
    request.files.add(await http.MultipartFile.fromPath('portfolio_image', imagePath));
    try {
      var response = await request.send();
      return json.decode(await response.stream.bytesToString());
    } catch (e) { return {'status': 'error', 'message': 'Upload failed.'}; }
  }

  static Future<Map<String, dynamic>> uploadKyc(String docType, String docPath, String selfiePath) async {
    final userId = await getUserId();
    if (userId == null) return {'status': 'error', 'message': 'Session expired'};
    var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadKyc));
    request.fields['user_id'] = userId;
    request.fields['document_type'] = docType;
    request.files.add(await http.MultipartFile.fromPath('document_image', docPath));
    request.files.add(await http.MultipartFile.fromPath('selfie_image', selfiePath));
    try {
      var response = await request.send();
      return json.decode(await response.stream.bytesToString());
    } catch (e) { return {'status': 'error', 'message': 'Upload failed.'}; }
  }
}
