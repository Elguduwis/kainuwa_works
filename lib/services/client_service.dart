
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



  static Future<Map<String, dynamic>> _safePost(String url, Map<String, dynamic> body) async {

    try {

      final res = await http.post(Uri.parse(url), body: body).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {

        try { return json.decode(res.body); } catch (e) { return {'status': 'error', 'message': 'Invalid data.'}; }

      }

      return {'status': 'error', 'message': 'Server error: ${res.statusCode}'};

    } catch (e) { return {'status': 'error', 'message': 'Connection timed out.'}; }

  }



  static Future<Map<String, dynamic>> fetchCategories() async => await _safePost(ApiConfig.getCategories, {});

  static Future<Map<String, dynamic>> fetchWallet() async => await _safePost(ApiConfig.getWallet, {'user_id': await getUserId()});

  static Future<Map<String, dynamic>> fetchBookings() async => await _safePost(ApiConfig.getClientBookings, {'user_id': await getUserId()});

  static Future<Map<String, dynamic>> fetchProfile() async => await _safePost(ApiConfig.getClientProfile, {'user_id': await getUserId()});

  static Future<Map<String, dynamic>> fetchProviders({String query = '', String categoryId = '0'}) async => await _safePost(ApiConfig.getProviders, {'query': query, 'category_id': categoryId});

  static Future<Map<String, dynamic>> fetchWorkerProfile(String workerId) async => await _safePost(ApiConfig.getWorkerProfile, {'worker_id': workerId});

  static Future<Map<String, dynamic>> createBooking(Map<String, String> data) async {

    final userId = await getUserId();

    if (userId == null) return {'status': 'error'};

    data['client_id'] = userId; 

    return await _safePost(ApiConfig.createBooking, data);

  }

  static Future<Map<String, dynamic>> fetchChatMessages(String bookingId, String lastId) async => await _safePost(ApiConfig.chatApi, {'user_id': await getUserId(), 'action': 'fetch', 'booking_id': bookingId, 'last_id': lastId});

  static Future<Map<String, dynamic>> sendChatMessage(String bookingId, String message) async => await _safePost(ApiConfig.chatApi, {'user_id': await getUserId(), 'action': 'send', 'booking_id': bookingId, 'message': message});

  static Future<Map<String, dynamic>> releaseEscrow(String bookingId) async => await _safePost(ApiConfig.releaseEscrow, {"user_id": await getUserId(), "booking_id": bookingId});

  static Future<Map<String, dynamic>> fundEscrow(String bookingId, String amount) async => await _safePost(ApiConfig.fundEscrow, {'user_id': await getUserId(), 'booking_id': bookingId, 'amount': amount});



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



  // NEW: Profile Update Multipart

  static Future<Map<String, dynamic>> updateProfile(Map<String, String> data, String? imagePath) async {

    final userId = await getUserId();

    if (userId == null) return {'status': 'error', 'message': 'Session expired'};

    var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.updateProfile));

    request.fields['user_id'] = userId;

    request.fields['role'] = 'client';

    data.forEach((key, value) => request.fields[key] = value);

    if (imagePath != null) request.files.add(await http.MultipartFile.fromPath('avatar', imagePath));

    try {

      var response = await request.send();

      return json.decode(await response.stream.bytesToString());

    } catch (e) { return {'status': 'error', 'message': 'Upload failed.'}; }

  }

}

