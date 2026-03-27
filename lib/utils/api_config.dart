class ApiConfig {
  static const String baseUrl = 'https://works.kainuwa.africa/api/mobile';
  
  static const String login = '$baseUrl/auth_login.php';
  static const String register = '$baseUrl/auth_register.php';
  static const String getWallet = '$baseUrl/get_wallet.php';
  static const String getClientBookings = '$baseUrl/get_client_bookings.php';
  static const String getClientProfile = '$baseUrl/get_client_profile.php';
  static const String getProviders = '$baseUrl/get_providers.php';
  static const String getWorkerProfile = '$baseUrl/get_worker_profile.php';
  static const String createBooking = '$baseUrl/create_booking.php';
  static const String chatApi = '$baseUrl/chat_api.php';
  static const String getWorkerDashboard = '$baseUrl/get_worker_dashboard.php';
  static const String updateBookingStatus = '$baseUrl/update_booking_status.php';
  static const String getWorkerBookings = '$baseUrl/get_worker_bookings.php';
}
