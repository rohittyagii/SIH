// Import the flutter_riverpod package, which provides state management and dependency injection.
// Riverpod helps us manage app state and share data/services across our application cleanly.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the local 'api_client.dart' file.
// This file likely contains the 'ApiClient' class and its provider, which handle network requests to the backend.
import 'api_client.dart';

// Create a global provider named 'supportServiceProvider'.
// In Riverpod, Providers are used to hold and share pieces of state or dependencies.
// Here, we are creating a Provider that specifically provides an instance of our 'SupportService' class.
// The 'ref' parameter is a reference object that allows us to interact with other providers.
final supportServiceProvider = Provider<SupportService>((ref) {
  // Inside the provider's function, we return a new instance of the SupportService.
  // We use 'ref.read(apiClientProvider)' to get the existing instance of the ApiClient.
  // This is dependency injection: SupportService needs an ApiClient to function,
  // and Riverpod ensures it gets the correct one automatically.
  return SupportService(ref.read(apiClientProvider));
});

// Define a class named 'SupportService'.
// The purpose of this class is to handle all operations related to customer support,
// such as making network requests to request a phone callback from support agents.
class SupportService {
  // Declare a private, final variable named '_api' of type 'ApiClient'.
  // The underscore '_' at the beginning means this variable is private (only accessible within this class).
  // The 'final' keyword means that once this variable is assigned a value, it cannot be changed.
  final ApiClient _api;

  // This is the constructor for the SupportService class.
  // It requires an ApiClient object to be passed in when a SupportService is created.
  // 'this._api' is a shorthand that automatically assigns the passed ApiClient to the private '_api' variable.
  SupportService(this._api);

  // Define an asynchronous method named 'requestCallback' that returns a Future<void>.
  // 'Future' indicates that this operation takes time to complete (it's asynchronous).
  // 'void' means that when the operation successfully finishes, it does not return any specific value.
  // The 'async' keyword allows us to use 'await' inside the function body.
  Future<void> requestCallback() async {
    // Start a 'try' block. This is used to test a block of code for errors while it is being executed.
    // If the network request fails, it won't crash the app; instead, it will jump to the 'catch' block.
    try {
      // Use 'await' to pause the execution of this function until the HTTP POST request is finished.
      // We are accessing the 'dio' HTTP client from our '_api' variable to make a POST request.
      // The request is sent to the '/support/callback' endpoint (URL path) on our backend server.
      await _api.dio.post('/support/callback', data: {
        // The 'data' parameter is a Map (like a dictionary) representing the JSON payload sent to the server.
        // We are telling the server that the 'type' of support requested is a 'callback'.
        'type': 'callback',
        // We are also sending an 'urgency' level, setting it to 'high' so the server knows it's important.
        'urgency': 'high',
      });
    // The 'catch' block runs if an error (like a network failure or a 404/500 error) occurs in the 'try' block.
    // The error object is stored in the variable 'e'.
    } catch (e) {
      // The 'rethrow' keyword takes the error we just caught and throws it again up the chain.
      // This is useful because it allows the UI code that called 'requestCallback()' to
      // catch the error as well and perhaps show an error dialog or snackbar to the user.
      rethrow;
    }
  }
}
