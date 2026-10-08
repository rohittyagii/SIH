// Import the flutter_riverpod package, which is a state management library for Flutter.
// It allows us to provide and consume dependencies and state easily throughout the app.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the flutter_secure_storage package.
// This is used to securely store sensitive data, like passwords or PINs, encrypted on the device.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import our custom API client, which handles network requests.
import 'api_client.dart';

// Create a provider for the AuthService. 
// This makes the AuthService available globally so any part of the app can use it.
final authServiceProvider = Provider<AuthService>((ref) {
  // Read the apiClientProvider to get an instance of ApiClient and inject it into AuthService.
  return AuthService(ref.read(apiClientProvider));
});

// Define the AuthService class.
// This class contains all the logic related to user authentication (login, logout, pin change, etc.).
class AuthService {
  // A private variable to hold the ApiClient instance.
  // It handles communicating with our backend server.
  final ApiClient _api;

  // An instance of FlutterSecureStorage to securely store data locally on the device.
  final _storage = const FlutterSecureStorage();

  // The constructor requires an ApiClient to be passed in when creating the AuthService.
  AuthService(this._api);

  // A method to activate a new device. It returns a Future containing a Map of user data.
  // This is marked async because it performs asynchronous network operations.
  Future<Map<String, dynamic>> activateDevice(
      String code, String pin, String fullName) async {
    try {
      // Send a POST request to the backend at '/auth/mobile/activate' with the activation details.
      final res = await _api.dio.post('/auth/mobile/activate', data: {
        'activation_code': code, // The activation code entered by the user.
        'pin': pin, // The PIN the user chose.
        'full_name': fullName, // The user's full name.
      });

      // Extract the 'access_token' from the server's response.
      // This token will be used to authenticate future requests.
      final token = res.data['access_token'];

      // Save the token using our API client so subsequent requests are authenticated.
      await _api.saveToken(token);

      // Securely save the chosen PIN to the local storage.
      // This allows the user to log in later even if the device is offline.
      await _storage.write(
          key: 'local_pin', value: pin); // Cache PIN for offline

      // Return the 'user' data from the response to whoever called this method.
      return res.data['user'];
    } catch (e) {
      // If any error occurs (like network failure or invalid code), rethrow it so the caller can handle it.
      rethrow;
    }
  }

  // A method for users to log in, taking their service ID and PIN.
  Future<Map<String, dynamic>> login(String serviceId, String pin) async {
    // 1. Try local offline validation first for instant login
    // Read the securely saved local PIN from device storage.
    final localPin = await _storage.read(key: 'local_pin');
    
    // Check if a local PIN exists and matches the PIN entered by the user.
    if (localPin != null && localPin == pin) {
      // Trigger background login to wake server and get a fresh token
      // If it matches, we log the user in immediately, and silently update the token in the background.
      _backgroundLogin(serviceId, pin);
      
      // Return a basic map representing the user since we aren't waiting for the server response.
      return {'service_id': serviceId, 'name': 'User'};
    }

    // 2. If local validation fails or no local PIN exists, fallback to API
    try {
      // Send a POST request to the backend login endpoint.
      final res = await _api.dio.post('/auth/mobile/login', data: {
        'service_id': serviceId, // The user's service ID.
        'pin': pin, // The PIN entered by the user.
      });

      // Extract the new access token from the response.
      final token = res.data['access_token'];

      // Save the token so future requests are authorized.
      await _api.saveToken(token);

      // Save or update the PIN in local secure storage.
      await _storage.write(
          key: 'local_pin', value: pin); // Cache PIN for future offline logins
      
      // Return the user information provided by the backend.
      return res.data['user'];
    } catch (e) {
      // If the login fails (e.g., incorrect PIN or network error), rethrow the error.
      rethrow;
    }
  }

  // A private helper method used to authenticate in the background when an offline login succeeds.
  Future<void> _backgroundLogin(String serviceId, String pin) async {
    try {
      // Send the same login request to the server.
      final res = await _api.dio.post('/auth/mobile/login', data: {
        'service_id': serviceId,
        'pin': pin,
      });

      // Get the fresh access token.
      final token = res.data['access_token'];

      // Save the new token in the API client for upcoming network calls.
      await _api.saveToken(token);
    } catch (_) {
      // If this background process fails (e.g., device is actually offline), we ignore the error
      // since the user is already logged in locally.
    }
  }

  // A method to log the user out.
  Future<void> logout() async {
    try {
      // Tell the backend that the user is logging out to invalidate the session.
      await _api.dio.post('/auth/logout');
    } catch (_) {
      // If the network call fails, we ignore it because we'll still clear local data anyway.
    }
    // Delete the stored access token from the device.
    await _api.clearToken();
  }

  // A method that allows users to completely delete their account data.
  Future<void> deleteMyData() async {
    try {
      // Send a DELETE request to the backend to erase user data.
      await _api.dio.delete('/users/me/data');
    } catch (_) {
      // Ignore network errors, proceed to clear local data.
    }
    // Clear the authentication token.
    await _api.clearToken();
    
    // Completely remove the saved local PIN from secure storage.
    await _storage.delete(key: 'local_pin'); // Clear PIN on full deletion
  }

  // A method to change the user's PIN securely.
  Future<void> changePin(String currentPin, String newPin) async {
    try {
      // Inform the server about the new PIN, providing the old PIN for verification.
      await _api.dio.post('/auth/mobile/change-pin', data: {
        'current_pin': currentPin, // The old PIN.
        'new_pin': newPin, // The new PIN they want to set.
      });

      // If the server update was successful, save the new PIN locally.
      await _storage.write(
          key: 'local_pin', value: newPin); // Update cached PIN
    } catch (e) {
      // If API fails, we could theoretically do an offline pin change, but better to require online for changes.
      // Rethrow the error to show an alert to the user.
      rethrow;
    }
  }

  // A method to update any user preferences.
  Future<void> updatePreferences(Map<String, dynamic> prefs) async {
    try {
      // Send a PATCH request to update only the specific preferences provided.
      await _api.dio.patch('/users/me/preferences', data: prefs);
    } catch (_) {
      // Silently ignore any errors that occur while updating preferences.
    }
  }
}
