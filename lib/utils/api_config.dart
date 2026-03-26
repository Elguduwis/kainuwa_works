class ApiConfig {
  static const String baseUrl = 'https://works.kainuwa.africa/api/mobile';
  
  static const String login = '$baseUrl/auth_login.php';
  static const String register = '$baseUrl/auth_register.php';
  static const String getWallet = '$baseUrl/get_wallet.php';
  static const String getClientBookings = '$baseUrl/get_client_bookings.php';
  static const String getClientProfile = '$baseUrl/get_client_profile.php';
}
