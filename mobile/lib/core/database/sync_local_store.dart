import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'local_database.dart';

/// Offline sync queue — SQLCipher on mobile, SharedPreferences on web.
class SyncLocalStore {
  SyncLocalStore._();

  static const _webQueueKey = 'sync_queue_json';

  static Future<void> insertQueueItem({
    required String clientId,
    required String entityType,
    required String operation,
    required String payloadJson,
    required String clientTimestamp,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = _readWebQueue(prefs);
      list.add({
        'id': list.length + 1,
        'client_id': clientId,
        'entity_type': entityType,
        'operation': operation,
        'payload': payloadJson,
        'client_timestamp': clientTimestamp,
        'status': 'pending',
        'retry_count': 0,
      });
      await prefs.setString(_webQueueKey, jsonEncode(list));
      return;
    }

    final db = await LocalDatabase.instance;
    await db.insert('sync_queue', {
      'client_id': clientId,
      'entity_type': entityType,
      'operation': operation,
      'payload': payloadJson,
      'client_timestamp': clientTimestamp,
      'status': 'pending',
    });
  }

  static Future<List<Map<String, dynamic>>> queryPending() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return _readWebQueue(prefs).where((r) => r['status'] == 'pending').toList();
    }

    final db = await LocalDatabase.instance;
    final rows = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'id ASC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  static Future<void> updateStatusByClientId(String clientId, String status) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = _readWebQueue(prefs);
      for (final row in list) {
        if (row['client_id'] == clientId) {
          row['status'] = status;
        }
      }
      await prefs.setString(_webQueueKey, jsonEncode(list));
      return;
    }

    final db = await LocalDatabase.instance;
    await db.update(
      'sync_queue',
      {'status': status},
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
  }

  static Future<void> incrementRetryForPending() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = _readWebQueue(prefs);
      for (final row in list) {
        if (row['status'] == 'pending') {
          row['retry_count'] = (row['retry_count'] as int? ?? 0) + 1;
        }
      }
      await prefs.setString(_webQueueKey, jsonEncode(list));
      return;
    }

    final db = await LocalDatabase.instance;
    await db.rawUpdate(
      "UPDATE sync_queue SET retry_count = retry_count + 1 WHERE status = 'pending'",
    );
  }

  static Future<void> insertSyncLog({
    required String direction,
    required int recordsCount,
    required String status,
  }) async {
    if (kIsWeb) return;

    final db = await LocalDatabase.instance;
    await db.insert('sync_logs', {
      'direction': direction,
      'records_count': recordsCount,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<int> pendingCount() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return _readWebQueue(prefs)
          .where((r) => ['pending', 'failed', 'conflict'].contains(r['status']))
          .length;
    }

    final db = await LocalDatabase.instance;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as c FROM sync_queue WHERE status IN ('pending', 'failed', 'conflict')",
    );
    return (result.first['c'] as int?) ?? 0;
  }

  static List<Map<String, dynamic>> _readWebQueue(SharedPreferences prefs) {
    final raw = prefs.getString(_webQueueKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
