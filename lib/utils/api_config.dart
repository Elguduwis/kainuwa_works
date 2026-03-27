class ApiConfig {
  static const String baseUrl = 'https://works.kainuwa.africa/api/mobile';
  
  static const String login = '$baseUrl/auth_login.php';
  static const String register = '$baseUrl/auth_register.php';
  static const String verifyOtp = '$baseUrl/verify_otp.php';
  static const String getWallet = '$baseUrl/get_wallet.php';
  static const String getClientBookings = '$baseUrl/get_client_bookings.php';
  static const String getClientProfile = '$baseUrl/get_client_profile.php';
  static const String getProviders = '$baseUrl/get_providers.php';
  static const String getCategories = '$baseUrl/get_categories.php';
  static const String getWorkerProfile = '$baseUrl/get_worker_profile.php';
  static const String createBooking = '$baseUrl/create_booking.php';
  static const String chatApi = '$baseUrl/chat_api.php';
  static const String getWorkerDashboard = '$baseUrl/get_worker_dashboard.php';
  static const String updateBookingStatus = '$baseUrl/update_booking_status.php';
  static const String getWorkerBookings = '$baseUrl/get_worker_bookings.php';
  static const String fundEscrow = '$baseUrl/fund_escrow.php';
  static const String requestRelease = '$baseUrl/request_release.php';
  static const String releaseEscrow = '$baseUrl/release_escrow.php';
  static const String raiseDispute = '$baseUrl/raise_dispute.php';
  static const String getWorkerWallet = '$baseUrl/get_worker_wallet.php';
  static const String requestWithdrawal = '$baseUrl/request_withdrawal.php';
  static const String getWorkerSettings = '$baseUrl/get_worker_settings.php';
  static const String updateProfile = '$baseUrl/update_profile.php';
  static const String uploadPortfolio = '$baseUrl/upload_portfolio.php';
  
  // NEW ENDPOINTS
  static const String uploadKyc = '$baseUrl/upload_kyc.php';
  static const String getPayoutMethods = '$baseUrl/get_payout_methods.php';
}
