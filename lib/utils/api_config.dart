class ApiConfig {
  static const String baseUrl = 'https://works.kainuwa.africa/api';
  
  // Endpoint definitions
  static const String login = '$baseUrl/auth_login.php';
  static const String getProviders = '$baseUrl/get_providers.php';
  // We will add more endpoints here as we build the PHP APIs
}
