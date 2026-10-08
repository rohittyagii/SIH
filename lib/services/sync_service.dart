// Import the riverpod package which is used for state management and dependency injection in Flutter.
// This allows us to easily provide and access our SyncService anywhere in the app.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Hive, which is a lightweight and fast local database for Flutter.
// We use this to store data on the device when there is no internet connection.
import 'package:hive_flutter/hive_flutter.dart';

// Import the connectivity_plus package to check the device's network state.
// We use this to find out if the user is connected to Wi-Fi, Mobile Data, or offline.
import 'package:connectivity_plus/connectivity_plus.dart';

// Import our custom api_client which contains the ApiClient class and its riverpod provider.
// This client handles the actual HTTP requests to our backend server.
import 'api_client.dart';

// Import the intl package for internationalization and localization, specifically for date formatting.
// It gives us tools like DateFormat to easily convert DateTime objects to readable strings.
import 'package:intl/intl.dart';

// Create a global Provider for the SyncService.
// A Provider is basically a safe, globally accessible variable that Riverpod manages for us.
// We pass a function that takes 'ref' (a reference to other providers) and returns our SyncService.
final syncServiceProvider = Provider<SyncService>((ref) {
  // We use 'ref.read' to get the instance of ApiClient from its own provider.
  // Then we pass that ApiClient into the SyncService constructor.
  return SyncService(ref.read(apiClientProvider));
});

// Define the SyncService class.
// This class is responsible for saving data locally when offline, and syncing it to the server when online.
class SyncService {
  // A private variable to hold our ApiClient. The underscore (_) makes it private to this file.
  final ApiClient _api;
  
  // A late variable for a Hive Box. A 'Box' in Hive is like a table in a database or a folder of files.
  // We use 'late' because we won't initialize it immediately when the class is created,
  // but we promise to initialize it (in the init method) before we ever try to use it.
  late Box _offlineBox;

  // The constructor for SyncService. It requires an ApiClient to be passed in,
  // which it then assigns to the private _api variable.
  SyncService(this._api);

  // An asynchronous method to initialize the SyncService.
  // This must be called before using the service (e.g., when the app starts).
  Future<void> init() async {
    // First, initialize Hive specifically for Flutter. This sets up the necessary directories for storage.
    await Hive.initFlutter();
    
    // Open a Hive Box named 'offline_checkins'. If it doesn't exist, Hive creates it.
    // Opening a box loads its data into memory so we can read and write to it quickly.
    _offlineBox = await Hive.openBox('offline_checkins');
  }

  // An asynchronous method to save check-in data locally when the user has no internet.
  // It takes a Map (key-value pairs, similar to a JSON object) representing the check-in data.
  Future<void> saveOfflineCheckin(Map<String, dynamic> checkinData) async {
    // Get the current date and time.
    final now = DateTime.now();
    
    // Create a string representation of the date in the format 'YYYY-MM-DD' (e.g., '2023-10-08').
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    
    // Add the formatted date string into the checkinData map under the key 'checkin_date'.
    checkinData['checkin_date'] = dateStr;
    
    // Save the entire map into our local Hive Box.
    // 'add' appends the data to the box with an automatically generated key (like an auto-incrementing ID).
    await _offlineBox.add(checkinData);
  }

  // An asynchronous method to try sending the saved offline data to the server, if we have internet.
  Future<void> syncIfOnline() async {
    // Ask the Connectivity plugin for the current network status.
    // It returns a list of active connection types (e.g., Wi-Fi, cellular, none).
    final connectivityResult = await Connectivity().checkConnectivity();
    
    // Check if the result contains 'none', meaning there is absolutely no internet connection.
    // If there is no connection, we stop running this function early by returning.
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    // Check if our local offline box is empty.
    // If we have no saved offline data, there's nothing to sync, so we stop here.
    if (_offlineBox.isEmpty) return;

    // Retrieve all the saved items from the Hive Box and convert them into a Dart List.
    final items = _offlineBox.values.toList();
    
    // Start a try-catch block. This is used to handle potential errors,
    // like the server being down or a sudden internet drop during the upload.
    try {
      // Use our ApiClient's internal Dio instance to make an HTTP POST request to the '/wellness/batch' endpoint.
      // We send the list of saved items in the 'data' body under the key 'checkins'.
      // 'await' pauses the function until the server responds.
      await _api.dio.post('/wellness/batch', data: {
        'checkins': items,
      });
      
      // If the POST request succeeds without throwing an error, we reach this line.
      // We clear the local Hive Box because all the data has been successfully sent to the server.
      await _offlineBox.clear();
    } catch (e) {
      // If an error occurs during the POST request (e.g., network failure), the code jumps here.
      // We simply catch the error and do nothing.
      // By doing nothing, we intentionally DO NOT clear the _offlineBox.
      // Failed to sync, keep in box so we can try again later.
    }
  }
  
  // A simple 'getter' property that returns a boolean (true or false).
  // It returns true if the _offlineBox has items inside it, and false if it's empty.
  // This is useful for UI checks, like showing a 'Syncing...' badge.
  bool get hasOfflineData => _offlineBox.isNotEmpty;
}
