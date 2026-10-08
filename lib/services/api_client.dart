// Import the 'dio' package. Dio is a powerful HTTP networking client for Dart/Flutter.
// It helps us make network requests (like GET, POST) to an API or server.
import 'package:dio/dio.dart';

// Import the 'flutter_secure_storage' package. 
// This package is used to securely store sensitive data (like passwords or authentication tokens) 
// on the device, encrypting it so malicious users cannot easily access it.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import the 'flutter_riverpod' package. 
// Riverpod is a popular state management library in Flutter. It helps us manage and share 
// data (like our ApiClient) across different parts of our application safely and easily.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a 'Provider' for our ApiClient using Riverpod.
// A Provider is like a global, smart variable that holds our ApiClient instance.
// The 'ref' parameter allows us to interact with other providers if needed.
final apiClientProvider = Provider<ApiClient>((ref) {
  // We return a new instance of our ApiClient, passing it a new instance of 
  // FlutterSecureStorage. This makes the ApiClient ready to be used anywhere in the app.
  return ApiClient(const FlutterSecureStorage());
});

// Define a class named 'ApiClient'. This class will be responsible for 
// handling all the network communications with our backend server.
class ApiClient {
  // Define a constant private string for the base URL of our API.
  // 'static' means this variable belongs to the class itself, not an instance.
  // 'const' means its value cannot be changed once set.
  // The '_' before the name makes it private, meaning it can only be used inside this file.
  static const String _baseUrl = 'https://sainiksaathi-api.onrender.com/api/v1';
  
  // Declare a private final variable to hold our secure storage instance.
  // 'final' means this variable can only be set once (when the ApiClient is created).
  final FlutterSecureStorage _storage;
  
  // Declare a private variable for our Dio HTTP client.
  // 'late' means we are promising to initialize it before it is first used.
  // 'final' means it will be set once and never changed after that.
  late final Dio _dio;
  
  // The constructor for the ApiClient class.
  // It requires a FlutterSecureStorage instance to be passed in when created.
  ApiClient(this._storage) {
    // Initialize the '_dio' instance with some base options.
    _dio = Dio(BaseOptions(
      // Set the base URL for all network requests.
      // Every request made with this Dio instance will start with this URL.
      baseUrl: _baseUrl,
      
      // Set the connection timeout to 60 seconds.
      // If the server doesn't respond to the connection request within this time, it will throw an error.
      connectTimeout: const Duration(seconds: 60),
      
      // Set the receive timeout to 60 seconds.
      // If the app doesn't receive any data from the server for this duration during a request, it throws an error.
      receiveTimeout: const Duration(seconds: 60),
    ));
    
    // Add an 'Interceptor' to our Dio client.
    // Interceptors are functions that run automatically before a request is sent or after a response/error is received.
    _dio.interceptors.add(InterceptorsWrapper(
      
      // The 'onRequest' callback runs right before an HTTP request is sent to the server.
      onRequest: (options, handler) async {
        // Asynchronously read the 'auth_token' from our secure storage.
        // The token is used to prove our identity to the server.
        final token = await _storage.read(key: 'auth_token');
        
        // Check if the token exists (is not null).
        if (token != null) {
          // If we have a token, add an 'Authorization' header to our outgoing request.
          // The format is typically 'Bearer <token>'. This tells the server who we are.
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Pass the request along to be sent. Without this, the request would be stuck!
        return handler.next(options);
      },
      
      // The 'onError' callback runs if the HTTP request results in an error 
      // (like a 404 Not Found or a 500 Server Error).
      onError: (e, handler) {
        // You can handle errors globally here. For example, if a 401 Unauthorized 
        // error occurs, you could automatically log the user out.
        // We pass the error along to the next handler so it can be handled by the 
        // specific function that made the request.
        return handler.next(e);
      },
    ));
  }

  // A 'getter' method that exposes our private '_dio' instance to the outside world.
  // This allows other parts of the app to use this pre-configured Dio client 
  // to make requests, while preventing them from replacing the instance itself.
  Dio get dio => _dio;

  // A method to securely save the authentication token.
  // It's asynchronous ('async' and 'Future') because writing to storage takes a small amount of time.
  Future<void> saveToken(String token) async {
    // Write the token to secure storage using the key 'auth_token'.
    await _storage.write(key: 'auth_token', value: token);
  }
  
  // A method to securely remove the authentication token (usually used when logging out).
  Future<void> clearToken() async {
    // Delete the data associated with the key 'auth_token' from secure storage.
    await _storage.delete(key: 'auth_token');
  }

  // A method to check if an authentication token exists in secure storage.
  // It returns a Future<bool>, which means it will eventually give us a true or false value.
  Future<bool> hasToken() async {
    // Read the token from secure storage.
    final token = await _storage.read(key: 'auth_token');
    
    // Return true if the token is not null AND the token string is not empty.
    // If both are true, it means we likely have a valid token saved.
    return token != null && token.isNotEmpty;
  }
}
