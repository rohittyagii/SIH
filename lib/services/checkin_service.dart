// Import the Flutter Riverpod package, which is a state management library. 
// It helps in providing and consuming data across the app efficiently.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the Dio package, a powerful HTTP client for Dart/Flutter.
// It is used to make network requests (GET, POST, etc.) to an API or server.
import 'package:dio/dio.dart';

// Import our custom API client module, which handles the core network setup.
// This likely contains the base URL, authentication headers, and Dio instance.
import 'api_client.dart';

// Define a Riverpod Provider for our CheckinService.
// Providers act as a global, safe way to access instances of objects.
// This specific provider creates and provides a single instance of CheckinService.
final checkinServiceProvider = Provider<CheckinService>((ref) {
  // 'ref.read' is used to get the instance of 'apiClientProvider' created elsewhere.
  // We pass this API client instance to the CheckinService constructor.
  return CheckinService(ref.read(apiClientProvider));
});

// Define the CheckinService class.
// This class contains all the logic and methods related to user wellness check-ins.
class CheckinService {
  // Declare a private final variable '_api' of type ApiClient.
  // The underscore '_' means it is private and can only be used inside this class.
  // 'final' means it cannot be reassigned once set.
  final ApiClient _api;

  // The constructor for CheckinService.
  // It takes an ApiClient instance and assigns it to our private '_api' variable.
  CheckinService(this._api);

  // A method to submit a new wellness check-in to the server.
  // It returns a Future<void>, meaning it performs an asynchronous operation
  // but doesn't return any specific value when it finishes.
  Future<void> submitCheckin({
    // 'required' means this named parameter must be provided when calling the method.
    // 'overall' represents the user's overall wellness score.
    required int overall,
    
    // 'sleep' represents the user's sleep quality score.
    required int sleep,
    
    // 'physical' represents the user's physical feeling score.
    required int physical,
    
    // 'focus' represents the user's focus or mental clarity score.
    required int focus,
    
    // 'note' is an optional string (denoted by '?') for any extra comments.
    String? note,
  }) async {
    // Start a try-catch block to handle potential network errors gracefully.
    try {
      // Use the Dio instance from our ApiClient to make an HTTP POST request.
      // We are sending data to the '/wellness/checkin' endpoint on our server.
      // 'await' pauses the execution of this method until the network request finishes.
      await _api.dio.post('/wellness/checkin', data: {
        // We pass the data as a Map (key-value pairs) matching what the server expects.
        'overall_score': overall,
        'sleep_score': sleep,
        'physical_score': physical,
        'focus_score': focus,
        
        // This is a collection 'if' statement.
        // It only adds the 'note' key-value pair to the map if the note is not null
        // and is not an empty string.
        if (note != null && note.isNotEmpty) 'note': note,
      });
    } on DioException catch (e) {
      // If a network error specific to Dio occurs, we catch it here.
      // We check if the server responded with a 409 status code.
      // HTTP 409 usually stands for 'Conflict'.
      if (e.response?.statusCode == 409) {
        // If it's a 409 error, it means the user already checked in today.
        // We throw a clear, custom exception message so the app can show it to the user.
        throw Exception("Check-in already submitted for today");
      }
      // If it's a different DioException (like no internet, server down, etc.),
      // we 'rethrow' it so the code calling this method can handle it.
      rethrow;
    }
  }

  // A method to check if the user has already submitted a check-in today.
  // Returns a Future containing a Map of Strings to dynamic values (usually JSON data).
  Future<Map<String, dynamic>> checkTodayStatus() async {
    try {
      // Make an HTTP GET request to the '/wellness/today' endpoint.
      // GET requests are used to fetch data from the server.
      final res = await _api.dio.get('/wellness/today');
      
      // Return the 'data' part of the response, which contains the server's payload.
      return res.data;
    } catch (e) {
      // If any error occurs during the GET request, throw it back up to the caller.
      rethrow;
    }
  }

  // A method to retrieve the user's past check-in history.
  // Returns a Future containing a List of dynamic items (likely a list of Maps).
  Future<List<dynamic>> getHistory() async {
    try {
      // Make an HTTP GET request to the '/wellness/history' endpoint.
      final res = await _api.dio.get('/wellness/history');
      
      // Return the response data, explicitly casting it to a List<dynamic>.
      // This tells Dart we expect the data to be a list/array.
      return res.data as List<dynamic>;
    } catch (e) {
      // If an error happens, rethrow it so the caller can deal with it.
      rethrow;
    }
  }
}
