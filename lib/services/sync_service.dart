import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_client.dart';
import 'package:intl/intl.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.read(apiClientProvider));
});

class SyncService {
  final ApiClient _api;
  late Box _offlineBox;

  SyncService(this._api);

  Future<void> init() async {
    await Hive.initFlutter();
    _offlineBox = await Hive.openBox('offline_checkins');
  }

  Future<void> saveOfflineCheckin(Map<String, dynamic> checkinData) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    checkinData['checkin_date'] = dateStr;
    await _offlineBox.add(checkinData);
  }

  Future<void> syncIfOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    if (_offlineBox.isEmpty) return;

    final items = _offlineBox.values.toList();
    try {
      await _api.dio.post('/wellness/batch', data: {
        'checkins': items,
      });
      await _offlineBox.clear();
    } catch (e) {
      // Failed to sync, keep in box
    }
  }
  
  bool get hasOfflineData => _offlineBox.isNotEmpty;
}
