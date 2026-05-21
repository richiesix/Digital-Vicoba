import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../database/sync_local_store.dart';
import '../network/api_client.dart';

class SyncService {
  SyncService(this._api);

  final ApiClient _api;
  final _uuid = const Uuid();

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> queueOperation({
    required String entityType,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final clientId = _uuid.v4();
    final payloadJson = jsonEncode({...payload, 'client_id': clientId});

    await SyncLocalStore.insertQueueItem(
      clientId: clientId,
      entityType: entityType,
      operation: operation,
      payloadJson: payloadJson,
      clientTimestamp: DateTime.now().toIso8601String(),
    );

    if (await isOnline) {
      await syncPending();
    }
  }

  Future<Map<String, dynamic>> syncPending() async {
    final pending = await SyncLocalStore.queryPending();

    if (pending.isEmpty) {
      return {'synced': 0, 'pending': 0};
    }

    final operations = pending.map((row) {
      return {
        'client_id': row['client_id'],
        'entity_type': row['entity_type'],
        'operation': row['operation'],
        'payload': jsonDecode(row['payload'] as String),
        'client_timestamp': row['client_timestamp'],
      };
    }).toList();

    try {
      final response = await _api.post('/sync/push', data: {
        'device_uuid': await _api.deviceUuid,
        'operations': operations,
      });

      final results = response.data['results'] as List? ?? [];

      for (final result in results) {
        final clientId = result['client_id'] as String?;
        final status = result['status'] as String?;
        if (clientId == null || status == null) continue;

        if (status == 'completed' || status == 'duplicate') {
          await SyncLocalStore.updateStatusByClientId(clientId, 'completed');
        } else if (status == 'conflict') {
          await SyncLocalStore.updateStatusByClientId(clientId, 'conflict');
        }
      }

      await SyncLocalStore.insertSyncLog(
        direction: 'push',
        recordsCount: operations.length,
        status: 'completed',
      );

      return {'synced': results.length, 'pending': await pendingCount()};
    } catch (e) {
      await SyncLocalStore.incrementRetryForPending();
      rethrow;
    }
  }

  Future<int> pendingCount() => SyncLocalStore.pendingCount();

  Future<Map<String, dynamic>> pull({DateTime? since}) async {
    final params = since != null ? {'since': since.toIso8601String()} : null;
    final response = await _api.get('/sync/pull', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }
}
